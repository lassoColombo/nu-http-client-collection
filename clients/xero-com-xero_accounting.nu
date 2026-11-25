# Auto-generated client for Xero Accounting API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_accounting/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_ACCOUNTING_API_TOKEN

const CLIENT = {
  base_url: "https://api.xero.com/api.xro/2.0"
  token_env_var: "XERO_ACCOUNTING_API_TOKEN"
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

def base-url-completer [] { ["https://api.xero.com/api.xro/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bank-account-type-completer [] { ["" "BANK" "CREDITCARD" "NONE" "PAYPAL"] }
def currency-code-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def status-completer [] { ["ACTIVE" "ARCHIVED" "DELETED"] }
def type-completer [] { ["BANK" "CURRENT" "CURRLIAB" "DEPRECIATN" "DIRECTCOSTS" "EQUITY" "EXPENSE" "FIXED" "INVENTORY" "LIABILITY" "NONCURRENT" "OTHERINCOME" "OVERHEADS" "PAYG" "PAYGLIABILITY" "PREPAYMENT" "REVENUE" "SALES" "SUPERANNUATIONEXPENSE" "SUPERANNUATIONLIABILITY" "TERMLIAB" "WAGESEXPENSE"] }
def code-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def source-transaction-type-code-completer [] { ["ACCPAY" "SPEND"] }
def status-completer-1 [] { ["APPROVED" "BILLED" "DRAFT" "ONDRAFT" "VOIDED"] }
def type-completer-1 [] { ["BILLABLEEXPENSE"] }
def status-completer-2 [] { ["AUTHORISED" "DELETED"] }
def status-completer-3 [] { ["AUTHORISED" "BILLED" "DELETED" "DRAFT" "SUBMITTED"] }
def timeframe-completer [] { ["MONTH" "QUARTER" "YEAR"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts: "record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-account: "record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    delete-account: "record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-account: "record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-account: "record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-account-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-account-attachment-by-id: "binary"
    get-account-attachment-by-file-name: "binary"
    update-account-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-account-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-bank-transactions: "record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>"
    update-or-create-bank-transactions: "record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>"
    create-bank-transactions: "record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>"
    get-bank-transaction: "record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>"
    update-bank-transaction: "record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>"
    get-bank-transaction-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-bank-transaction-attachment-by-id: "binary"
    get-bank-transaction-attachment-by-file-name: "binary"
    update-bank-transaction-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-bank-transaction-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-bank-transactions-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-bank-transaction-history-record: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-bank-transfers: "record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>"
    create-bank-transfer: "record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>"
    get-bank-transfer: "record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>"
    get-bank-transfer-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-bank-transfer-attachment-by-id: "binary"
    get-bank-transfer-attachment-by-file-name: "binary"
    update-bank-transfer-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-bank-transfer-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-bank-transfer-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-bank-transfer-history-record: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-batch-payments: "record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>>"
    create-batch-payment: "record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>>"
    get-batch-payment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-batch-payment-history-record: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-branding-themes: "record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>>"
    get-branding-theme: "record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>>"
    get-branding-theme-payment-services: "record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>"
    create-branding-theme-payment-services: "record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>"
    get-contact-groups: "record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>"
    create-contact-group: "record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>"
    get-contact-group: "record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>"
    update-contact-group: "record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>"
    create-contact-group-contacts: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    get-contacts: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    update-or-create-contacts: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    create-contacts: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    get-contact: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    update-contact: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    get-contact-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-contact-attachment-by-id: "binary"
    get-contact-attachment-by-file-name: "binary"
    update-contact-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-contact-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-contact-cis-settings: "record<CISSettings: table<CISEnabled: bool, Rate: float>>"
    get-contact-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-contact-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-contact-by-contact-number: "record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>"
    get-credit-notes: "record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    update-or-create-credit-notes: "record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    create-credit-notes: "record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    get-credit-note: "record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    update-credit-note: "record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    create-credit-note-allocation: "record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>"
    get-credit-note-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-credit-note-attachment-by-id: "binary"
    get-credit-note-attachment-by-file-name: "binary"
    update-credit-note-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-credit-note-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-credit-note-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-credit-note-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-credit-note-as-pdf: "binary"
    get-currencies: "record<Currencies: table<Code: string, Description: string>>"
    create-currency: "record<Currencies: table<Code: string, Description: string>>"
    get-employees: "record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-or-create-employees: "record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-employees: "record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-employee: "record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-expense-claims: "record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>"
    create-expense-claims: "record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>"
    get-expense-claim: "record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>"
    update-expense-claim: "record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>"
    get-expense-claim-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-expense-claim-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-invoice-reminders: "record<InvoiceReminders: table<Enabled: bool>>"
    get-invoices: "record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    update-or-create-invoices: "record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    create-invoices: "record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    get-invoice: "record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    update-invoice: "record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    get-invoice-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-invoice-attachment-by-id: "binary"
    get-invoice-attachment-by-file-name: "binary"
    update-invoice-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-invoice-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-invoice-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-invoice-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-online-invoice: "record<OnlineInvoices: table<OnlineInvoiceUrl: string>>"
    get-invoice-as-pdf: "binary"
    get-items: "record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-or-create-items: "record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-items: "record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-item: "record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-item: "record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-item-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-item-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-journals: "record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>>"
    get-journal: "record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>>"
    get-linked-transactions: "record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-linked-transaction: "record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-linked-transaction: "record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-linked-transaction: "record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-manual-journals: "record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    update-or-create-manual-journals: "record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    create-manual-journals: "record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    get-manual-journal: "record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    update-manual-journal: "record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>"
    get-manual-journal-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-manual-journal-attachment-by-id: "binary"
    get-manual-journal-attachment-by-file-name: "binary"
    update-manual-journal-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-manual-journal-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-manual-journals-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-manual-journal-history-record: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-organisations: "record<Organisations: table<APIKey: string, Addresses: list, BaseCurrency: string, Class: string, CountryCode: string, CreatedDateUTC: string, DefaultPurchasesTax: string, DefaultSalesTax: string, Edition: string, EmployerIdentificationNumber: string, EndOfYearLockDate: string, ExternalLinks: list, FinancialYearEndDay: int, FinancialYearEndMonth: int, IsDemoCompany: bool, LegalName: string, LineOfBusiness: string, Name: string, OrganisationEntityType: string, OrganisationID: string, OrganisationStatus: string, OrganisationType: string, PaymentTerms: record, PaysTax: bool, PeriodLockDate: string, Phones: list, RegistrationNumber: string, SalesTaxBasis: string, SalesTaxPeriod: string, ShortCode: string, TaxNumber: string, Timezone: string, Version: string>>"
    get-organisation-actions: "record<Actions: table<Name: string, Status: string>>"
    get-organisation-cis-settings: "record<CISSettings: table<CISContractorEnabled: bool, CISSubContractorEnabled: bool, Rate: float>>"
    get-overpayments: "record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>"
    get-overpayment: "record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>"
    create-overpayment-allocations: "record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>"
    get-overpayment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-overpayment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-payment-services: "record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>"
    create-payment-service: "record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>"
    get-payments: "record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-payment: "record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-payments: "record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-payment: "record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    delete-payment: "record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-payment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-payment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-prepayments: "record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>"
    get-prepayment: "record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>"
    create-prepayment-allocations: "record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>"
    get-prepayment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-prepayment-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-purchase-orders: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    update-or-create-purchase-orders: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    create-purchase-orders: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    get-purchase-order: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    update-purchase-order: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    get-purchase-order-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-purchase-order-attachment-by-id: "binary"
    get-purchase-order-attachment-by-file-name: "binary"
    update-purchase-order-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-purchase-order-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-purchase-order-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-purchase-order-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-purchase-order-as-pdf: "binary"
    get-purchase-order-by-number: "record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>"
    get-quotes: "record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-or-create-quotes: "record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    create-quotes: "record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-quote: "record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    update-quote: "record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>"
    get-quote-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-quote-attachment-by-id: "binary"
    get-quote-attachment-by-file-name: "binary"
    update-quote-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-quote-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-quote-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-quote-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-quote-as-pdf: "binary"
    get-receipts: "record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>"
    create-receipt: "record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>"
    get-receipt: "record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>"
    update-receipt: "record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>"
    get-receipt-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-receipt-attachment-by-id: "binary"
    get-receipt-attachment-by-file-name: "binary"
    update-receipt-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-receipt-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-receipt-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-receipt-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-repeating-invoices: "record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>>"
    get-repeating-invoice: "record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>>"
    get-repeating-invoice-attachments: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-repeating-invoice-attachment-by-id: "binary"
    get-repeating-invoice-attachment-by-file-name: "binary"
    update-repeating-invoice-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    create-repeating-invoice-attachment-by-file-name: "record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>"
    get-repeating-invoice-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    create-repeating-invoice-history: "record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>"
    get-report-ba-sor-gst-list: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-aged-payables-by-contact: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-aged-receivables-by-contact: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-balance-sheet: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-bank-summary: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-budget-summary: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-executive-summary: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-profit-and-loss: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-ten-ninety-nine: "record<Reports: table<Contacts: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportType: string, UpdatedDateUTC: string>>"
    get-report-trial-balance: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    get-report-ba-sor-gst: "record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>"
    post-setup: "record<ImportSummary: record<Accounts: record<Deleted: float, Errored: float, Locked: float, New: float, NewOrUpdated: float, Present: bool, System: float, Total: float, Updated: float>, Organisation: record<Present: bool>>>"
    get-tax-rates: "record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>"
    update-tax-rate: "record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>"
    create-tax-rates: "record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>"
    get-tracking-categories: "record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    create-tracking-category: "record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    delete-tracking-category: "record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    get-tracking-category: "record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    update-tracking-category: "record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    create-tracking-options: "record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    delete-tracking-options: "record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    update-tracking-options: "record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>"
    get-users: "record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>>"
    get-user: "record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-accounts" "create-account" "delete-account" "get-account" "update-account" "get-account-attachments" "get-account-attachment-by-id" "get-account-attachment-by-file-name" "update-account-attachment-by-file-name" "create-account-attachment-by-file-name" "get-bank-transactions" "update-or-create-bank-transactions" "create-bank-transactions" "get-bank-transaction" "update-bank-transaction" "get-bank-transaction-attachments" "get-bank-transaction-attachment-by-id" "get-bank-transaction-attachment-by-file-name" "update-bank-transaction-attachment-by-file-name" "create-bank-transaction-attachment-by-file-name" "get-bank-transactions-history" "create-bank-transaction-history-record" "get-bank-transfers" "create-bank-transfer" "get-bank-transfer" "get-bank-transfer-attachments" "get-bank-transfer-attachment-by-id" "get-bank-transfer-attachment-by-file-name" "update-bank-transfer-attachment-by-file-name" "create-bank-transfer-attachment-by-file-name" "get-bank-transfer-history" "create-bank-transfer-history-record" "get-batch-payments" "create-batch-payment" "get-batch-payment-history" "create-batch-payment-history-record" "get-branding-themes" "get-branding-theme" "get-branding-theme-payment-services" "create-branding-theme-payment-services" "get-contact-groups" "create-contact-group" "get-contact-group" "update-contact-group" "delete-contact-group-contacts" "create-contact-group-contacts" "delete-contact-group-contact" "get-contacts" "update-or-create-contacts" "create-contacts" "get-contact" "update-contact" "get-contact-attachments" "get-contact-attachment-by-id" "get-contact-attachment-by-file-name" "update-contact-attachment-by-file-name" "create-contact-attachment-by-file-name" "get-contact-cis-settings" "get-contact-history" "create-contact-history" "get-contact-by-contact-number" "get-credit-notes" "update-or-create-credit-notes" "create-credit-notes" "get-credit-note" "update-credit-note" "create-credit-note-allocation" "get-credit-note-attachments" "get-credit-note-attachment-by-id" "get-credit-note-attachment-by-file-name" "update-credit-note-attachment-by-file-name" "create-credit-note-attachment-by-file-name" "get-credit-note-history" "create-credit-note-history" "get-credit-note-as-pdf" "get-currencies" "create-currency" "get-employees" "update-or-create-employees" "create-employees" "get-employee" "get-expense-claims" "create-expense-claims" "get-expense-claim" "update-expense-claim" "get-expense-claim-history" "create-expense-claim-history" "get-invoice-reminders" "get-invoices" "update-or-create-invoices" "create-invoices" "get-invoice" "update-invoice" "get-invoice-attachments" "get-invoice-attachment-by-id" "get-invoice-attachment-by-file-name" "update-invoice-attachment-by-file-name" "create-invoice-attachment-by-file-name" "email-invoice" "get-invoice-history" "create-invoice-history" "get-online-invoice" "get-invoice-as-pdf" "get-items" "update-or-create-items" "create-items" "delete-item" "get-item" "update-item" "get-item-history" "create-item-history" "get-journals" "get-journal" "get-linked-transactions" "create-linked-transaction" "delete-linked-transaction" "get-linked-transaction" "update-linked-transaction" "get-manual-journals" "update-or-create-manual-journals" "create-manual-journals" "get-manual-journal" "update-manual-journal" "get-manual-journal-attachments" "get-manual-journal-attachment-by-id" "get-manual-journal-attachment-by-file-name" "update-manual-journal-attachment-by-file-name" "create-manual-journal-attachment-by-file-name" "get-manual-journals-history" "create-manual-journal-history-record" "get-organisations" "get-organisation-actions" "get-organisation-cis-settings" "get-overpayments" "get-overpayment" "create-overpayment-allocations" "get-overpayment-history" "create-overpayment-history" "get-payment-services" "create-payment-service" "get-payments" "create-payment" "create-payments" "get-payment" "delete-payment" "get-payment-history" "create-payment-history" "get-prepayments" "get-prepayment" "create-prepayment-allocations" "get-prepayment-history" "create-prepayment-history" "get-purchase-orders" "update-or-create-purchase-orders" "create-purchase-orders" "get-purchase-order" "update-purchase-order" "get-purchase-order-attachments" "get-purchase-order-attachment-by-id" "get-purchase-order-attachment-by-file-name" "update-purchase-order-attachment-by-file-name" "create-purchase-order-attachment-by-file-name" "get-purchase-order-history" "create-purchase-order-history" "get-purchase-order-as-pdf" "get-purchase-order-by-number" "get-quotes" "update-or-create-quotes" "create-quotes" "get-quote" "update-quote" "get-quote-attachments" "get-quote-attachment-by-id" "get-quote-attachment-by-file-name" "update-quote-attachment-by-file-name" "create-quote-attachment-by-file-name" "get-quote-history" "create-quote-history" "get-quote-as-pdf" "get-receipts" "create-receipt" "get-receipt" "update-receipt" "get-receipt-attachments" "get-receipt-attachment-by-id" "get-receipt-attachment-by-file-name" "update-receipt-attachment-by-file-name" "create-receipt-attachment-by-file-name" "get-receipt-history" "create-receipt-history" "get-repeating-invoices" "get-repeating-invoice" "get-repeating-invoice-attachments" "get-repeating-invoice-attachment-by-id" "get-repeating-invoice-attachment-by-file-name" "update-repeating-invoice-attachment-by-file-name" "create-repeating-invoice-attachment-by-file-name" "get-repeating-invoice-history" "create-repeating-invoice-history" "get-report-ba-sor-gst-list" "get-report-aged-payables-by-contact" "get-report-aged-receivables-by-contact" "get-report-balance-sheet" "get-report-bank-summary" "get-report-budget-summary" "get-report-executive-summary" "get-report-profit-and-loss" "get-report-ten-ninety-nine" "get-report-trial-balance" "get-report-ba-sor-gst" "post-setup" "get-tax-rates" "update-tax-rate" "create-tax-rates" "get-tracking-categories" "create-tracking-category" "delete-tracking-category" "get-tracking-category" "update-tracking-category" "create-tracking-options" "delete-tracking-options" "update-tracking-options" "get-users" "get-user" "commands"] | sort) } | get name | first)
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

# Retrieves the full chart of accounts
#
# GET /Accounts
# Returns: record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getAccounts
export def "get-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status==&quot;ACTIVE&quot; AND Type==&quot;BANK&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Accounts"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new chart of accounts
#
# PUT /Accounts
# Returns: record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --account-id: string # The Xero identifier for an account – specified as a string following the endpoint name e.g. /297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --add-to-watchlist: oneof<nothing, bool> # Boolean – describes whether the account is shown in the watchlist widget on the dashboard
  --bank-account-number: string # For bank accounts only (Account Type BANK)
  --bank-account-type: string@bank-account-type-completer # For bank accounts only. See Bank Account types
  --code: string # Customer defined alpha numeric account code e.g 200 or SALES (max length = 10) (e.g. 4400)
  --currency-code: string@currency-code-completer # 3 letter alpha code for the currency – see list of currency codes
  --description: string # Description of the Account. Valid for all types of accounts except bank accounts (max length = 4000)
  --enable-payments-to-account: oneof<nothing, bool> # Boolean – describes whether account can have payments applied to it
  --name: string # Name of account (max length = 150) (e.g. Food Sales)
  --reporting-code: string # Shown if set
  --show-in-expense-claims: oneof<nothing, bool> # Boolean – describes whether account code is available for use with expense claims
  --status: string@status-completer # Accounts with a status of ACTIVE can be updated to ARCHIVED. See Account Status Codes
  --tax-type: string # The tax type from TaxRates
  --type: string@type-completer # See Account Types
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Accounts"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountID, var: account_id}, {name: AddToWatchlist, var: add_to_watchlist}, {name: BankAccountNumber, var: bank_account_number}, {name: BankAccountType, var: bank_account_type}, {name: Code, var: code}, {name: CurrencyCode, var: currency_code}, {name: Description, var: description}, {name: EnablePaymentsToAccount, var: enable_payments_to_account}, {name: Name, var: name}, {name: ReportingCode, var: reporting_code}, {name: ShowInExpenseClaims, var: show_in_expense_claims}, {name: Status, var: status}, {name: TaxType, var: tax_type}, {name: Type, var: type}, {name: ValidationErrors, var: validation_errors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, account_id: $account_id, add_to_watchlist: $add_to_watchlist, bank_account_number: $bank_account_number, bank_account_type: $bank_account_type, code: $code, currency_code: $currency_code, description: $description, enable_payments_to_account: $enable_payments_to_account, name: $name, reporting_code: $reporting_code, show_in_expense_claims: $show_in_expense_claims, status: $status, tax_type: $tax_type, type: $type, validation_errors: $validation_errors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a chart of accounts
#
# DELETE /Accounts/{AccountID}
# Returns: record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: deleteAccount
export def "delete-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/Accounts/{AccountID}"
    path_params: [{name: AccountID, var: account_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a single chart of accounts by using a unique account Id
#
# GET /Accounts/{AccountID}
# Returns: record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getAccount
export def "get-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Accounts/{AccountID}"
    path_params: [{name: AccountID, var: account_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a chart of accounts
#
# POST /Accounts/{AccountID}
# Returns: record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateAccount
export def "update-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Accounts/{AccountID}"
    path_params: [{name: AccountID, var: account_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Accounts, var: accounts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xero_tenant_id: $xero_tenant_id, accounts: $accounts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific accounts by using a unique account Id
#
# GET /Accounts/{AccountID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getAccountAttachments
export def "get-account-attachments" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Accounts/{AccountID}/Attachments"
    path_params: [{name: AccountID, var: account_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific account using a unique attachment Id
#
# GET /Accounts/{AccountID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getAccountAttachmentById
export def "get-account-attachment-by-id" [
  account_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Accounts/{AccountID}/Attachments/{AttachmentID}"
    path_params: [{name: AccountID, var: account_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an attachment for a specific account by filename
#
# GET /Accounts/{AccountID}/Attachments/{FileName}
# Returns: binary
# operationId: getAccountAttachmentByFileName
export def "get-account-attachment-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Accounts/{AccountID}/Attachments/{FileName}"
    path_params: [{name: AccountID, var: account_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates attachment on a specific account by filename
#
# POST /Accounts/{AccountID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateAccountAttachmentByFileName
export def "update-account-attachment-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Accounts/{AccountID}/Attachments/{FileName}"
    path_params: [{name: AccountID, var: account_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment on a specific account
#
# PUT /Accounts/{AccountID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createAccountAttachmentByFileName
export def "create-account-attachment-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Accounts/{AccountID}/Attachments/{FileName}"
    path_params: [{name: AccountID, var: account_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves any spent or received money transactions
#
# GET /BankTransactions
# Returns: record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>
# operationId: getBankTransactions
export def "get-bank-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Type ASC)
  --page: int # Up to 100 bank transactions will be returned in a single API call with line items details (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransactions"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more spent or received money transaction
#
# POST /BankTransactions
# Returns: record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>
# operationId: updateOrCreateBankTransactions
export def "update-or-create-bank-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BankTransactions"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BankTransactions, var: bank_transactions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, bank_transactions: $bank_transactions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more spent or received money transaction
#
# PUT /BankTransactions
# Returns: record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>
# operationId: createBankTransactions
export def "create-bank-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransactions"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BankTransactions, var: bank_transactions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, bank_transactions: $bank_transactions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a single spent or received money transaction by using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}
# Returns: record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>
# operationId: getBankTransaction
export def "get-bank-transaction" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransactions/{BankTransactionID}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single spent or received money transaction
#
# POST /BankTransactions/{BankTransactionID}
# Returns: record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>>
# operationId: updateBankTransaction
export def "update-bank-transaction" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BankTransactions/{BankTransactionID}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BankTransactions, var: bank_transactions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, bank_transactions: $bank_transactions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves any attachments from a specific bank transactions
#
# GET /BankTransactions/{BankTransactionID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getBankTransactionAttachments
export def "get-bank-transaction-attachments" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransactions/{BankTransactionID}/Attachments"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves specific attachments from a specific BankTransaction using a unique attachment Id
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getBankTransactionAttachmentById
export def "get-bank-transaction-attachment-by-id" [
  bank_transaction_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/BankTransactions/{BankTransactionID}/Attachments/{AttachmentID}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific bank transaction by filename
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# Returns: binary
# operationId: getBankTransactionAttachmentByFileName
export def "get-bank-transaction-attachment-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/BankTransactions/{BankTransactionID}/Attachments/{FileName}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment from a specific bank transaction by filename
#
# POST /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateBankTransactionAttachmentByFileName
export def "update-bank-transaction-attachment-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BankTransactions/{BankTransactionID}/Attachments/{FileName}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment for a specific bank transaction by filename
#
# PUT /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createBankTransactionAttachmentByFileName
export def "create-bank-transaction-attachment-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransactions/{BankTransactionID}/Attachments/{FileName}"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history from a specific bank transaction using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getBankTransactionsHistory
export def "get-bank-transactions-history" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransactions/{BankTransactionID}/History"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific bank transactions
#
# PUT /BankTransactions/{BankTransactionID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createBankTransactionHistoryRecord
export def "create-bank-transaction-history-record" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransactions/{BankTransactionID}/History"
    path_params: [{name: BankTransactionID, var: bank_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transaction_id: $bank_transaction_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all bank transfers
#
# GET /BankTransfers
# Returns: record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>
# operationId: getBankTransfers
export def "get-bank-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. HasAttachments==true)
  --order: string # Order by an any element (e.g. Amount ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransfers"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a bank transfer
#
# PUT /BankTransfers
# Returns: record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>
# operationId: createBankTransfer
export def "create-bank-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --bank-transfers: list # item shape: {Amount: float, Date?: string, FromBankAccount: record, ToBankAccount: record, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransfers"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BankTransfers, var: bank_transfers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, bank_transfers: $bank_transfers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves specific bank transfers by using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}
# Returns: record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>>
# operationId: getBankTransfer
export def "get-bank-transfer" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransfers/{BankTransferID}"
    path_params: [{name: BankTransferID, var: bank_transfer_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments from a specific bank transfer
#
# GET /BankTransfers/{BankTransferID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getBankTransferAttachments
export def "get-bank-transfer-attachments" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransfers/{BankTransferID}/Attachments"
    path_params: [{name: BankTransferID, var: bank_transfer_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific bank transfer using a unique attachment ID
#
# GET /BankTransfers/{BankTransferID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getBankTransferAttachmentById
export def "get-bank-transfer-attachment-by-id" [
  bank_transfer_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/BankTransfers/{BankTransferID}/Attachments/{AttachmentID}"
    path_params: [{name: BankTransferID, var: bank_transfer_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment on a specific bank transfer by file name
#
# GET /BankTransfers/{BankTransferID}/Attachments/{FileName}
# Returns: binary
# operationId: getBankTransferAttachmentByFileName
export def "get-bank-transfer-attachment-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/BankTransfers/{BankTransferID}/Attachments/{FileName}"
    path_params: [{name: BankTransferID, var: bank_transfer_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateBankTransferAttachmentByFileName
export def "update-bank-transfer-attachment-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BankTransfers/{BankTransferID}/Attachments/{FileName}"
    path_params: [{name: BankTransferID, var: bank_transfer_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createBankTransferAttachmentByFileName
export def "create-bank-transfer-attachment-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransfers/{BankTransferID}/Attachments/{FileName}"
    path_params: [{name: BankTransferID, var: bank_transfer_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history from a specific bank transfer using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getBankTransferHistory
export def "get-bank-transfer-history" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BankTransfers/{BankTransferID}/History"
    path_params: [{name: BankTransferID, var: bank_transfer_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific bank transfer
#
# PUT /BankTransfers/{BankTransferID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createBankTransferHistoryRecord
export def "create-bank-transfer-history-record" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BankTransfers/{BankTransferID}/History"
    path_params: [{name: BankTransferID, var: bank_transfer_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bank_transfer_id: $bank_transfer_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves either one or many batch payments for invoices
#
# GET /BatchPayments
# Returns: record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>>
# operationId: getBatchPayments
export def "get-batch-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Date ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BatchPayments"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or many batch payments for invoices
#
# PUT /BatchPayments
# Returns: record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>>
# operationId: createBatchPayment
export def "create-batch-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --batch-payments: list # item shape: {Account?: record, Amount?: float, Code?: string, Date?: string, DateString?: string, Details?: string, Narrative?: string, Particulars?: string, Payments?: list, Reference?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BatchPayments"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchPayments, var: batch_payments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, batch_payments: $batch_payments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history from a specific batch payment
#
# GET /BatchPayments/{BatchPaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getBatchPaymentHistory
export def "get-batch-payment-history" [
  batch_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BatchPayments/{BatchPaymentID}/History"
    path_params: [{name: BatchPaymentID, var: batch_payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_payment_id: $batch_payment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific batch payment
#
# PUT /BatchPayments/{BatchPaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createBatchPaymentHistoryRecord
export def "create-batch-payment-history-record" [
  batch_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/BatchPayments/{BatchPaymentID}/History"
    path_params: [{name: BatchPaymentID, var: batch_payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_payment_id: $batch_payment_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all the branding themes
#
# GET /BrandingThemes
# Returns: record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>>
# operationId: getBrandingThemes
export def "get-branding-themes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BrandingThemes"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific branding theme using a unique branding theme Id
#
# GET /BrandingThemes/{BrandingThemeID}
# Returns: record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>>
# operationId: getBrandingTheme
export def "get-branding-theme" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BrandingThemes/{BrandingThemeID}"
    path_params: [{name: BrandingThemeID, var: branding_theme_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    branding_theme_id: $branding_theme_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the payment services for a specific branding theme
#
# GET /BrandingThemes/{BrandingThemeID}/PaymentServices
# Returns: record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>
# operationId: getBrandingThemePaymentServices
export def "get-branding-theme-payment-services" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/BrandingThemes/{BrandingThemeID}/PaymentServices"
    path_params: [{name: BrandingThemeID, var: branding_theme_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    branding_theme_id: $branding_theme_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new custom payment service for a specific branding theme
#
# POST /BrandingThemes/{BrandingThemeID}/PaymentServices
# Returns: record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>
# operationId: createBrandingThemePaymentServices
export def "create-branding-theme-payment-services" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --pay-now-text: string # The text displayed on the Pay Now button in Xero Online Invoicing. If this is not set it will default to Pay by credit card
  --payment-service-id: string # Xero identifier (format: uuid)
  --payment-service-name: string # Name of payment service
  --payment-service-type: string # This will always be CUSTOM for payment services created via the API.
  --payment-service-url: string # The custom payment URL
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/BrandingThemes/{BrandingThemeID}/PaymentServices"
    path_params: [{name: BrandingThemeID, var: branding_theme_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayNowText, var: pay_now_text}, {name: PaymentServiceID, var: payment_service_id}, {name: PaymentServiceName, var: payment_service_name}, {name: PaymentServiceType, var: payment_service_type}, {name: PaymentServiceUrl, var: payment_service_url}, {name: ValidationErrors, var: validation_errors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    branding_theme_id: $branding_theme_id, xero_tenant_id: $xero_tenant_id, pay_now_text: $pay_now_text, payment_service_id: $payment_service_id, payment_service_name: $payment_service_name, payment_service_type: $payment_service_type, payment_service_url: $payment_service_url, validation_errors: $validation_errors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the contact Id and name of all the contacts in a contact group
#
# GET /ContactGroups
# Returns: record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>
# operationId: getContactGroups
export def "get-contact-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ContactGroups"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a contact group
#
# PUT /ContactGroups
# Returns: record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>
# operationId: createContactGroup
export def "create-contact-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contact-groups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ContactGroups"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContactGroups, var: contact_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, contact_groups: $contact_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific contact group by using a unique contact group Id
#
# GET /ContactGroups/{ContactGroupID}
# Returns: record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>
# operationId: getContactGroup
export def "get-contact-group" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ContactGroups/{ContactGroupID}"
    path_params: [{name: ContactGroupID, var: contact_group_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_group_id: $contact_group_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific contact group
#
# POST /ContactGroups/{ContactGroupID}
# Returns: record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>>
# operationId: updateContactGroup
export def "update-contact-group" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contact-groups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ContactGroups/{ContactGroupID}"
    path_params: [{name: ContactGroupID, var: contact_group_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContactGroups, var: contact_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_group_id: $contact_group_id, xero_tenant_id: $xero_tenant_id, contact_groups: $contact_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all contacts from a specific contact group
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts
# operationId: deleteContactGroupContacts
export def "delete-contact-group-contacts" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: delete
    path: "/ContactGroups/{ContactGroupID}/Contacts"
    path_params: [{name: ContactGroupID, var: contact_group_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    contact_group_id: $contact_group_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates contacts to a specific contact group
#
# PUT /ContactGroups/{ContactGroupID}/Contacts
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: createContactGroupContacts
export def "create-contact-group-contacts" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ContactGroups/{ContactGroupID}/Contacts"
    path_params: [{name: ContactGroupID, var: contact_group_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_group_id: $contact_group_id, xero_tenant_id: $xero_tenant_id, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific contact from a contact group using a unique contact Id
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts/{ContactID}
# operationId: deleteContactGroupContact
export def "delete-contact-group-contact" [
  contact_group_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: delete
    path: "/ContactGroups/{ContactGroupID}/Contacts/{ContactID}"
    path_params: [{name: ContactGroupID, var: contact_group_id}, {name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    contact_group_id: $contact_group_id, contact_id: $contact_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all contacts in a Xero organisation
#
# GET /Contacts
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: getContacts
export def "get-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. ContactStatus==&quot;ACTIVE&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --i-ds: list<string> # Filter by a comma separated list of ContactIDs. Allows you to retrieve a specific set of contacts in a single call. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --page: int # e.g. page=1 - Up to 100 contacts will be returned in a single API call. (e.g. 1)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts"
    query: [{name: where, var: where}, {name: order, var: order}, {name: IDs, var: i_ds, style: csv}, {name: page, var: page}, {name: includeArchived, var: include_archived}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, i_ds: $i_ds, page: $page, include_archived: $include_archived, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more contacts in a Xero organisation
#
# POST /Contacts
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: updateOrCreateContacts
export def "update-or-create-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Contacts"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates multiple contacts (bulk) in a Xero organisation
#
# PUT /Contacts
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: createContacts
export def "create-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Contacts"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific contacts in a Xero organisation using a unique contact Id
#
# GET /Contacts/{ContactID}
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: getContact
export def "get-contact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts/{ContactID}"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific contact in a Xero organisation
#
# POST /Contacts/{ContactID}
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: updateContact
export def "update-contact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Contacts/{ContactID}"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getContactAttachments
export def "get-contact-attachments" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts/{ContactID}/Attachments"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific contact using a unique attachment Id
#
# GET /Contacts/{ContactID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getContactAttachmentById
export def "get-contact-attachment-by-id" [
  contact_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Contacts/{ContactID}/Attachments/{AttachmentID}"
    path_params: [{name: ContactID, var: contact_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific contact by file name
#
# GET /Contacts/{ContactID}/Attachments/{FileName}
# Returns: binary
# operationId: getContactAttachmentByFileName
export def "get-contact-attachment-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Contacts/{ContactID}/Attachments/{FileName}"
    path_params: [{name: ContactID, var: contact_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /Contacts/{ContactID}/Attachments/{FileName}
#
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateContactAttachmentByFileName
export def "update-contact-attachment-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Contacts/{ContactID}/Attachments/{FileName}"
    path_params: [{name: ContactID, var: contact_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /Contacts/{ContactID}/Attachments/{FileName}
#
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createContactAttachmentByFileName
export def "create-contact-attachment-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Contacts/{ContactID}/Attachments/{FileName}"
    path_params: [{name: ContactID, var: contact_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves CIS settings for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/CISSettings
# Returns: record<CISSettings: table<CISEnabled: bool, Rate: float>>
# operationId: getContactCISSettings
export def "get-contact-cis-settings" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts/{ContactID}/CISSettings"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records for a specific contact
#
# GET /Contacts/{ContactID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getContactHistory
export def "get-contact-history" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts/{ContactID}/History"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new history record for a specific contact
#
# PUT /Contacts/{ContactID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createContactHistory
export def "create-contact-history" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Contacts/{ContactID}/History"
    path_params: [{name: ContactID, var: contact_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific contact by contact number in a Xero organisation
#
# GET /Contacts/{ContactNumber}
# Returns: record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>>
# operationId: getContactByContactNumber
export def "get-contact-by-contact-number" [
  contact_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Contacts/{ContactNumber}"
    path_params: [{name: ContactNumber, var: contact_number}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_number: $contact_number, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves any credit notes
#
# GET /CreditNotes
# Returns: record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: getCreditNotes
export def "get-credit-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. CreditNoteNumber ASC)
  --page: int # e.g. page=1 – Up to 100 credit notes will be returned in a single API call with line items shown for each credit note (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/CreditNotes"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more credit notes
#
# POST /CreditNotes
# Returns: record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: updateOrCreateCreditNotes
export def "update-or-create-credit-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreditNotes"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreditNotes, var: credit_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, credit_notes: $credit_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new credit note
#
# PUT /CreditNotes
# Returns: record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: createCreditNotes
export def "create-credit-notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreditNotes"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreditNotes, var: credit_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, credit_notes: $credit_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific credit note using a unique credit note Id
#
# GET /CreditNotes/{CreditNoteID}
# Returns: record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: getCreditNote
export def "get-credit-note" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific credit note
#
# POST /CreditNotes/{CreditNoteID}
# Returns: record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: updateCreditNote
export def "update-credit-note" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreditNotes/{CreditNoteID}"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreditNotes, var: credit_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, credit_notes: $credit_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates allocation for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Allocations
# Returns: record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>
# operationId: createCreditNoteAllocation
export def "create-credit-note-allocation" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreditNotes/{CreditNoteID}/Allocations"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Allocations, var: allocations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, allocations: $allocations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific credit notes
#
# GET /CreditNotes/{CreditNoteID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getCreditNoteAttachments
export def "get-credit-note-attachments" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}/Attachments"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific credit note using a unique attachment Id
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getCreditNoteAttachmentById
export def "get-credit-note-attachment-by-id" [
  credit_note_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}/Attachments/{AttachmentID}"
    path_params: [{name: CreditNoteID, var: credit_note_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment on a specific credit note by file name
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# Returns: binary
# operationId: getCreditNoteAttachmentByFileName
export def "get-credit-note-attachment-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}/Attachments/{FileName}"
    path_params: [{name: CreditNoteID, var: credit_note_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates attachments on a specific credit note by file name
#
# POST /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateCreditNoteAttachmentByFileName
export def "update-credit-note-attachment-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreditNotes/{CreditNoteID}/Attachments/{FileName}"
    path_params: [{name: CreditNoteID, var: credit_note_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createCreditNoteAttachmentByFileName
export def "create-credit-note-attachment-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-online: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreditNotes/{CreditNoteID}/Attachments/{FileName}"
    path_params: [{name: CreditNoteID, var: credit_note_id}, {name: FileName, var: file_name}]
    query: [{name: IncludeOnline, var: include_online}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, file_name: $file_name, include_online: $include_online, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific credit note
#
# GET /CreditNotes/{CreditNoteID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getCreditNoteHistory
export def "get-credit-note-history" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}/History"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createCreditNoteHistory
export def "create-credit-note-history" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/CreditNotes/{CreditNoteID}/History"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves credit notes as PDF files
#
# GET /CreditNotes/{CreditNoteID}/pdf
# Returns: binary
# operationId: getCreditNoteAsPdf
export def "get-credit-note-as-pdf" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: get
    path: "/CreditNotes/{CreditNoteID}/pdf"
    path_params: [{name: CreditNoteID, var: credit_note_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    credit_note_id: $credit_note_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves currencies for your Xero organisation
#
# GET /Currencies
# Returns: record<Currencies: table<Code: string, Description: string>>
# operationId: getCurrencies
export def "get-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Code=="USD")
  --order: string # Order by an any element (e.g. Code ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Currencies"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new currency for a Xero organisation
#
# PUT /Currencies
# Returns: record<Currencies: table<Code: string, Description: string>>
# operationId: createCurrency
export def "create-currency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --code: string@code-completer # 3 letter alpha code for the currency – see list of currency codes
  --description: string # Name of Currency
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Currencies"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Code, var: code}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, code: $code, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves employees used in Xero payrun
#
# GET /Employees
# Returns: record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getEmployees
export def "get-employees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. LastName ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employees"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single new employees used in Xero payrun
#
# POST /Employees
# Returns: record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateOrCreateEmployees
export def "update-or-create-employees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employees"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employees, var: employees}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, employees: $employees
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new employees used in Xero payrun
#
# PUT /Employees
# Returns: record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createEmployees
export def "create-employees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employees"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employees, var: employees}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, employees: $employees
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific employee used in Xero payrun using a unique employee Id
#
# GET /Employees/{EmployeeID}
# Returns: record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getEmployee
export def "get-employee" [
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
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employees/{EmployeeID}"
    path_params: [{name: EmployeeID, var: employee_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employee_id: $employee_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves expense claims
#
# GET /ExpenseClaims
# Returns: record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>
# operationId: getExpenseClaims
export def "get-expense-claims" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="SUBMITTED")
  --order: string # Order by an any element (e.g. Status ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ExpenseClaims"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates expense claims
#
# PUT /ExpenseClaims
# Returns: record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>
# operationId: createExpenseClaims
export def "create-expense-claims" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --expense-claims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ExpenseClaims"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExpenseClaims, var: expense_claims}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, expense_claims: $expense_claims
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific expense claim using a unique expense claim Id
#
# GET /ExpenseClaims/{ExpenseClaimID}
# Returns: record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>
# operationId: getExpenseClaim
export def "get-expense-claim" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ExpenseClaims/{ExpenseClaimID}"
    path_params: [{name: ExpenseClaimID, var: expense_claim_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expense_claim_id: $expense_claim_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific expense claims
#
# POST /ExpenseClaims/{ExpenseClaimID}
# Returns: record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>>
# operationId: updateExpenseClaim
export def "update-expense-claim" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --expense-claims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ExpenseClaims/{ExpenseClaimID}"
    path_params: [{name: ExpenseClaimID, var: expense_claim_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ExpenseClaims, var: expense_claims}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expense_claim_id: $expense_claim_id, xero_tenant_id: $xero_tenant_id, expense_claims: $expense_claims
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific expense claim
#
# GET /ExpenseClaims/{ExpenseClaimID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getExpenseClaimHistory
export def "get-expense-claim-history" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ExpenseClaims/{ExpenseClaimID}/History"
    path_params: [{name: ExpenseClaimID, var: expense_claim_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expense_claim_id: $expense_claim_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific expense claim
#
# PUT /ExpenseClaims/{ExpenseClaimID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createExpenseClaimHistory
export def "create-expense-claim-history" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ExpenseClaims/{ExpenseClaimID}/History"
    path_params: [{name: ExpenseClaimID, var: expense_claim_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expense_claim_id: $expense_claim_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves invoice reminder settings
#
# GET /InvoiceReminders/Settings
# Returns: record<InvoiceReminders: table<Enabled: bool>>
# operationId: getInvoiceReminders
export def "get-invoice-reminders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/InvoiceReminders/Settings"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves sales invoices or purchase bills
#
# GET /Invoices
# Returns: record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: getInvoices
export def "get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. InvoiceNumber ASC)
  --i-ds: list<string> # Filter by a comma-separated list of InvoicesIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --invoice-numbers: list<string> # Filter by a comma-separated list of InvoiceNumbers. (e.g. &quot;INV-001&quot;, &quot;INV-002&quot;)
  --contact-i-ds: list<string> # Filter by a comma-separated list of ContactIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --statuses: list<string> # Filter by a comma-separated list Statuses. For faster response times we recommend using these explicit parameters instead of passing OR conditions into the Where filter. (e.g. &quot;DRAFT&quot;, &quot;SUBMITTED&quot;)
  --page: int # e.g. page=1 – Up to 100 invoices will be returned in a single API call with line items shown for each invoice (e.g. 1)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --created-by-my-app: oneof<nothing, bool> # When set to true you'll only retrieve Invoices created by your app (e.g. false)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Invoices"
    query: [{name: where, var: where}, {name: order, var: order}, {name: IDs, var: i_ds, style: csv}, {name: InvoiceNumbers, var: invoice_numbers, style: csv}, {name: ContactIDs, var: contact_i_ds, style: csv}, {name: Statuses, var: statuses, style: csv}, {name: page, var: page}, {name: includeArchived, var: include_archived}, {name: createdByMyApp, var: created_by_my_app}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, i_ds: $i_ds, invoice_numbers: $invoice_numbers, contact_i_ds: $contact_i_ds, statuses: $statuses, page: $page, include_archived: $include_archived, created_by_my_app: $created_by_my_app, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more sales invoices or purchase bills
#
# POST /Invoices
# Returns: record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: updateOrCreateInvoices
export def "update-or-create-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Invoices"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Invoices, var: invoices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, invoices: $invoices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more sales invoices or purchase bills
#
# PUT /Invoices
# Returns: record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: createInvoices
export def "create-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Invoices"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Invoices, var: invoices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, invoices: $invoices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific sales invoice or purchase bill using a unique invoice Id
#
# GET /Invoices/{InvoiceID}
# Returns: record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: getInvoice
export def "get-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}"
    path_params: [{name: InvoiceID, var: invoice_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific sales invoices or purchase bills
#
# POST /Invoices/{InvoiceID}
# Returns: record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: updateInvoice
export def "update-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Invoices/{InvoiceID}"
    path_params: [{name: InvoiceID, var: invoice_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Invoices, var: invoices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, invoices: $invoices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific invoice or purchase bill
#
# GET /Invoices/{InvoiceID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getInvoiceAttachments
export def "get-invoice-attachments" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/Attachments"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific invoices or purchase bills by using a unique attachment Id
#
# GET /Invoices/{InvoiceID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getInvoiceAttachmentById
export def "get-invoice-attachment-by-id" [
  invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/Attachments/{AttachmentID}"
    path_params: [{name: InvoiceID, var: invoice_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an attachment from a specific invoice or purchase bill by filename
#
# GET /Invoices/{InvoiceID}/Attachments/{FileName}
# Returns: binary
# operationId: getInvoiceAttachmentByFileName
export def "get-invoice-attachment-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/Attachments/{FileName}"
    path_params: [{name: InvoiceID, var: invoice_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an attachment from a specific invoices or purchase bill by filename
#
# POST /Invoices/{InvoiceID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateInvoiceAttachmentByFileName
export def "update-invoice-attachment-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Invoices/{InvoiceID}/Attachments/{FileName}"
    path_params: [{name: InvoiceID, var: invoice_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment for a specific invoice or purchase bill by filename
#
# PUT /Invoices/{InvoiceID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createInvoiceAttachmentByFileName
export def "create-invoice-attachment-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-online: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Invoices/{InvoiceID}/Attachments/{FileName}"
    path_params: [{name: InvoiceID, var: invoice_id}, {name: FileName, var: file_name}]
    query: [{name: IncludeOnline, var: include_online}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, file_name: $file_name, include_online: $include_online, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a copy of a specific invoice to related contact via email
#
# POST /Invoices/{InvoiceID}/Email
# operationId: emailInvoice
export def "email-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --status: string # Need at least one field to create an empty JSON payload
]: any -> any {
  $in | http-request {
    method: post
    path: "/Invoices/{InvoiceID}/Email"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records for a specific invoice
#
# GET /Invoices/{InvoiceID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getInvoiceHistory
export def "get-invoice-history" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/History"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific invoice
#
# PUT /Invoices/{InvoiceID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createInvoiceHistory
export def "create-invoice-history" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Invoices/{InvoiceID}/History"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a URL to an online invoice
#
# GET /Invoices/{InvoiceID}/OnlineInvoice
# Returns: record<OnlineInvoices: table<OnlineInvoiceUrl: string>>
# operationId: getOnlineInvoice
export def "get-online-invoice" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/OnlineInvoice"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves invoices or purchase bills as PDF files
#
# GET /Invoices/{InvoiceID}/pdf
# Returns: binary
# operationId: getInvoiceAsPdf
export def "get-invoice-as-pdf" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: get
    path: "/Invoices/{InvoiceID}/pdf"
    path_params: [{name: InvoiceID, var: invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves items
#
# GET /Items
# Returns: record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getItems
export def "get-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. IsSold==true)
  --order: string # Order by an any element (e.g. Code ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Items"
    query: [{name: where, var: where}, {name: order, var: order}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more items
#
# POST /Items
# Returns: record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateOrCreateItems
export def "update-or-create-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Items"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more items
#
# PUT /Items
# Returns: record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createItems
export def "create-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Items"
    query: [{name: summarizeErrors, var: summarize_errors}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific item
#
# DELETE /Items/{ItemID}
# operationId: deleteItem
export def "delete-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Items/{ItemID}"
    path_params: [{name: ItemID, var: item_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    item_id: $item_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific item using a unique item Id
#
# GET /Items/{ItemID}
# Returns: record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getItem
export def "get-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Items/{ItemID}"
    path_params: [{name: ItemID, var: item_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific item
#
# POST /Items/{ItemID}
# Returns: record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateItem
export def "update-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Items/{ItemID}"
    path_params: [{name: ItemID, var: item_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history for a specific item
#
# GET /Items/{ItemID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getItemHistory
export def "get-item-history" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Items/{ItemID}/History"
    path_params: [{name: ItemID, var: item_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific item
#
# PUT /Items/{ItemID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createItemHistory
export def "create-item-history" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Items/{ItemID}/History"
    path_params: [{name: ItemID, var: item_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves journals
#
# GET /Journals
# Returns: record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>>
# operationId: getJournals
export def "get-journals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Offset by a specified journal number. e.g. journals with a JournalNumber greater than the offset will be returned (e.g. 10)
  --payments-only: oneof<nothing, bool> # Filter to retrieve journals on a cash basis. Journals are returned on an accrual basis by default.
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Journals"
    query: [{name: offset, var: offset}, {name: paymentsOnly, var: payments_only}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, payments_only: $payments_only, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific journal using a unique journal Id.
#
# GET /Journals/{JournalID}
# Returns: record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>>
# operationId: getJournal
export def "get-journal" [
  journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Journals/{JournalID}"
    path_params: [{name: JournalID, var: journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    journal_id: $journal_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves linked transactions (billable expenses)
#
# GET /LinkedTransactions
# Returns: record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getLinkedTransactions
export def "get-linked-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Up to 100 linked transactions will be returned in a single API call. Use the page parameter to specify the page to be returned e.g. page=1. (e.g. 1)
  --linked-transaction-id: string # The Xero identifier for an Linked Transaction (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --source-transaction-id: string # Filter by the SourceTransactionID. Get the linked transactions created from a particular ACCPAY invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --contact-id: string # Filter by the ContactID. Get all the linked transactions that have been assigned to a particular customer. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --status: string # Filter by the combination of ContactID and Status. Get the linked transactions associated to a customer and with a status (e.g. APPROVED)
  --target-transaction-id: string # Filter by the TargetTransactionID. Get all the linked transactions allocated to a particular ACCREC invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/LinkedTransactions"
    query: [{name: page, var: page}, {name: LinkedTransactionID, var: linked_transaction_id}, {name: SourceTransactionID, var: source_transaction_id}, {name: ContactID, var: contact_id}, {name: Status, var: status}, {name: TargetTransactionID, var: target_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, linked_transaction_id: $linked_transaction_id, source_transaction_id: $source_transaction_id, contact_id: $contact_id, status: $status, target_transaction_id: $target_transaction_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates linked transactions (billable expenses)
#
# PUT /LinkedTransactions
# Returns: record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createLinkedTransaction
export def "create-linked-transaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --contact-id: string # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED. (format: uuid)
  --linked-transaction-id: string # The Xero identifier for an Linked Transaction e.g./LinkedTransactions/297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --source-line-item-id: string # The line item identifier from the source transaction. (format: uuid)
  --source-transaction-id: string # Filter by the SourceTransactionID. Get all the linked transactions created from a particular ACCPAY invoice (format: uuid)
  --source-transaction-type-code: string@source-transaction-type-code-completer # The Type of the source tranasction. This will be ACCPAY if the linked transaction was created from an invoice and SPEND if it was created from a bank transaction.
  --status: string@status-completer-1 # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED.
  --target-line-item-id: string # The line item identifier from the target transaction. It is possible to link multiple billable expenses to the same TargetLineItemID. (format: uuid)
  --target-transaction-id: string # Filter by the TargetTransactionID. Get all the linked transactions allocated to a particular ACCREC invoice (format: uuid)
  --type: string@type-completer-1 # This will always be BILLABLEEXPENSE. More types may be added in future.
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/LinkedTransactions"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ContactID, var: contact_id}, {name: LinkedTransactionID, var: linked_transaction_id}, {name: SourceLineItemID, var: source_line_item_id}, {name: SourceTransactionID, var: source_transaction_id}, {name: SourceTransactionTypeCode, var: source_transaction_type_code}, {name: Status, var: status}, {name: TargetLineItemID, var: target_line_item_id}, {name: TargetTransactionID, var: target_transaction_id}, {name: Type, var: type}, {name: ValidationErrors, var: validation_errors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, contact_id: $contact_id, linked_transaction_id: $linked_transaction_id, source_line_item_id: $source_line_item_id, source_transaction_id: $source_transaction_id, source_transaction_type_code: $source_transaction_type_code, status: $status, target_line_item_id: $target_line_item_id, target_transaction_id: $target_transaction_id, type: $type, validation_errors: $validation_errors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific linked transactions (billable expenses)
#
# DELETE /LinkedTransactions/{LinkedTransactionID}
# operationId: deleteLinkedTransaction
export def "delete-linked-transaction" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: delete
    path: "/LinkedTransactions/{LinkedTransactionID}"
    path_params: [{name: LinkedTransactionID, var: linked_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    linked_transaction_id: $linked_transaction_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific linked transaction (billable expenses) using a unique linked transaction Id
#
# GET /LinkedTransactions/{LinkedTransactionID}
# Returns: record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getLinkedTransaction
export def "get-linked-transaction" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/LinkedTransactions/{LinkedTransactionID}"
    path_params: [{name: LinkedTransactionID, var: linked_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linked_transaction_id: $linked_transaction_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific linked transactions (billable expenses)
#
# POST /LinkedTransactions/{LinkedTransactionID}
# Returns: record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateLinkedTransaction
export def "update-linked-transaction" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --linked-transactions: list # item shape: {ContactID?: string, LinkedTransactionID?: string, SourceLineItemID?: string, SourceTransactionID?: string, SourceTransactionTypeCode?: "ACCPAY"|"SPEND", Status?: "APPROVED"|"DRAFT"|"ONDRAFT"|"BILLED"|"VOIDED", TargetLineItemID?: string, TargetTransactionID?: string, Type?: "BILLABLEEXPENSE", ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/LinkedTransactions/{LinkedTransactionID}"
    path_params: [{name: LinkedTransactionID, var: linked_transaction_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: LinkedTransactions, var: linked_transactions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linked_transaction_id: $linked_transaction_id, xero_tenant_id: $xero_tenant_id, linked_transactions: $linked_transactions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves manual journals
#
# GET /ManualJournals
# Returns: record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: getManualJournals
export def "get-manual-journals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Date ASC)
  --page: int # e.g. page=1 – Up to 100 manual journals will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ManualJournals"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates a single manual journal
#
# POST /ManualJournals
# Returns: record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: updateOrCreateManualJournals
export def "update-or-create-manual-journals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ManualJournals"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ManualJournals, var: manual_journals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, manual_journals: $manual_journals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more manual journals
#
# PUT /ManualJournals
# Returns: record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: createManualJournals
export def "create-manual-journals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ManualJournals"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ManualJournals, var: manual_journals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, manual_journals: $manual_journals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}
# Returns: record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: getManualJournal
export def "get-manual-journal" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ManualJournals/{ManualJournalID}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific manual journal
#
# POST /ManualJournals/{ManualJournalID}
# Returns: record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>>
# operationId: updateManualJournal
export def "update-manual-journal" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ManualJournals/{ManualJournalID}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ManualJournals, var: manual_journals}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, xero_tenant_id: $xero_tenant_id, manual_journals: $manual_journals
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachment for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getManualJournalAttachments
export def "get-manual-journal-attachments" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ManualJournals/{ManualJournalID}/Attachments"
    path_params: [{name: ManualJournalID, var: manual_journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to retrieve a specific attachment from a specific manual journal using a unique attachment Id
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getManualJournalAttachmentById
export def "get-manual-journal-attachment-by-id" [
  manual_journal_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/ManualJournals/{ManualJournalID}/Attachments/{AttachmentID}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific manual journal by file name
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# Returns: binary
# operationId: getManualJournalAttachmentByFileName
export def "get-manual-journal-attachment-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/ManualJournals/{ManualJournalID}/Attachments/{FileName}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment from a specific manual journal by file name
#
# POST /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateManualJournalAttachmentByFileName
export def "update-manual-journal-attachment-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ManualJournals/{ManualJournalID}/Attachments/{FileName}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a specific attachment for a specific manual journal by file name
#
# PUT /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createManualJournalAttachmentByFileName
export def "create-manual-journal-attachment-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ManualJournals/{ManualJournalID}/Attachments/{FileName}"
    path_params: [{name: ManualJournalID, var: manual_journal_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getManualJournalsHistory
export def "get-manual-journals-history" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ManualJournals/{ManualJournalID}/History"
    path_params: [{name: ManualJournalID, var: manual_journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific manual journal
#
# PUT /ManualJournals/{ManualJournalID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createManualJournalHistoryRecord
export def "create-manual-journal-history-record" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ManualJournals/{ManualJournalID}/History"
    path_params: [{name: ManualJournalID, var: manual_journal_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    manual_journal_id: $manual_journal_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves Xero organisation details
#
# GET /Organisation
# Returns: record<Organisations: table<APIKey: string, Addresses: list, BaseCurrency: string, Class: string, CountryCode: string, CreatedDateUTC: string, DefaultPurchasesTax: string, DefaultSalesTax: string, Edition: string, EmployerIdentificationNumber: string, EndOfYearLockDate: string, ExternalLinks: list, FinancialYearEndDay: int, FinancialYearEndMonth: int, IsDemoCompany: bool, LegalName: string, LineOfBusiness: string, Name: string, OrganisationEntityType: string, OrganisationID: string, OrganisationStatus: string, OrganisationType: string, PaymentTerms: record, PaysTax: bool, PeriodLockDate: string, Phones: list, RegistrationNumber: string, SalesTaxBasis: string, SalesTaxPeriod: string, ShortCode: string, TaxNumber: string, Timezone: string, Version: string>>
# operationId: getOrganisations
export def "get-organisations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Organisation"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of the key actions your app has permission to perform in the connected Xero organisation.
#
# GET /Organisation/Actions
# Returns: record<Actions: table<Name: string, Status: string>>
# operationId: getOrganisationActions
export def "get-organisation-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Organisation/Actions"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the CIS settings for the Xero organistaion.
#
# GET /Organisation/{OrganisationID}/CISSettings
# Returns: record<CISSettings: table<CISContractorEnabled: bool, CISSubContractorEnabled: bool, Rate: float>>
# operationId: getOrganisationCISSettings
export def "get-organisation-cis-settings" [
  organisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Organisation/{OrganisationID}/CISSettings"
    path_params: [{name: OrganisationID, var: organisation_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organisation_id: $organisation_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves overpayments
#
# GET /Overpayments
# Returns: record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>
# operationId: getOverpayments
export def "get-overpayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Status ASC)
  --page: int # e.g. page=1 – Up to 100 overpayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Overpayments"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific overpayment using a unique overpayment Id
#
# GET /Overpayments/{OverpaymentID}
# Returns: record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>
# operationId: getOverpayment
export def "get-overpayment" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Overpayments/{OverpaymentID}"
    path_params: [{name: OverpaymentID, var: overpayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    overpayment_id: $overpayment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single allocation for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/Allocations
# Returns: record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>
# operationId: createOverpaymentAllocations
export def "create-overpayment-allocations" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Overpayments/{OverpaymentID}/Allocations"
    path_params: [{name: OverpaymentID, var: overpayment_id}]
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Allocations, var: allocations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    overpayment_id: $overpayment_id, summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, allocations: $allocations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific overpayment
#
# GET /Overpayments/{OverpaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getOverpaymentHistory
export def "get-overpayment-history" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Overpayments/{OverpaymentID}/History"
    path_params: [{name: OverpaymentID, var: overpayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    overpayment_id: $overpayment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createOverpaymentHistory
export def "create-overpayment-history" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Overpayments/{OverpaymentID}/History"
    path_params: [{name: OverpaymentID, var: overpayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    overpayment_id: $overpayment_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves payment services
#
# GET /PaymentServices
# Returns: record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>
# operationId: getPaymentServices
export def "get-payment-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PaymentServices"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a payment service
#
# PUT /PaymentServices
# Returns: record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>>
# operationId: createPaymentService
export def "create-payment-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --payment-services: list # item shape: {PayNowText?: string, PaymentServiceID?: string, PaymentServiceName?: string, PaymentServiceType?: string, PaymentServiceUrl?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PaymentServices"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PaymentServices, var: payment_services}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, payment_services: $payment_services
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves payments for invoices and credit notes
#
# GET /Payments
# Returns: record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getPayments
export def "get-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Amount ASC)
  --page: int # Up to 100 payments will be returned in a single API call (e.g. 1)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Payments"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single payment for invoice or credit notes
#
# POST /Payments
# Returns: record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createPayment
export def "create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --account: record # shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
  --amount: float # The amount of the payment. Must be less than or equal to the outstanding amount owing on the invoice e.g. 200.00 (format: double)
  --bank-account-number: string # The suppliers bank account number the payment is being made to
  --batch-payment-id: string # Present if the payment was created as part of a batch. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --code: string # Code of account you are using to make the payment e.g. 001 (note- not all accounts have a code value)
  --credit-note: record # shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
  --credit-note-number: string # Number of invoice or credit note you are applying payment to e.g. INV-4003
  --currency-rate: float # Exchange rate when payment is received. Only used for non base currency invoices and credit notes e.g. 0.7500 (format: double)
  --date: string # Date the payment is being made (YYYY-MM-DD) e.g. 2009-09-06
  --details: string # The information to appear on the supplier's bank account
  --has-account: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --has-validation-errors: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --invoice: record # shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
  --invoice-number: string # Number of invoice or credit note you are applying payment to e.g.INV-4003
  --is-reconciled: oneof<nothing, bool> # An optional parameter for the payment. A boolean indicating whether you would like the payment to be created as reconciled when using PUT, or whether a payment has been reconciled when using GET
  --overpayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (13 more fields)}
  --particulars: string # The suppliers bank account number the payment is being made to
  --payment-id: string # The Xero identifier for an Payment e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --prepayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (12 more fields)}
  --reference: string # An optional description for the payment e.g. Direct Debit
  --status: string@status-completer-2 # The status of the payment.
  --status-attribute-string: string # A string to indicate if a invoice status
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Payments"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Account, var: account}, {name: Amount, var: amount}, {name: BankAccountNumber, var: bank_account_number}, {name: BatchPaymentID, var: batch_payment_id}, {name: Code, var: code}, {name: CreditNote, var: credit_note}, {name: CreditNoteNumber, var: credit_note_number}, {name: CurrencyRate, var: currency_rate}, {name: Date, var: date}, {name: Details, var: details}, {name: HasAccount, var: has_account}, {name: HasValidationErrors, var: has_validation_errors}, {name: Invoice, var: invoice}, {name: InvoiceNumber, var: invoice_number}, {name: IsReconciled, var: is_reconciled}, {name: Overpayment, var: overpayment}, {name: Particulars, var: particulars}, {name: PaymentID, var: payment_id}, {name: Prepayment, var: prepayment}, {name: Reference, var: reference}, {name: Status, var: status}, {name: StatusAttributeString, var: status_attribute_string}, {name: ValidationErrors, var: validation_errors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, account: $account, amount: $amount, bank_account_number: $bank_account_number, batch_payment_id: $batch_payment_id, code: $code, credit_note: $credit_note, credit_note_number: $credit_note_number, currency_rate: $currency_rate, date: $date, details: $details, has_account: $has_account, has_validation_errors: $has_validation_errors, invoice: $invoice, invoice_number: $invoice_number, is_reconciled: $is_reconciled, overpayment: $overpayment, particulars: $particulars, payment_id: $payment_id, prepayment: $prepayment, reference: $reference, status: $status, status_attribute_string: $status_attribute_string, validation_errors: $validation_errors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates multiple payments for invoices or credit notes
#
# PUT /Payments
# Returns: record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createPayments
export def "create-payments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --payments: list # item shape: {Account?: record, Amount?: float, BankAccountNumber?: string, BatchPaymentID?: string, Code?: string, CreditNote?: record, CreditNoteNumber?: string, CurrencyRate?: float, Date?: string, Details?: string, HasAccount?: bool, HasValidationErrors?: bool, Invoice?: record, InvoiceNumber?: string, IsReconciled?: bool, Overpayment?: record, Particulars?: string, PaymentID?: string, Prepayment?: record, Reference?: string, Status?: "AUTHORISED"|"DELETED", StatusAttributeString?: string, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Payments"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Payments, var: payments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, payments: $payments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific payment for invoices and credit notes using a unique payment Id
#
# GET /Payments/{PaymentID}
# Returns: record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getPayment
export def "get-payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Payments/{PaymentID}"
    path_params: [{name: PaymentID, var: payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific payment for invoices and credit notes
#
# POST /Payments/{PaymentID}
# Returns: record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: deletePayment
export def "delete-payment" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  status: string # The status of the payment. (default: DELETED)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Payments/{PaymentID}"
    path_params: [{name: PaymentID, var: payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, xero_tenant_id: $xero_tenant_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific payment
#
# GET /Payments/{PaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getPaymentHistory
export def "get-payment-history" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Payments/{PaymentID}/History"
    path_params: [{name: PaymentID, var: payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific payment
#
# PUT /Payments/{PaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createPaymentHistory
export def "create-payment-history" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Payments/{PaymentID}/History"
    path_params: [{name: PaymentID, var: payment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_id: $payment_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves prepayments
#
# GET /Prepayments
# Returns: record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>
# operationId: getPrepayments
export def "get-prepayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Reference ASC)
  --page: int # e.g. page=1 – Up to 100 prepayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Prepayments"
    query: [{name: where, var: where}, {name: order, var: order}, {name: page, var: page}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, page: $page, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to retrieve a specified prepayments
#
# GET /Prepayments/{PrepaymentID}
# Returns: record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>>
# operationId: getPrepayment
export def "get-prepayment" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Prepayments/{PrepaymentID}"
    path_params: [{name: PrepaymentID, var: prepayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prepayment_id: $prepayment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to create an Allocation for prepayments
#
# PUT /Prepayments/{PrepaymentID}/Allocations
# Returns: record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>>
# operationId: createPrepaymentAllocations
export def "create-prepayment-allocations" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Prepayments/{PrepaymentID}/Allocations"
    path_params: [{name: PrepaymentID, var: prepayment_id}]
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Allocations, var: allocations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prepayment_id: $prepayment_id, summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, allocations: $allocations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history record for a specific prepayment
#
# GET /Prepayments/{PrepaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getPrepaymentHistory
export def "get-prepayment-history" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Prepayments/{PrepaymentID}/History"
    path_params: [{name: PrepaymentID, var: prepayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prepayment_id: $prepayment_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific prepayment
#
# PUT /Prepayments/{PrepaymentID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createPrepaymentHistory
export def "create-prepayment-history" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Prepayments/{PrepaymentID}/History"
    path_params: [{name: PrepaymentID, var: prepayment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prepayment_id: $prepayment_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves purchase orders
#
# GET /PurchaseOrders
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: getPurchaseOrders
export def "get-purchase-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Filter by purchase order status (e.g. SUBMITTED)
  --date-from: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-01)
  --date-to: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-31)
  --order: string # Order by an any element (e.g. PurchaseOrderNumber ASC)
  --page: int # To specify a page, append the page parameter to the URL e.g. ?page=1. If there are 100 records in the response you will need to check if there is any more data by fetching the next page e.g ?page=2 and continuing this process until no more results are returned. (e.g. 1)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PurchaseOrders"
    query: [{name: Status, var: status}, {name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: order, var: order}, {name: page, var: page}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, date_from: $date_from, date_to: $date_to, order: $order, page: $page, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more purchase orders
#
# POST /PurchaseOrders
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: updateOrCreatePurchaseOrders
export def "update-or-create-purchase-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/PurchaseOrders"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PurchaseOrders, var: purchase_orders}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, purchase_orders: $purchase_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more purchase orders
#
# PUT /PurchaseOrders
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: createPurchaseOrders
export def "create-purchase-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PurchaseOrders"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PurchaseOrders, var: purchase_orders}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, purchase_orders: $purchase_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific purchase order using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: getPurchaseOrder
export def "get-purchase-order" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific purchase order
#
# POST /PurchaseOrders/{PurchaseOrderID}
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: updatePurchaseOrder
export def "update-purchase-order" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/PurchaseOrders/{PurchaseOrderID}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: PurchaseOrders, var: purchase_orders}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id, purchase_orders: $purchase_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getPurchaseOrderAttachments
export def "get-purchase-order-attachments" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}/Attachments"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves specific attachment for a specific purchase order using a unique attachment Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getPurchaseOrderAttachmentById
export def "get-purchase-order-attachment-by-id" [
  purchase_order_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}/Attachments/{AttachmentID}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment for a specific purchase order by filename
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# Returns: binary
# operationId: getPurchaseOrder≠AttachmentByFileName
export def "get-purchase-order-attachment-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment for a specific purchase order by filename
#
# POST /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updatePurchaseOrderAttachmentByFileName
export def "update-purchase-order-attachment-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates attachment for a specific purchase order
#
# PUT /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createPurchaseOrderAttachmentByFileName
export def "create-purchase-order-attachment-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getPurchaseOrderHistory
export def "get-purchase-order-history" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}/History"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific purchase orders
#
# PUT /PurchaseOrders/{PurchaseOrderID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createPurchaseOrderHistory
export def "create-purchase-order-history" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/PurchaseOrders/{PurchaseOrderID}/History"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves specific purchase order as PDF files using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/pdf
# Returns: binary
# operationId: getPurchaseOrderAsPdf
export def "get-purchase-order-as-pdf" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderID}/pdf"
    path_params: [{name: PurchaseOrderID, var: purchase_order_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_id: $purchase_order_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific purchase order using purchase order number
#
# GET /PurchaseOrders/{PurchaseOrderNumber}
# Returns: record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>>
# operationId: getPurchaseOrderByNumber
export def "get-purchase-order-by-number" [
  purchase_order_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/PurchaseOrders/{PurchaseOrderNumber}"
    path_params: [{name: PurchaseOrderNumber, var: purchase_order_number}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    purchase_order_number: $purchase_order_number, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves sales quotes
#
# GET /Quotes
# Returns: record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getQuotes
export def "get-quotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Filter for quotes after a particular date (format: date)
  --date-to: string # Filter for quotes before a particular date (format: date)
  --expiry-date-from: string # Filter for quotes expiring after a particular date (format: date)
  --expiry-date-to: string # Filter for quotes before a particular date (format: date)
  --contact-id: string # Filter for quotes belonging to a particular contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --status: string # Filter for quotes of a particular Status (e.g. DRAFT)
  --page: int # e.g. page=1 – Up to 100 Quotes will be returned in a single API call with line items shown for each quote (e.g. 1)
  --order: string # Order by an any element (e.g. Status ASC)
  --quote-number: string # Filter by quote number (e.g. GET https://.../Quotes?QuoteNumber=QU-0001) (e.g. QU-0001)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Quotes"
    query: [{name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: ExpiryDateFrom, var: expiry_date_from}, {name: ExpiryDateTo, var: expiry_date_to}, {name: ContactID, var: contact_id}, {name: Status, var: status}, {name: page, var: page}, {name: order, var: order}, {name: QuoteNumber, var: quote_number}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_from: $date_from, date_to: $date_to, expiry_date_from: $expiry_date_from, expiry_date_to: $expiry_date_to, contact_id: $contact_id, status: $status, page: $page, order: $order, quote_number: $quote_number, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates or creates one or more quotes
#
# POST /Quotes
# Returns: record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateOrCreateQuotes
export def "update-or-create-quotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Quotes"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Quotes, var: quotes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, quotes: $quotes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one or more quotes
#
# PUT /Quotes
# Returns: record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: createQuotes
export def "create-quotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Quotes"
    query: [{name: summarizeErrors, var: summarize_errors}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Quotes, var: quotes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    summarize_errors: $summarize_errors, xero_tenant_id: $xero_tenant_id, quotes: $quotes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific quote using a unique quote Id
#
# GET /Quotes/{QuoteID}
# Returns: record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: getQuote
export def "get-quote" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific quote
#
# POST /Quotes/{QuoteID}
# Returns: record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>>
# operationId: updateQuote
export def "update-quote" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Quotes/{QuoteID}"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Quotes, var: quotes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id, quotes: $quotes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific quote
#
# GET /Quotes/{QuoteID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getQuoteAttachments
export def "get-quote-attachments" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}/Attachments"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific quote using a unique attachment Id
#
# GET /Quotes/{QuoteID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getQuoteAttachmentById
export def "get-quote-attachment-by-id" [
  quote_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}/Attachments/{AttachmentID}"
    path_params: [{name: QuoteID, var: quote_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific quote by filename
#
# GET /Quotes/{QuoteID}/Attachments/{FileName}
# Returns: binary
# operationId: getQuoteAttachmentByFileName
export def "get-quote-attachment-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}/Attachments/{FileName}"
    path_params: [{name: QuoteID, var: quote_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment from a specific quote by filename
#
# POST /Quotes/{QuoteID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateQuoteAttachmentByFileName
export def "update-quote-attachment-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Quotes/{QuoteID}/Attachments/{FileName}"
    path_params: [{name: QuoteID, var: quote_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates attachment for a specific quote
#
# PUT /Quotes/{QuoteID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createQuoteAttachmentByFileName
export def "create-quote-attachment-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Quotes/{QuoteID}/Attachments/{FileName}"
    path_params: [{name: QuoteID, var: quote_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history records of a specific quote
#
# GET /Quotes/{QuoteID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getQuoteHistory
export def "get-quote-history" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}/History"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific quote
#
# PUT /Quotes/{QuoteID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createQuoteHistory
export def "create-quote-history" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Quotes/{QuoteID}/History"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific quote as a PDF file using a unique quote Id
#
# GET /Quotes/{QuoteID}/pdf
# Returns: binary
# operationId: getQuoteAsPdf
export def "get-quote-as-pdf" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  http-request {
    method: get
    path: "/Quotes/{QuoteID}/pdf"
    path_params: [{name: QuoteID, var: quote_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    quote_id: $quote_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves draft expense claim receipts for any user
#
# GET /Receipts
# Returns: record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>
# operationId: getReceipts
export def "get-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. ReceiptNumber ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Receipts"
    query: [{name: where, var: where}, {name: order, var: order}, {name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates draft expense claim receipts for any user
#
# PUT /Receipts
# Returns: record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>
# operationId: createReceipt
export def "create-receipt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Receipts"
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Receipts, var: receipts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, receipts: $receipts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific draft expense claim receipt by using a unique receipt Id
#
# GET /Receipts/{ReceiptID}
# Returns: record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>
# operationId: getReceipt
export def "get-receipt" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Receipts/{ReceiptID}"
    path_params: [{name: ReceiptID, var: receipt_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific draft expense claim receipts
#
# POST /Receipts/{ReceiptID}
# Returns: record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>>
# operationId: updateReceipt
export def "update-receipt" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Receipts/{ReceiptID}"
    path_params: [{name: ReceiptID, var: receipt_id}]
    query: [{name: unitdp, var: unitdp}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Receipts, var: receipts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, unitdp: $unitdp, xero_tenant_id: $xero_tenant_id, receipts: $receipts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments for a specific expense claim receipt
#
# GET /Receipts/{ReceiptID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getReceiptAttachments
export def "get-receipt-attachments" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Receipts/{ReceiptID}/Attachments"
    path_params: [{name: ReceiptID, var: receipt_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachments from a specific expense claim receipts by using a unique attachment Id
#
# GET /Receipts/{ReceiptID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getReceiptAttachmentById
export def "get-receipt-attachment-by-id" [
  receipt_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Receipts/{ReceiptID}/Attachments/{AttachmentID}"
    path_params: [{name: ReceiptID, var: receipt_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific expense claim receipts by file name
#
# GET /Receipts/{ReceiptID}/Attachments/{FileName}
# Returns: binary
# operationId: getReceiptAttachmentByFileName
export def "get-receipt-attachment-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/Receipts/{ReceiptID}/Attachments/{FileName}"
    path_params: [{name: ReceiptID, var: receipt_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment on a specific expense claim receipts by file name
#
# POST /Receipts/{ReceiptID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateReceiptAttachmentByFileName
export def "update-receipt-attachment-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Receipts/{ReceiptID}/Attachments/{FileName}"
    path_params: [{name: ReceiptID, var: receipt_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment on a specific expense claim receipts by file name
#
# PUT /Receipts/{ReceiptID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createReceiptAttachmentByFileName
export def "create-receipt-attachment-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Receipts/{ReceiptID}/Attachments/{FileName}"
    path_params: [{name: ReceiptID, var: receipt_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a history record for a specific receipt
#
# GET /Receipts/{ReceiptID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getReceiptHistory
export def "get-receipt-history" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Receipts/{ReceiptID}/History"
    path_params: [{name: ReceiptID, var: receipt_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific receipt
#
# PUT /Receipts/{ReceiptID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createReceiptHistory
export def "create-receipt-history" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Receipts/{ReceiptID}/History"
    path_params: [{name: ReceiptID, var: receipt_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    receipt_id: $receipt_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves repeating invoices
#
# GET /RepeatingInvoices
# Returns: record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>>
# operationId: getRepeatingInvoices
export def "get-repeating-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Total ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/RepeatingInvoices"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific repeating invoice by using a unique repeating invoice Id
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}
# Returns: record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>>
# operationId: getRepeatingInvoice
export def "get-repeating-invoice" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/RepeatingInvoices/{RepeatingInvoiceID}"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves attachments from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: getRepeatingInvoiceAttachments
export def "get-repeating-invoice-attachments" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/Attachments"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{AttachmentID}
# Returns: binary
# operationId: getRepeatingInvoiceAttachmentById
export def "get-repeating-invoice-attachment-by-id" [
  repeating_invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{AttachmentID}"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}, {name: AttachmentID, var: attachment_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, attachment_id: $attachment_id, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific attachment from a specific repeating invoices by file name
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# Returns: binary
# operationId: getRepeatingInvoiceAttachmentByFileName
export def "get-repeating-invoice-attachment-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (required, e.g. image/jpg)
]: nothing -> any {
  http-request {
    method: get
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: contentType, var: content_type, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific attachment from a specific repeating invoices by file name
#
# POST /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: updateRepeatingInvoiceAttachmentByFileName
export def "update-repeating-invoice-attachment-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an attachment from a specific repeating invoices by file name
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# Returns: record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>>
# operationId: createRepeatingInvoiceAttachmentByFileName
export def "create-repeating-invoice-attachment-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}, {name: FileName, var: file_name}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, file_name: $file_name, xero_tenant_id: $xero_tenant_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves history record for a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: getRepeatingInvoiceHistory
export def "get-repeating-invoice-history" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/History"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a history record for a specific repeating invoice
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/History
# Returns: record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>>
# operationId: createRepeatingInvoiceHistory
export def "create-repeating-invoice-history" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/RepeatingInvoices/{RepeatingInvoiceID}/History"
    path_params: [{name: RepeatingInvoiceID, var: repeating_invoice_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: HistoryRecords, var: history_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repeating_invoice_id: $repeating_invoice_id, xero_tenant_id: $xero_tenant_id, history_records: $history_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for BAS (only valid for AU orgs)
#
# GET /Reports
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportBASorGSTList
export def "get-report-ba-sor-gst-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for aged payables by contact
#
# GET /Reports/AgedPayablesByContact
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportAgedPayablesByContact
export def "get-report-aged-payables-by-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Unique identifier for a Contact (required, format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Payables By Contact report (format: date)
  --from-date: string # The from date of the Aged Payables By Contact report (format: date)
  --to-date: string # The to date of the Aged Payables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/AgedPayablesByContact"
    query: [{name: contactId, var: contact_id, required: true}, {name: date, var: date}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, date: $date, from_date: $from_date, to_date: $to_date, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for aged receivables by contact
#
# GET /Reports/AgedReceivablesByContact
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportAgedReceivablesByContact
export def "get-report-aged-receivables-by-contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Unique identifier for a Contact (required, format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Receivables By Contact report (format: date)
  --from-date: string # The from date of the Aged Receivables By Contact report (format: date)
  --to-date: string # The to date of the Aged Receivables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/AgedReceivablesByContact"
    query: [{name: contactId, var: contact_id, required: true}, {name: date, var: date}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, date: $date, from_date: $from_date, to_date: $to_date, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for balancesheet
#
# GET /Reports/BalanceSheet
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportBalanceSheet
export def "get-report-balance-sheet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date of the Balance Sheet report (format: date, e.g. 2019-11-01)
  --periods: int # The number of periods for the Balance Sheet report (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --tracking-option-id1: string # The tracking option 1 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id2: string # The tracking option 2 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --standard-layout: oneof<nothing, bool> # The standard layout boolean for the Balance Sheet report (e.g. true)
  --payments-only: oneof<nothing, bool> # return a cash basis for the Balance Sheet report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/BalanceSheet"
    query: [{name: date, var: date}, {name: periods, var: periods}, {name: timeframe, var: timeframe}, {name: trackingOptionID1, var: tracking_option_id1}, {name: trackingOptionID2, var: tracking_option_id2}, {name: standardLayout, var: standard_layout}, {name: paymentsOnly, var: payments_only}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, periods: $periods, timeframe: $timeframe, tracking_option_id1: $tracking_option_id1, tracking_option_id2: $tracking_option_id2, standard_layout: $standard_layout, payments_only: $payments_only, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for bank summary
#
# GET /Reports/BankSummary
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportBankSummary
export def "get-report-bank-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # The from date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-01)
  --to-date: string # The to date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-30)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/BankSummary"
    query: [{name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    from_date: $from_date, to_date: $to_date, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for budget summary
#
# GET /Reports/BudgetSummary
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportBudgetSummary
export def "get-report-budget-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --period: int # The number of periods to compare (integer between 1 and 12) (e.g. 2)
  --timeframe: int # The period size to compare to (1=month, 3=quarter, 12=year) (e.g. 3)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/BudgetSummary"
    query: [{name: date, var: date}, {name: period, var: period}, {name: timeframe, var: timeframe}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, period: $period, timeframe: $timeframe, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for executive summary
#
# GET /Reports/ExecutiveSummary
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportExecutiveSummary
export def "get-report-executive-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/ExecutiveSummary"
    query: [{name: date, var: date}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for profit and loss
#
# GET /Reports/ProfitAndLoss
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportProfitAndLoss
export def "get-report-profit-and-loss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # The from date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-01)
  --to-date: string # The to date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --periods: int # The number of periods to compare (integer between 1 and 12) (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --tracking-category-id: string # The trackingCategory 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-category-id2: string # The trackingCategory 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id: string # The tracking option 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id2: string # The tracking option 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --standard-layout: oneof<nothing, bool> # Return the standard layout for the ProfitAndLoss report (e.g. true)
  --payments-only: oneof<nothing, bool> # Return cash only basis for the ProfitAndLoss report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/ProfitAndLoss"
    query: [{name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: periods, var: periods}, {name: timeframe, var: timeframe}, {name: trackingCategoryID, var: tracking_category_id}, {name: trackingCategoryID2, var: tracking_category_id2}, {name: trackingOptionID, var: tracking_option_id}, {name: trackingOptionID2, var: tracking_option_id2}, {name: standardLayout, var: standard_layout}, {name: paymentsOnly, var: payments_only}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    from_date: $from_date, to_date: $to_date, periods: $periods, timeframe: $timeframe, tracking_category_id: $tracking_category_id, tracking_category_id2: $tracking_category_id2, tracking_option_id: $tracking_option_id, tracking_option_id2: $tracking_option_id2, standard_layout: $standard_layout, payments_only: $payments_only, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve reports for 1099
#
# GET /Reports/TenNinetyNine
# Returns: record<Reports: table<Contacts: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportType: string, UpdatedDateUTC: string>>
# operationId: getReportTenNinetyNine
export def "get-report-ten-ninety-nine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-year: string # The year of the 1099 report (e.g. 2019)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/TenNinetyNine"
    query: [{name: reportYear, var: report_year}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_year: $report_year, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves report for trial balance
#
# GET /Reports/TrialBalance
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportTrialBalance
export def "get-report-trial-balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Trial Balance report e.g. 2018-03-31 (format: date, e.g. 2019-10-31)
  --payments-only: oneof<nothing, bool> # Return cash only basis for the Trial Balance report (e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/TrialBalance"
    query: [{name: date, var: date}, {name: paymentsOnly, var: payments_only}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, payments_only: $payments_only, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific report for BAS using a unique report Id (only valid for AU orgs)
#
# GET /Reports/{ReportID}
# Returns: record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>>
# operationId: getReportBASorGST
export def "get-report-ba-sor-gst" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports/{ReportID}"
    path_params: [{name: ReportID, var: report_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_id: $report_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the chart of accounts, the conversion date and conversion balances
#
# POST /Setup
# Returns: record<ImportSummary: record<Accounts: record<Deleted: float, Errored: float, Locked: float, New: float, NewOrUpdated: float, Present: bool, System: float, Total: float, Updated: float>, Organisation: record<Present: bool>>>
# operationId: postSetup
export def "post-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
  --conversion-balances: list # Balance supplied for each account that has a value as at the conversion date. — item shape: {AccountCode?: string, Balance?: float, BalanceDetails?: list}
  --conversion-date: record # The date when the organisation starts using Xero — shape: {Month?: int, Year?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Setup"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Accounts, var: accounts}, {name: ConversionBalances, var: conversion_balances}, {name: ConversionDate, var: conversion_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, accounts: $accounts, conversion_balances: $conversion_balances, conversion_date: $conversion_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves tax rates
#
# GET /TaxRates
# Returns: record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>
# operationId: getTaxRates
export def "get-tax-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --tax-type: string # Filter by tax type (e.g. INPUT)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TaxRates"
    query: [{name: where, var: where}, {name: order, var: order}, {name: TaxType, var: tax_type}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, tax_type: $tax_type, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates tax rates
#
# POST /TaxRates
# Returns: record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>
# operationId: updateTaxRate
export def "update-tax-rate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --tax-rates: list # item shape: {Name?: string, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TaxRates"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaxRates, var: tax_rates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, tax_rates: $tax_rates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more tax rates
#
# PUT /TaxRates
# Returns: record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>>
# operationId: createTaxRates
export def "create-tax-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --tax-rates: list # item shape: {Name?: string, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/TaxRates"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: TaxRates, var: tax_rates}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, tax_rates: $tax_rates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves tracking categories and options
#
# GET /TrackingCategories
# Returns: record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: getTrackingCategories
export def "get-tracking-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Categories and options with a status of ARCHIVED will be included in the response
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TrackingCategories"
    query: [{name: where, var: where}, {name: order, var: order}, {name: includeArchived, var: include_archived}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, include_archived: $include_archived, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create tracking categories
#
# PUT /TrackingCategories
# Returns: record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: createTrackingCategory
export def "create-tracking-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --status: string@status-completer # The status of a tracking category
  --tracking-category-id: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/TrackingCategories"
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Option, var: option}, {name: Options, var: options}, {name: Status, var: status}, {name: TrackingCategoryID, var: tracking_category_id}, {name: TrackingOptionID, var: tracking_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xero_tenant_id: $xero_tenant_id, name: $name, option: $option, options: $options, status: $status, tracking_category_id: $tracking_category_id, tracking_option_id: $tracking_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}
# Returns: record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: deleteTrackingCategory
export def "delete-tracking-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/TrackingCategories/{TrackingCategoryID}"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves specific tracking categories and options using a unique tracking category Id
#
# GET /TrackingCategories/{TrackingCategoryID}
# Returns: record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: getTrackingCategory
export def "get-tracking-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TrackingCategories/{TrackingCategoryID}"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}
# Returns: record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: updateTrackingCategory
export def "update-tracking-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --status: string@status-completer # The status of a tracking category
  --body-tracking-category-id: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid) (spec name: TrackingCategoryID)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TrackingCategories/{TrackingCategoryID}"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Option, var: option}, {name: Options, var: options}, {name: Status, var: status}, {name: TrackingCategoryID, var: body_tracking_category_id}, {name: TrackingOptionID, var: tracking_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, xero_tenant_id: $xero_tenant_id, name: $name, option: $option, options: $options, status: $status, body_tracking_category_id: $body_tracking_category_id, tracking_option_id: $tracking_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates options for a specific tracking category
#
# PUT /TrackingCategories/{TrackingCategoryID}/Options
# Returns: record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: createTrackingOptions
export def "create-tracking-options" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --status: string@status-completer # The status of a tracking option
  --body-tracking-category-id: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid) (spec name: TrackingCategoryID)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/TrackingCategories/{TrackingCategoryID}/Options"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Status, var: status}, {name: TrackingCategoryID, var: body_tracking_category_id}, {name: TrackingOptionID, var: tracking_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, xero_tenant_id: $xero_tenant_id, name: $name, status: $status, body_tracking_category_id: $body_tracking_category_id, tracking_option_id: $tracking_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific option for a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# Returns: record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: deleteTrackingOptions
export def "delete-tracking-options" [
  tracking_category_id: string
  tracking_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}, {name: TrackingOptionID, var: tracking_option_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, tracking_option_id: $tracking_option_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a specific option for a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# Returns: record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>>
# operationId: updateTrackingOptions
export def "update-tracking-options" [
  tracking_category_id: string
  tracking_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --status: string@status-completer # The status of a tracking option
  --body-tracking-category-id: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid) (spec name: TrackingCategoryID)
  --body-tracking-option-id: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid) (spec name: TrackingOptionID)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}"
    path_params: [{name: TrackingCategoryID, var: tracking_category_id}, {name: TrackingOptionID, var: tracking_option_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Status, var: status}, {name: TrackingCategoryID, var: body_tracking_category_id}, {name: TrackingOptionID, var: body_tracking_option_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tracking_category_id: $tracking_category_id, tracking_option_id: $tracking_option_id, xero_tenant_id: $xero_tenant_id, name: $name, status: $status, body_tracking_category_id: $body_tracking_category_id, body_tracking_option_id: $body_tracking_option_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves users
#
# GET /Users
# Returns: record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>>
# operationId: getUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --where: string # Filter by an any element (e.g. IsSubscriber==true)
  --order: string # Order by an any element (e.g. LastName ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (format: date-time, e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Users"
    query: [{name: where, var: where}, {name: order, var: order}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}, {name: If-Modified-Since, var: if_modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    where: $where, order: $order, xero_tenant_id: $xero_tenant_id, if_modified_since: $if_modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific user
#
# GET /Users/{UserID}
# Returns: record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>>
# operationId: getUser
export def "get-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (required, e.g. YOUR_XERO_TENANT_ID)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Users/{UserID}"
    path_params: [{name: UserID, var: user_id}]
    header: [{name: xero-tenant-id, var: xero_tenant_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, xero_tenant_id: $xero_tenant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
