# Auto-generated client for Accounting API v2.1.0
# Source: https://api.apis.guru/v2/specs/codat.io/accounting/2.1.0/openapi.json
# Auth: --token flag or $env.ACCOUNTING_API_TOKEN

const CLIENT = {
  base_url: "https://api.codat.io"
  token_env_var: "ACCOUNTING_API_TOKEN"
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

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["Active" "Archived" "Pending" "Unknown"] }
def type-completer [] { ["Asset" "Equity" "Expense" "Income" "Liability" "Unknown"] }
def account-type-completer [] { ["Credit" "Debit" "Unknown"] }
def status-completer-1 [] { ["Draft" "Paid" "PartiallyPaid" "Submitted" "Unknown" "Void"] }
def status-completer-2 [] { ["Draft" "Open" "Paid" "PartiallyPaid" "Unknown" "Void"] }
def status-completer-3 [] { ["Active" "Archived" "Unknown"] }
def item-status-completer [] { ["Active" "Archived" "Unknown"] }
def status-completer-4 [] { ["Closed" "Draft" "Open" "Unknown" "Void"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-account-transactions: "record<results: table<bankAccountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-account-transaction: "record<bankAccountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<amount: float, description: string, recordRef: record>, metadata: record<isDeleted: bool>, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>"
    list-bank-accounts: "record<results: table<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-bank-account: "record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>"
    list-bank-account-transactions: "record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-bill-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-bill-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    get-customer-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-customer-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    get-direct-costs: "record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-direct-cost: "record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-direct-cost-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-direct-cost-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    get-direct-incomes: "record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-direct-income: "record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-direct-income-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-direct-income-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    get-invoice-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-invoice-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    list-supplier-attachments: "record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>"
    get-supplier-attachment: "record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>"
    list-transfers: "record<results: table<contactRef: record, date: string, depositedRecordRefs: list, description: string, from: record, id: string, metadata: record, supplementalData: record, to: record, trackingCategoryRefs: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-transfer: "record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, trackingCategoryRefs: table<id: string, name: string>, modifiedDate: string, sourceModifiedDate: string>"
    get-create-update-bank-accounts-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-bank-account-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-bill-credit-notes-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-bill-payments-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-bills-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-chart-of-accounts-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-credit-notes-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-customers-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-direct-costs-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-direct-incomes-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-invoices-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-items-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-journal-entries-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-journals-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-payments-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-purchase-orders-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-update-suppliers-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    get-create-transfers-model: "record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>"
    create-account: "record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-bank-account: "record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-bank-transactions: "record<data: record<accountId: string, transactions: list<record>>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-bank-account: "record<data: record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-bill-credit-note: "record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-bill-credit-note: "record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-bill-payment: "record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    delete-bill-payment: "record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-bill: "record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    delete-bill: "record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-bill: "record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-credit-note: "record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-credit-note: "record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-customer: "record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-customer: "record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-direct-cost: "record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-direct-income: "record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-invoice: "record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    delete-invoice: "record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-invoice: "record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-item: "record<data: record<billItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-journal-entry: "record<data: record<createdOn: string, description: string, id: string, journalLines: list<record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    delete-journal-entry: "record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    push-journal: "record<data: record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-payment: "record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-purchase-order: "record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    update-purchase-order: "record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-supplier: "record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    put-supplier: "record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    create-transfer: "record<data: record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record, amount: float, currency: string>, trackingCategoryRefs: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>"
    list-accounts: "record<results: table<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-account: "record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>"
    get-all-bank-account: "record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: record<modifiedDate: string>, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: record<sourceModifiedDate: string>, toDate: string>"
    list-bank-transactions: "record<results: table<amount: float, balance: float, clearedOnDate: string, counterparty: string, description: string, id: string, reconciled: bool, reference: string, transactionType: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    list-bill-credit-notes: "record<results: table<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-bill-credit-note: "record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>"
    list-bill-payments: "record<results: table<accountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, paymentMethodRef: record, reference: string, supplementalData: record, supplierRef: record, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-bill-payments: "record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-bills: "record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-bill: "record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectCost: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, purchaseOrderRefs: table<id: string, purchaseOrderNumber: string>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>"
    list-credit-notes: "record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-credit-note: "record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>"
    get-customers: "record<results: table<addresses: list, contactName: string, contacts: list, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-customer: "record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, contacts: table<address: record, email: string, modifiedDate: string, name: string, phone: list, status: string>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>"
    get-balance-sheet: "record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: table<assets: record, date: string, equity: record, liabilities: record, netAssets: float>>"
    get-cash-flow-statement: "record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reportInput: string, reports: table<cashPayments: record, cashReceipts: record, fromDate: string, toDate: string>>"
    get-profit-and-loss: "record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reports: table<costOfSales: record, expenses: record, fromDate: string, grossProfit: float, income: record, netOperatingProfit: float, netOtherIncome: float, netProfit: float, otherExpenses: record, otherIncome: record, toDate: string>>"
    get-company-info: "record<accountingPlatformRef: string, addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, baseCurrency: string, companyLegalName: string, companyName: string, createdDate: string, financialYearStartDate: string, ledgerLockDate: string, phoneNumbers: table<number: string, type: string>, registrationNumber: string, sourceUrls: record, taxNumber: string, webLinks: table<type: string, url: string>>"
    post-sync-info: "record<companyId: string, completed: string, connectionId: string, dataType: string, datasetLogsUrl: string, errorMessage: string, id: string, isCompleted: bool, isErrored: bool, progress: int, requested: string, status: string, validationInformationUrl: string>"
    list-invoices: "record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list, metadata: record, note: string, paidOnDate: string, paymentAllocations: list, salesOrderRefs: list, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-invoice: "record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: table<allocation: record, payment: record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>"
    list-items: "record<results: table<billItem: record, code: string, id: string, invoiceItem: record, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-item: "record<billItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>"
    list-journal-entries: "record<results: table<createdOn: string, description: string, id: string, journalLines: list, journalRef: record, metadata: record, postedOn: string, recordRef: record, supplementalData: record, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-journal-entry: "record<createdOn: string, description: string, id: string, journalLines: table<accountRef: record, currency: string, description: string, netAmount: float, tracking: record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>"
    list-journals: "record<results: table<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-journal: "record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>"
    list-payment-methods: "record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-payment-method: "record<id: string, metadata: record<isDeleted: bool>, name: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>"
    list-payments: "record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-payment: "record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-purchase-orders: "record<results: table<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record, status: string, subTotal: float, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-purchase-order: "record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-sales-orders: "record<results: table<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: list, metadata: record, note: string, salesOrderNumber: string, shipTo: record, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-sales-order: "record<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record<companyName: string, id: string>, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, salesOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>"
    list-suppliers: "record<results: table<addresses: list, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-supplier: "record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>"
    list-tax-rates: "record<results: table<code: string, components: list, effectiveTaxRate: float, id: string, metadata: record, name: string, status: string, totalTaxRate: float, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-tax-rate: "record<code: string, components: table<isCompound: bool, name: string, rate: float>, effectiveTaxRate: float, id: string, metadata: record<isDeleted: bool>, name: string, status: string, totalTaxRate: float, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>"
    list-tracking-categories: "record<results: table<hasChildren: bool, id: string, name: string, parentId: string, status: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>"
    get-tracking-category: "record<hasChildren: bool, id: string, name: string, parentId: string, status: string, subCategories: list<any>, modifiedDate: string, sourceModifiedDate: string>"
    get-aged-creditors-report: "record<data: table<agedCurrencyOutstanding: list, supplierId: string, supplierName: string>, generated: string, reportDate: string>"
    is-aged-creditors-report-available: "bool"
    get-aged-debtors-report: "record<data: table<agedCurrencyOutstanding: list, customerId: string, customerName: string>, generated: string, reportDate: string>"
    is-aged-debtor-report-available: "bool"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-account-transactions" "get-account-transaction" "list-bank-accounts" "get-bank-account" "list-bank-account-transactions" "get-bill-attachments" "get-bill-attachment" "download-bill-attachment" "get-customer-attachments" "get-customer-attachment" "download-customer-attachment" "get-direct-costs" "get-direct-cost" "list-direct-cost-attachments" "get-direct-cost-attachment" "download-direct-cost-attachment" "get-direct-incomes" "get-direct-income" "list-direct-income-attachments" "get-direct-income-attachment" "download-direct-income-attachment" "get-invoice-attachments" "get-invoice-attachment" "download-invoice-attachment" "list-supplier-attachments" "get-supplier-attachment" "download-supplier-attachment" "list-transfers" "get-transfer" "get-create-update-bank-accounts-model" "get-create-bank-account-model" "get-create-update-bill-credit-notes-model" "get-create-bill-payments-model" "get-create-update-bills-model" "get-create-chart-of-accounts-model" "get-create-update-credit-notes-model" "get-create-update-customers-model" "get-create-direct-costs-model" "get-create-direct-incomes-model" "get-create-update-invoices-model" "get-create-items-model" "get-create-journal-entries-model" "get-create-journals-model" "get-create-payments-model" "get-create-update-purchase-orders-model" "get-create-update-suppliers-model" "get-create-transfers-model" "create-account" "create-bank-account" "create-bank-transactions" "update-bank-account" "create-bill-credit-note" "update-bill-credit-note" "create-bill-payment" "delete-bill-payment" "create-bill" "delete-bill" "update-bill" "upload-bill-attachments" "create-credit-note" "update-credit-note" "create-customer" "update-customer" "create-direct-cost" "upload-direct-cost-attachment" "create-direct-income" "upload-direct-income-attachment" "create-invoice" "delete-invoice" "update-invoice" "upload-invoice-attachment" "create-item" "create-journal-entry" "delete-journal-entry" "push-journal" "create-payment" "create-purchase-order" "update-purchase-order" "create-supplier" "put-supplier" "create-transfer" "list-accounts" "get-account" "get-all-bank-account" "list-bank-transactions" "list-bill-credit-notes" "get-bill-credit-note" "list-bill-payments" "get-bill-payments" "list-bills" "get-bill" "list-credit-notes" "get-credit-note" "get-customers" "get-customer" "get-balance-sheet" "get-cash-flow-statement" "get-profit-and-loss" "get-company-info" "post-sync-info" "list-invoices" "get-invoice" "download-invoice-pdf" "list-items" "get-item" "list-journal-entries" "get-journal-entry" "list-journals" "get-journal" "list-payment-methods" "get-payment-method" "list-payments" "get-payment" "list-purchase-orders" "get-purchase-order" "list-sales-orders" "get-sales-order" "list-suppliers" "get-supplier" "list-tax-rates" "get-tax-rate" "list-tracking-categories" "get-tracking-category" "get-aged-creditors-report" "is-aged-creditors-report-available" "get-aged-debtors-report" "is-aged-debtor-report-available" "commands"] | sort) } | get name | first)
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

# List account transactions
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions
# Returns: record<results: table<bankAccountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-account-transactions
export def "list-account-transactions" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/accountTransactions"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account transaction
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}
# Returns: record<bankAccountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<amount: float, description: string, recordRef: record>, metadata: record<isDeleted: bool>, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-account-transaction
export def "get-account-transaction" [
  company_id: string
  connection_id: string
  account_transaction_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountTransactionId, var: account_transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_transaction_id: $account_transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bank accounts
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts
# Returns: record<results: table<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bank-accounts
export def "list-bank-accounts" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/bankAccounts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}
# DEPRECATED
# Returns: record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-bank-account
@deprecated
export def "get-bank-account" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bank transactions for bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions
# Returns: record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bank-account-transactions
export def "list-bank-account-transactions" [
  company_id: string
  connection_id: string
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bill attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: get-bill-attachments
export def "get-bill-attachments" [
  company_id: string
  connection_id: string
  bill_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-bill-attachment
export def "get-bill-attachment" [
  company_id: string
  connection_id: string
  bill_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download
# operationId: download-bill-attachment
export def "download-bill-attachment" [
  company_id: string
  connection_id: string
  bill_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List customer attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: get-customer-attachments
export def "get-customer-attachments" [
  company_id: string
  connection_id: string
  customer_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: customerId, var: customer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-customer-attachment
export def "get-customer-attachment" [
  company_id: string
  connection_id: string
  customer_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: customerId, var: customer_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download
# operationId: download-customer-attachment
export def "download-customer-attachment" [
  company_id: string
  connection_id: string
  customer_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: customerId, var: customer_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List direct costs
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts
# Returns: record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: get-direct-costs
export def "get-direct-costs" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directCosts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct cost
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}
# DEPRECATED
# Returns: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-direct-cost
@deprecated
export def "get-direct-cost" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directCostId, var: direct_cost_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List direct cost attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: list-direct-cost-attachments
export def "list-direct-cost-attachments" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directCostId, var: direct_cost_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-direct-cost-attachment
export def "get-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directCostId, var: direct_cost_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download
# operationId: download-direct-cost-attachment
export def "download-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directCostId, var: direct_cost_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct incomes
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes
# Returns: record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: get-direct-incomes
export def "get-direct-incomes" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directIncomes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct income
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}
# DEPRECATED
# Returns: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-direct-income
@deprecated
export def "get-direct-income" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directIncomeId, var: direct_income_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List direct income attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: list-direct-income-attachments
export def "list-direct-income-attachments" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directIncomeId, var: direct_income_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-direct-income-attachment
export def "get-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
  --timeout-in-minutes: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directIncomeId, var: direct_income_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id, attachment_id: $attachment_id, timeout_in_minutes: $timeout_in_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download
# operationId: download-direct-income-attachment
export def "download-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directIncomeId, var: direct_income_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoice attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: get-invoice-attachments
export def "get-invoice-attachments" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-invoice-attachment
export def "get-invoice-attachment" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download
# operationId: download-invoice-attachment
export def "download-invoice-attachment" [
  company_id: string
  connection_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List supplier attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments
# Returns: record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>
# operationId: list-supplier-attachments
export def "list-supplier-attachments" [
  company_id: string
  connection_id: string
  supplier_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: supplierId, var: supplier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}
# Returns: record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-supplier-attachment
export def "get-supplier-attachment" [
  company_id: string
  connection_id: string
  supplier_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: supplierId, var: supplier_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download
# operationId: download-supplier-attachment
export def "download-supplier-attachment" [
  company_id: string
  connection_id: string
  supplier_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: supplierId, var: supplier_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transfers
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers
# Returns: record<results: table<contactRef: record, date: string, depositedRecordRefs: list, description: string, from: record, id: string, metadata: record, supplementalData: record, to: record, trackingCategoryRefs: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-transfers
export def "list-transfers" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/data/transfers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transfer
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers/{transferId}
# DEPRECATED
# Returns: record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, trackingCategoryRefs: table<id: string, name: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-transfer
@deprecated
export def "get-transfer" [
  company_id: string
  connection_id: string
  transfer_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/data/transfers/{transferId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: transferId, var: transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, transfer_id: $transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update bank account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-bankAccounts-model
export def "get-create-update-bank-accounts-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/bankAccounts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List push options for bank account bank transactions
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-bank-account-model
export def "get-create-bank-account-model" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update bill credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billCreditNotes
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-billCreditNotes-model
export def "get-create-update-bill-credit-notes-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/billCreditNotes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create bill payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billPayments
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-billPayments-model
export def "get-create-bill-payments-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/billPayments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update bill model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bills
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-bills-model
export def "get-create-update-bills-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/bills"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/chartOfAccounts
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-chartOfAccounts-model
export def "get-create-chart-of-accounts-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/chartOfAccounts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/creditNotes
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-creditNotes-model
export def "get-create-update-credit-notes-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/creditNotes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update customer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/customers
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-customers-model
export def "get-create-update-customers-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/customers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create direct cost model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directCosts
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-directCosts-model
export def "get-create-direct-costs-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/directCosts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create direct income model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directIncomes
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-directIncomes-model
export def "get-create-direct-incomes-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/directIncomes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update invoice model
#
# GET /companies/{companyId}/connections/{connectionId}/options/invoices
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-invoices-model
export def "get-create-update-invoices-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/invoices"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create item model
#
# GET /companies/{companyId}/connections/{connectionId}/options/items
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-items-model
export def "get-create-items-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/items"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create journal entry model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journalEntries
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-journalEntries-model
export def "get-create-journal-entries-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/journalEntries"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create journal model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journals
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-journals-model
export def "get-create-journals-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/journals"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/payments
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-payments-model
export def "get-create-payments-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/payments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update purchase order model
#
# GET /companies/{companyId}/connections/{connectionId}/options/purchaseOrders
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-purchaseOrders-model
export def "get-create-update-purchase-orders-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/purchaseOrders"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create/update supplier model
#
# GET /companies/{companyId}/connections/{connectionId}/options/suppliers
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-update-suppliers-model
export def "get-create-update-suppliers-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/suppliers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get create transfer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/transfers
# Returns: record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>
# operationId: get-create-transfers-model
export def "get-create-transfers-model" [
  company_id: string
  connection_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/options/transfers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create account
#
# POST /companies/{companyId}/connections/{connectionId}/push/accounts
# Returns: record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-account
export def "create-account" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --current-balance: float # Current balance in the account. (nullable)
  --description: string # Description for the account. (nullable)
  --fully-qualified-category: string # Full category of the account. For example: Liability.Current or Income.Revenue. See example data. (nullable)
  --fully-qualified-name: string # Full name of the account, for example: - `Liability.Current.VAT` - `Income.Revenue.Sales` (nullable)
  --id: string # Identifier for the account, unique for the company.
  --is-bank-account: oneof<nothing, bool> # Confirms whether the account is a bank account or not.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the account. (nullable)
  --nominal-code: string # Reference given to each nominal account for a business. It ensures money is allocated to the correct account. This code isn't a unique identifier in the Codat system. (nullable)
  status: string@status-completer # Status of the account
  type: string@type-completer # Type of account
  --valid-datatype-links: list # 'The validDatatypeLinks can be used to determine whether an account can be correctly mapped to another object; for example, accounts with a `type` of `income` might only support being used on an Invoice and Direct Income. For more information, see Valid Data Type Links.' (nullable) — item shape: {links?: list<string>, property?: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/accounts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: currentBalance, var: current_balance}, {name: description, var: description}, {name: fullyQualifiedCategory, var: fully_qualified_category}, {name: fullyQualifiedName, var: fully_qualified_name}, {name: id, var: id}, {name: isBankAccount, var: is_bank_account, required: true}, {name: metadata, var: metadata}, {name: name, var: name}, {name: nominalCode, var: nominal_code}, {name: status, var: status}, {name: type, var: type}, {name: validDatatypeLinks, var: valid_datatype_links}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, currency: $currency, current_balance: $current_balance, description: $description, fully_qualified_category: $fully_qualified_category, fully_qualified_name: $fully_qualified_name, id: $id, is_bank_account: $is_bank_account, metadata: $metadata, name: $name, nominal_code: $nominal_code, status: $status, type: $type, valid_datatype_links: $valid_datatype_links, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bank account
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts
# Returns: record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-bank-account
export def "create-bank-account" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account. Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated. FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account. For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities. For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account. The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account. Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/bankAccounts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: allowSyncOnPushComplete, var: allow_sync_on_push_complete}, {name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: accountType, var: account_type}, {name: availableBalance, var: available_balance}, {name: balance, var: balance}, {name: currency, var: currency}, {name: iBan, var: i_ban}, {name: id, var: id}, {name: institution, var: institution}, {name: metadata, var: metadata}, {name: nominalCode, var: nominal_code}, {name: overdraftLimit, var: overdraft_limit}, {name: sortCode, var: sort_code}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, allow_sync_on_push_complete: $allow_sync_on_push_complete, timeout_in_minutes: $timeout_in_minutes, account_name: $account_name, account_number: $account_number, account_type: $account_type, available_balance: $available_balance, balance: $balance, currency: $currency, i_ban: $i_ban, id: $id, institution: $institution, metadata: $metadata, nominal_code: $nominal_code, overdraft_limit: $overdraft_limit, sort_code: $sort_code, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bank transactions
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{accountId}/bankTransactions
# Returns: record<data: record<accountId: string, transactions: list<record>>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-bank-transactions
export def "create-bank-transactions" [
  company_id: string
  connection_id: string
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
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --body-account-id: string # nullable (spec name: accountId)
  --transactions: list # nullable — item shape: {amount: float, balance: float, clearedOnDate?: string, counterparty?: string, description?: string, id?: string, reconciled: bool, reference?: string, transactionType: "Unknown"|"Credit"|"Debit"|"Int"|"Div"|"Fee"|"SerChg"|"Dep"|"Atm"|"Pos"|"Xfer"|"Check"|"Payment"|"Cash"|"DirectDep"|"DirectDebit"|"RepeatPmt"|"Other", modifiedDate?: string, sourceModifiedDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/bankAccounts/{accountId}/bankTransactions"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: accountId, var: account_id}]
    query: [{name: allowSyncOnPushComplete, var: allow_sync_on_push_complete}, {name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: transactions, var: transactions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, account_id: $account_id, allow_sync_on_push_complete: $allow_sync_on_push_complete, timeout_in_minutes: $timeout_in_minutes, body_account_id: $body_account_id, transactions: $transactions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update bank account
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{bankAccountId}
# Returns: record<data: record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-bank-account
export def "update-bank-account" [
  company_id: string
  connection_id: string
  bank_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account. Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated. FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account. For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities. For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account. The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account. Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/bankAccounts/{bankAccountId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: bankAccountId, var: bank_account_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: accountNumber, var: account_number}, {name: accountType, var: account_type}, {name: availableBalance, var: available_balance}, {name: balance, var: balance}, {name: currency, var: currency}, {name: iBan, var: i_ban}, {name: id, var: id}, {name: institution, var: institution}, {name: metadata, var: metadata}, {name: nominalCode, var: nominal_code}, {name: overdraftLimit, var: overdraft_limit}, {name: sortCode, var: sort_code}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bank_account_id: $bank_account_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, account_name: $account_name, account_number: $account_number, account_type: $account_type, available_balance: $available_balance, balance: $balance, currency: $currency, i_ban: $i_ban, id: $id, institution: $institution, metadata: $metadata, nominal_code: $nominal_code, overdraft_limit: $overdraft_limit, sort_code: $sort_code, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bill credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/billCreditNotes
# Returns: record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-bill-credit-note
export def "create-bill-credit-note" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: string@status-completer-1 # Current state of the bill credit note
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/billCreditNotes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: allocatedOnDate, var: allocated_on_date}, {name: billCreditNoteNumber, var: bill_credit_note_number}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: discountPercentage, var: discount_percentage}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: remainingCredit, var: remaining_credit}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: supplierRef, var: supplier_ref}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, allocated_on_date: $allocated_on_date, bill_credit_note_number: $bill_credit_note_number, currency: $currency, currency_rate: $currency_rate, discount_percentage: $discount_percentage, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, remaining_credit: $remaining_credit, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, supplier_ref: $supplier_ref, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update bill credit note
#
# PUT /companies/{companyId}/connections/{connectionId}/push/billCreditNotes/{billCreditNoteId}
# Returns: record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-bill-credit-note
export def "update-bill-credit-note" [
  company_id: string
  connection_id: string
  bill_credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: string@status-completer-1 # Current state of the bill credit note
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/billCreditNotes/{billCreditNoteId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billCreditNoteId, var: bill_credit_note_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: allocatedOnDate, var: allocated_on_date}, {name: billCreditNoteNumber, var: bill_credit_note_number}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: discountPercentage, var: discount_percentage}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: remainingCredit, var: remaining_credit}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: supplierRef, var: supplier_ref}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_credit_note_id: $bill_credit_note_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, allocated_on_date: $allocated_on_date, bill_credit_note_number: $bill_credit_note_number, currency: $currency, currency_rate: $currency_rate, discount_percentage: $discount_percentage, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, remaining_credit: $remaining_credit, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, supplier_ref: $supplier_ref, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bill payments
#
# POST /companies/{companyId}/connections/{connectionId}/push/billPayments
# Returns: record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-bill-payment
export def "create-bill-payment" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --account-ref: record # Data types that reference an account, for example bill and invoice line items, use an accountRef that includes the ID and name of the linked account. — shape: {id?: string, name?: string}
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the bill payment, unique for the company in the accounting platform.
  --lines: list # An array of bill payment lines. (nullable) — item shape: {allocatedOnDate?: string, amount: float, links?: list}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Additional information associated with the payment. (nullable)
  --payment-method-ref: record # shape: {id?: string, name?: string}
  --reference: string # Additional information associated with the payment. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Amount of the payment in the payment currency. This value never changes and represents the amount of money that is paid into the supplier's account.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/billPayments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountRef, var: account_ref}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: date, var: date}, {name: id, var: id}, {name: lines, var: lines}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentMethodRef, var: payment_method_ref}, {name: reference, var: reference}, {name: supplementalData, var: supplemental_data}, {name: supplierRef, var: supplier_ref}, {name: totalAmount, var: total_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, account_ref: $account_ref, currency: $currency, currency_rate: $currency_rate, date: $date, id: $id, lines: $lines, metadata: $metadata, note: $note, payment_method_ref: $payment_method_ref, reference: $reference, supplemental_data: $supplemental_data, supplier_ref: $supplier_ref, total_amount: $total_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete bill payment
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/billPayments/{billPaymentId}
# Returns: record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: delete-billPayment
export def "delete-bill-payment" [
  company_id: string
  connection_id: string
  bill_payment_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/push/billPayments/{billPaymentId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billPaymentId, var: bill_payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_payment_id: $bill_payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bill
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills
# Returns: record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-bill
export def "create-bill" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: string # Date the supplier is due to be paid.
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: string # Date of the bill as recorded in the accounting platform.
  --line-items: list # Array of Bill line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --purchase-order-refs: list # nullable — item shape: {id?: string, purchaseOrderNumber?: string}
  --reference: string # User-friendly reference for the bill. (nullable)
  status: string@status-completer-2 # Current state of the bill.
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/bills"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: amountDue, var: amount_due}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: dueDate, var: due_date}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: purchaseOrderRefs, var: purchase_order_refs}, {name: reference, var: reference}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: supplierRef, var: supplier_ref}, {name: taxAmount, var: tax_amount}, {name: totalAmount, var: total_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, amount_due: $amount_due, currency: $currency, currency_rate: $currency_rate, due_date: $due_date, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, purchase_order_refs: $purchase_order_refs, reference: $reference, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, supplier_ref: $supplier_ref, tax_amount: $tax_amount, total_amount: $total_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete bill
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# Returns: record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: delete-bill
export def "delete-bill" [
  company_id: string
  connection_id: string
  bill_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/push/bills/{billId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update bill
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# Returns: record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-bill
export def "update-bill" [
  company_id: string
  connection_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: string # Date the supplier is due to be paid.
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: string # Date of the bill as recorded in the accounting platform.
  --line-items: list # Array of Bill line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --purchase-order-refs: list # nullable — item shape: {id?: string, purchaseOrderNumber?: string}
  --reference: string # User-friendly reference for the bill. (nullable)
  status: string@status-completer-2 # Current state of the bill.
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/bills/{billId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: amountDue, var: amount_due}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: dueDate, var: due_date}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: purchaseOrderRefs, var: purchase_order_refs}, {name: reference, var: reference}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: supplierRef, var: supplier_ref}, {name: taxAmount, var: tax_amount}, {name: totalAmount, var: total_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, amount_due: $amount_due, currency: $currency, currency_rate: $currency_rate, due_date: $due_date, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, purchase_order_refs: $purchase_order_refs, reference: $reference, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, supplier_ref: $supplier_ref, tax_amount: $tax_amount, total_amount: $total_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload bill attachments
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills/{billId}/attachments
# operationId: upload-bill-attachments
export def "upload-bill-attachments" [
  company_id: string
  connection_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/bills/{billId}/attachments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: billId, var: bill_id}]
    body: {content_type: "multipart/form-data", kind: multipart}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/creditNotes
# Returns: record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-credit-note
export def "create-credit-note" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: string@status-completer-1
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/creditNotes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalTaxAmount, var: additional_tax_amount}, {name: additionalTaxPercentage, var: additional_tax_percentage}, {name: allocatedOnDate, var: allocated_on_date}, {name: creditNoteNumber, var: credit_note_number}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: customerRef, var: customer_ref}, {name: discountPercentage, var: discount_percentage}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: remainingCredit, var: remaining_credit}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, additional_tax_amount: $additional_tax_amount, additional_tax_percentage: $additional_tax_percentage, allocated_on_date: $allocated_on_date, credit_note_number: $credit_note_number, currency: $currency, currency_rate: $currency_rate, customer_ref: $customer_ref, discount_percentage: $discount_percentage, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, remaining_credit: $remaining_credit, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update creditNote
#
# PUT /companies/{companyId}/connections/{connectionId}/push/creditNotes/{creditNoteId}
# Returns: record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-credit-note
export def "update-credit-note" [
  company_id: string
  connection_id: string
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
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: string@status-completer-1
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/creditNotes/{creditNoteId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: creditNoteId, var: credit_note_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalTaxAmount, var: additional_tax_amount}, {name: additionalTaxPercentage, var: additional_tax_percentage}, {name: allocatedOnDate, var: allocated_on_date}, {name: creditNoteNumber, var: credit_note_number}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: customerRef, var: customer_ref}, {name: discountPercentage, var: discount_percentage}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: remainingCredit, var: remaining_credit}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, credit_note_id: $credit_note_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, additional_tax_amount: $additional_tax_amount, additional_tax_percentage: $additional_tax_percentage, allocated_on_date: $allocated_on_date, credit_note_number: $credit_note_number, currency: $currency, currency_rate: $currency_rate, customer_ref: $customer_ref, discount_percentage: $discount_percentage, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, remaining_credit: $remaining_credit, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create customer
#
# POST /companies/{companyId}/connections/{connectionId}/push/customers
# Returns: record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-customer
export def "create-customer" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable) — item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: string@status-completer-3 # Status of customer.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --tax-number: string # Company tax number. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/customers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: contactName, var: contact_name}, {name: contacts, var: contacts}, {name: customerName, var: customer_name}, {name: defaultCurrency, var: default_currency}, {name: emailAddress, var: email_address}, {name: id, var: id}, {name: metadata, var: metadata}, {name: phone, var: phone}, {name: registrationNumber, var: registration_number}, {name: status, var: status}, {name: supplementalData, var: supplemental_data}, {name: taxNumber, var: tax_number}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, addresses: $addresses, contact_name: $contact_name, contacts: $contacts, customer_name: $customer_name, default_currency: $default_currency, email_address: $email_address, id: $id, metadata: $metadata, phone: $phone, registration_number: $registration_number, status: $status, supplemental_data: $supplemental_data, tax_number: $tax_number, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update customer
#
# PUT /companies/{companyId}/connections/{connectionId}/push/customers/{customerId}
# Returns: record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-customer
export def "update-customer" [
  company_id: string
  connection_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable) — item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: string@status-completer-3 # Status of customer.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --tax-number: string # Company tax number. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/customers/{customerId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: customerId, var: customer_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: contactName, var: contact_name}, {name: contacts, var: contacts}, {name: customerName, var: customer_name}, {name: defaultCurrency, var: default_currency}, {name: emailAddress, var: email_address}, {name: id, var: id}, {name: metadata, var: metadata}, {name: phone, var: phone}, {name: registrationNumber, var: registration_number}, {name: status, var: status}, {name: supplementalData, var: supplemental_data}, {name: taxNumber, var: tax_number}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, addresses: $addresses, contact_name: $contact_name, contacts: $contacts, customer_name: $customer_name, default_currency: $default_currency, email_address: $email_address, id: $id, metadata: $metadata, phone: $phone, registration_number: $registration_number, status: $status, supplemental_data: $supplemental_data, tax_number: $tax_number, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create direct cost
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts
# Returns: record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-direct-cost
export def "create-direct-cost" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --id: string # Identifier of the direct cost, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items. — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # A note attached to the direct cost. (nullable)
  payment_allocations: list # An array of payment allocations. — item shape: {allocation: record, payment: record}
  --reference: string # User-friendly reference for the direct cost. (nullable)
  sub_total: float # The total amount of the direct costs, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  tax_amount: float # The total amount of tax on the direct costs.
  total_amount: float # The amount of the direct costs, inclusive of tax.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/directCosts"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactRef, var: contact_ref}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: reference, var: reference}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: taxAmount, var: tax_amount}, {name: totalAmount, var: total_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, contact_ref: $contact_ref, currency: $currency, currency_rate: $currency_rate, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, reference: $reference, sub_total: $sub_total, supplemental_data: $supplemental_data, tax_amount: $tax_amount, total_amount: $total_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload direct cost attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts/{directCostId}/attachment
# operationId: upload-direct-cost-attachment
export def "upload-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/directCosts/{directCostId}/attachment"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directCostId, var: direct_cost_id}]
    body: {content_type: "multipart/form-data", kind: multipart}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create direct income
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes
# Returns: record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-direct-income
export def "create-direct-income" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --id: string # Identifier of the direct income, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items. — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # nullable
  payment_allocations: list # item shape: {allocation: record, payment: record}
  --reference: string # User-friendly reference for the direct income. (nullable)
  sub_total: float # The total amount of the direct incomes, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  tax_amount: float # The total amount of tax on the direct incomes.
  total_amount: float # The amount of the direct incomes, inclusive of tax.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/directIncomes"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactRef, var: contact_ref}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentAllocations, var: payment_allocations}, {name: reference, var: reference}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: taxAmount, var: tax_amount}, {name: totalAmount, var: total_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, contact_ref: $contact_ref, currency: $currency, currency_rate: $currency_rate, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_allocations: $payment_allocations, reference: $reference, sub_total: $sub_total, supplemental_data: $supplemental_data, tax_amount: $tax_amount, total_amount: $total_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create direct income attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes/{directIncomeId}/attachment
# operationId: upload-direct-income-attachment
export def "upload-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/directIncomes/{directIncomeId}/attachment"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: directIncomeId, var: direct_income_id}]
    body: {content_type: "multipart/form-data", kind: multipart}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create invoice
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices
# Returns: record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-invoice
export def "create-invoice" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --sales-order-refs: list<string> # List of references to related Sales orders. (nullable)
  status: string@status-completer-1 # Current state of the invoice: - `Draft` - Invoice hasn't been submitted to the supplier. It may be in a pending state or is scheduled for future submission, for example by email. - `Submitted` - Invoice is no longer a draft. It has been processed and, or, sent to the customer. In this state, it will impact the ledger. It also has no payments made against it (amountDue == totalAmount). - `PartiallyPaid` - The balance paid against the invoice is positive, but less than the total invoice amount (0 < amountDue < totalAmount). - `Paid` - Invoice is paid in full. This includes if the invoice has been credited or overpaid (amountDue == 0). - `Void` - An invoice can become Void when it's deleted, refunded, written off, or cancelled. A voided invoice may still be PartiallyPaid, and so all outstanding amounts on voided invoices are removed from the accounts receivable account.
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/invoices"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalTaxAmount, var: additional_tax_amount}, {name: additionalTaxPercentage, var: additional_tax_percentage}, {name: amountDue, var: amount_due}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: customerRef, var: customer_ref}, {name: discountPercentage, var: discount_percentage}, {name: dueDate, var: due_date}, {name: id, var: id}, {name: invoiceNumber, var: invoice_number}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paidOnDate, var: paid_on_date}, {name: paymentAllocations, var: payment_allocations}, {name: salesOrderRefs, var: sales_order_refs}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, additional_tax_amount: $additional_tax_amount, additional_tax_percentage: $additional_tax_percentage, amount_due: $amount_due, currency: $currency, currency_rate: $currency_rate, customer_ref: $customer_ref, discount_percentage: $discount_percentage, due_date: $due_date, id: $id, invoice_number: $invoice_number, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, paid_on_date: $paid_on_date, payment_allocations: $payment_allocations, sales_order_refs: $sales_order_refs, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete invoice
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# Returns: record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: delete-invoice
export def "delete-invoice" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update invoice
#
# PUT /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# Returns: record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-invoice
export def "update-invoice" [
  company_id: string
  connection_id: string
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
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --sales-order-refs: list<string> # List of references to related Sales orders. (nullable)
  status: string@status-completer-1 # Current state of the invoice: - `Draft` - Invoice hasn't been submitted to the supplier. It may be in a pending state or is scheduled for future submission, for example by email. - `Submitted` - Invoice is no longer a draft. It has been processed and, or, sent to the customer. In this state, it will impact the ledger. It also has no payments made against it (amountDue == totalAmount). - `PartiallyPaid` - The balance paid against the invoice is positive, but less than the total invoice amount (0 < amountDue < totalAmount). - `Paid` - Invoice is paid in full. This includes if the invoice has been credited or overpaid (amountDue == 0). - `Void` - An invoice can become Void when it's deleted, refunded, written off, or cancelled. A voided invoice may still be PartiallyPaid, and so all outstanding amounts on voided invoices are removed from the accounts receivable account.
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalTaxAmount, var: additional_tax_amount}, {name: additionalTaxPercentage, var: additional_tax_percentage}, {name: amountDue, var: amount_due}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: customerRef, var: customer_ref}, {name: discountPercentage, var: discount_percentage}, {name: dueDate, var: due_date}, {name: id, var: id}, {name: invoiceNumber, var: invoice_number}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paidOnDate, var: paid_on_date}, {name: paymentAllocations, var: payment_allocations}, {name: salesOrderRefs, var: sales_order_refs}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplementalData, var: supplemental_data}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: withholdingTax, var: withholding_tax}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, additional_tax_amount: $additional_tax_amount, additional_tax_percentage: $additional_tax_percentage, amount_due: $amount_due, currency: $currency, currency_rate: $currency_rate, customer_ref: $customer_ref, discount_percentage: $discount_percentage, due_date: $due_date, id: $id, invoice_number: $invoice_number, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, paid_on_date: $paid_on_date, payment_allocations: $payment_allocations, sales_order_refs: $sales_order_refs, status: $status, sub_total: $sub_total, supplemental_data: $supplemental_data, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, withholding_tax: $withholding_tax, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push invoice attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}/attachment
# operationId: upload-invoice-attachment
export def "upload-invoice-attachment" [
  company_id: string
  connection_id: string
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
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}/attachment"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: invoiceId, var: invoice_id}]
    body: {content_type: "multipart/form-data", kind: multipart}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create item
#
# POST /companies/{companyId}/connections/{connectionId}/push/items
# Returns: record<data: record<billItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-item
export def "create-item" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --bill-item: record # Item details that are only for bills. — shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
  --code: string # Friendly reference for the item. (nullable)
  --id: string # Identifier for the item that is unique to a company in the accounting platform.
  --invoice-item: record # Item details that are only for bills. — shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
  --is-bill-item: oneof<nothing, bool> # Whether you can use this item for bills.
  --is-invoice-item: oneof<nothing, bool> # Whether you can use this item for invoices.
  item_status: string@item-status-completer # Current state of the item, either: - `Active`: Available for use - `Archived`: Unavailable - `Unknown` Due to a [limitation in Xero's API](https://docs.codat.io/integrations/accounting/xero/xero-faq#why-do-all-of-my-items-from-xero-have-their-status-as-unknown), all items from Xero are mapped as `Unknown`.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the item in the accounting platform. (nullable)
  type: any
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/items"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: billItem, var: bill_item}, {name: code, var: code}, {name: id, var: id}, {name: invoiceItem, var: invoice_item}, {name: isBillItem, var: is_bill_item, required: true}, {name: isInvoiceItem, var: is_invoice_item, required: true}, {name: itemStatus, var: item_status}, {name: metadata, var: metadata}, {name: name, var: name}, {name: type, var: type}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, bill_item: $bill_item, code: $code, id: $id, invoice_item: $invoice_item, is_bill_item: $is_bill_item, is_invoice_item: $is_invoice_item, item_status: $item_status, metadata: $metadata, name: $name, type: $type, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create journal entry
#
# POST /companies/{companyId}/connections/{connectionId}/push/journalEntries
# Returns: record<data: record<createdOn: string, description: string, id: string, journalLines: list<record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-journal-entry
export def "create-journal-entry" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --description: string # Optional description of the journal entry. (nullable)
  --id: string # Unique identifier of the journal entry for the company in the accounting platform.
  --journal-lines: list # An array of journal lines. (nullable) — item shape: {accountRef?: record, currency?: string, description?: string, netAmount: float, tracking?: record}
  --journal-ref: record # Links journal entries to the relevant journal in accounting integrations that use multi-book accounting (multiple journals). — shape: {id: string, name?: string}
  --metadata: record # shape: {isDeleted?: bool}
  --posted-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --record-ref: record # Links to the underlying record or data type. Found on: - Journal entries - Account transactions - Invoices - Transfers — shape: {dataType?: string, id?: string}
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --updated-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/journalEntries"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdOn, var: created_on}, {name: description, var: description}, {name: id, var: id}, {name: journalLines, var: journal_lines}, {name: journalRef, var: journal_ref}, {name: metadata, var: metadata}, {name: postedOn, var: posted_on}, {name: recordRef, var: record_ref}, {name: supplementalData, var: supplemental_data}, {name: updatedOn, var: updated_on}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, created_on: $created_on, description: $description, id: $id, journal_lines: $journal_lines, journal_ref: $journal_ref, metadata: $metadata, posted_on: $posted_on, record_ref: $record_ref, supplemental_data: $supplemental_data, updated_on: $updated_on, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete journal entry
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/journalEntries/{journalEntryId}
# Returns: record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: delete-journal-entry
export def "delete-journal-entry" [
  company_id: string
  connection_id: string
  journal_entry_id: string
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
    path: "/companies/{companyId}/connections/{connectionId}/push/journalEntries/{journalEntryId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: journalEntryId, var: journal_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, journal_entry_id: $journal_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create journal
#
# POST /companies/{companyId}/connections/{connectionId}/push/journals
# Returns: record<data: record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: push-journal
export def "push-journal" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --has-children: oneof<nothing, bool> # If the journal has child journals, this value is true. If it doesn’t, it is false.
  --id: string # Journal ID.
  --journal-code: string # Native journal number or code. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Journal name. The maximum length for a journal name is 256 characters. All characters above that number will be truncated. (nullable)
  --parent-id: string # Parent journal ID. If the journal is a parent journal, this value is not present. (nullable)
  --status: string@status-completer-3 # Current journal status.
  --type: string # The type of the journal. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/journals"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: createdOn, var: created_on}, {name: hasChildren, var: has_children}, {name: id, var: id}, {name: journalCode, var: journal_code}, {name: metadata, var: metadata}, {name: name, var: name}, {name: parentId, var: parent_id}, {name: status, var: status}, {name: type, var: type}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, created_on: $created_on, has_children: $has_children, id: $id, journal_code: $journal_code, metadata: $metadata, name: $name, parent_id: $parent_id, status: $status, type: $type, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create payment
#
# POST /companies/{companyId}/connections/{connectionId}/push/payments
# Returns: record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-payment
export def "create-payment" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --account-ref: record # Data types that reference an account, for example bill and invoice line items, use an accountRef that includes the ID and name of the linked account. — shape: {id?: string, name?: string}
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the payment, unique to the company in the accounting platform.
  --lines: list # An array of payment lines. (nullable) — item shape: {allocatedOnDate?: string, amount: float, links?: list}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the payment. (nullable)
  --payment-method-ref: record # shape: {id?: string, name?: string}
  --reference: string # Friendly reference for the payment. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --total-amount: float # Amount of the payment in the payment currency. This value should never change and represents the amount of money paid into the customer's account.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/payments"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountRef, var: account_ref}, {name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: customerRef, var: customer_ref}, {name: date, var: date}, {name: id, var: id}, {name: lines, var: lines}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentMethodRef, var: payment_method_ref}, {name: reference, var: reference}, {name: supplementalData, var: supplemental_data}, {name: totalAmount, var: total_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, account_ref: $account_ref, currency: $currency, currency_rate: $currency_rate, customer_ref: $customer_ref, date: $date, id: $id, lines: $lines, metadata: $metadata, note: $note, payment_method_ref: $payment_method_ref, reference: $reference, supplemental_data: $supplemental_data, total_amount: $total_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create purchase order
#
# POST /companies/{companyId}/connections/{connectionId}/push/purchaseOrders
# Returns: record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-purchase-order
export def "create-purchase-order" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: record # Delivery details for any goods that have been ordered. — shape: {address?: record, contact?: record}
  --status: string@status-completer-4 # Current state of the purchase order
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # Total amount of tax included in the purchase order.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/purchaseOrders"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: deliveryDate, var: delivery_date}, {name: expectedDeliveryDate, var: expected_delivery_date}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentDueDate, var: payment_due_date}, {name: purchaseOrderNumber, var: purchase_order_number}, {name: shipTo, var: ship_to}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplierRef, var: supplier_ref}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, currency: $currency, currency_rate: $currency_rate, delivery_date: $delivery_date, expected_delivery_date: $expected_delivery_date, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_due_date: $payment_due_date, purchase_order_number: $purchase_order_number, ship_to: $ship_to, status: $status, sub_total: $sub_total, supplier_ref: $supplier_ref, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update purchase order
#
# PUT /companies/{companyId}/connections/{connectionId}/push/purchaseOrders/{purchaseOrderId}
# Returns: record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: update-purchase-order
export def "update-purchase-order" [
  company_id: string
  connection_id: string
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
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: record # Delivery details for any goods that have been ordered. — shape: {address?: record, contact?: record}
  --status: string@status-completer-4 # Current state of the purchase order
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # Total amount of tax included in the purchase order.
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/purchaseOrders/{purchaseOrderId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: purchaseOrderId, var: purchase_order_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: currencyRate, var: currency_rate}, {name: deliveryDate, var: delivery_date}, {name: expectedDeliveryDate, var: expected_delivery_date}, {name: id, var: id}, {name: issueDate, var: issue_date}, {name: lineItems, var: line_items}, {name: metadata, var: metadata}, {name: note, var: note}, {name: paymentDueDate, var: payment_due_date}, {name: purchaseOrderNumber, var: purchase_order_number}, {name: shipTo, var: ship_to}, {name: status, var: status}, {name: subTotal, var: sub_total}, {name: supplierRef, var: supplier_ref}, {name: totalAmount, var: total_amount}, {name: totalDiscount, var: total_discount}, {name: totalTaxAmount, var: total_tax_amount}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, purchase_order_id: $purchase_order_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, currency: $currency, currency_rate: $currency_rate, delivery_date: $delivery_date, expected_delivery_date: $expected_delivery_date, id: $id, issue_date: $issue_date, line_items: $line_items, metadata: $metadata, note: $note, payment_due_date: $payment_due_date, purchase_order_number: $purchase_order_number, ship_to: $ship_to, status: $status, sub_total: $sub_total, supplier_ref: $supplier_ref, total_amount: $total_amount, total_discount: $total_discount, total_tax_amount: $total_tax_amount, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create suppliers
#
# POST /companies/{companyId}/connections/{connectionId}/push/suppliers
# Returns: record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-supplier
export def "create-supplier" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: string@status-completer-3 # Status of the supplier.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/suppliers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: contactName, var: contact_name}, {name: defaultCurrency, var: default_currency}, {name: emailAddress, var: email_address}, {name: id, var: id}, {name: metadata, var: metadata}, {name: phone, var: phone}, {name: registrationNumber, var: registration_number}, {name: status, var: status}, {name: supplementalData, var: supplemental_data}, {name: supplierName, var: supplier_name}, {name: taxNumber, var: tax_number}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, timeout_in_minutes: $timeout_in_minutes, addresses: $addresses, contact_name: $contact_name, default_currency: $default_currency, email_address: $email_address, id: $id, metadata: $metadata, phone: $phone, registration_number: $registration_number, status: $status, supplemental_data: $supplemental_data, supplier_name: $supplier_name, tax_number: $tax_number, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update supplier
#
# PUT /companies/{companyId}/connections/{connectionId}/push/suppliers/{supplierId}
# Returns: record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: put-supplier
export def "put-supplier" [
  company_id: string
  connection_id: string
  supplier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: string@status-completer-3 # Status of the supplier.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies/{companyId}/connections/{connectionId}/push/suppliers/{supplierId}"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}, {name: supplierId, var: supplier_id}]
    query: [{name: timeoutInMinutes, var: timeout_in_minutes}, {name: forceUpdate, var: force_update}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: contactName, var: contact_name}, {name: defaultCurrency, var: default_currency}, {name: emailAddress, var: email_address}, {name: id, var: id}, {name: metadata, var: metadata}, {name: phone, var: phone}, {name: registrationNumber, var: registration_number}, {name: status, var: status}, {name: supplementalData, var: supplemental_data}, {name: supplierName, var: supplier_name}, {name: taxNumber, var: tax_number}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id, timeout_in_minutes: $timeout_in_minutes, force_update: $force_update, addresses: $addresses, contact_name: $contact_name, default_currency: $default_currency, email_address: $email_address, id: $id, metadata: $metadata, phone: $phone, registration_number: $registration_number, status: $status, supplemental_data: $supplemental_data, supplier_name: $supplier_name, tax_number: $tax_number, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create transfer
#
# POST /companies/{companyId}/connections/{connectionId}/push/transfers
# Returns: record<data: record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record, amount: float, currency: string>, trackingCategoryRefs: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>
# operationId: create-transfer
export def "create-transfer" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  --date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --deposited-record-refs: list<string> # nullable
  --description: string # Description of the transfer. (nullable)
  --from: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --id: string # Unique identifier for the transfer.
  --metadata: record # shape: {isDeleted?: bool}
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --to: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --tracking-category-refs: list # Reference to the tracking categories this transfer is being tracked against. (nullable) — item shape: {id: string, name?: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{companyId}/connections/{connectionId}/push/transfers"
    path_params: [{name: companyId, var: company_id}, {name: connectionId, var: connection_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactRef, var: contact_ref}, {name: date, var: date}, {name: depositedRecordRefs, var: deposited_record_refs}, {name: description, var: description}, {name: from, var: from}, {name: id, var: id}, {name: metadata, var: metadata}, {name: supplementalData, var: supplemental_data}, {name: to, var: to}, {name: trackingCategoryRefs, var: tracking_category_refs}, {name: modifiedDate, var: modified_date}, {name: sourceModifiedDate, var: source_modified_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, connection_id: $connection_id, contact_ref: $contact_ref, date: $date, deposited_record_refs: $deposited_record_refs, description: $description, from: $from, id: $id, metadata: $metadata, supplemental_data: $supplemental_data, to: $to, tracking_category_refs: $tracking_category_refs, modified_date: $modified_date, source_modified_date: $source_modified_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts
#
# GET /companies/{companyId}/data/accounts
# Returns: record<results: table<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-accounts
export def "list-accounts" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/accounts"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account
#
# GET /companies/{companyId}/data/accounts/{accountId}
# DEPRECATED
# Returns: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-account
@deprecated
export def "get-account" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/accounts/{accountId}"
    path_params: [{name: companyId, var: company_id}, {name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bank account
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}
# DEPRECATED
# Returns: record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: record<modifiedDate: string>, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: record<sourceModifiedDate: string>, toDate: string>
# operationId: get-all-bank-account
@deprecated
export def "get-all-bank-account" [
  company_id: string
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
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/bankAccounts/{accountId}"
    path_params: [{name: companyId, var: company_id}, {name: accountId, var: account_id}]
    query: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, account_id: $account_id, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all bank transactions
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}/transactions
# Returns: record<results: table<amount: float, balance: float, clearedOnDate: string, counterparty: string, description: string, id: string, reconciled: bool, reference: string, transactionType: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bank-transactions
export def "list-bank-transactions" [
  company_id: string
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/bankAccounts/{accountId}/transactions"
    path_params: [{name: companyId, var: company_id}, {name: accountId, var: account_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, account_id: $account_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bill credit notes
#
# GET /companies/{companyId}/data/billCreditNotes
# Returns: record<results: table<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bill-credit-notes
export def "list-bill-credit-notes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/billCreditNotes"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bill credit note
#
# GET /companies/{companyId}/data/billCreditNotes/{billCreditNoteId}
# DEPRECATED
# Returns: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-bill-credit-note
@deprecated
export def "get-bill-credit-note" [
  company_id: string
  bill_credit_note_id: string
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
    path: "/companies/{companyId}/data/billCreditNotes/{billCreditNoteId}"
    path_params: [{name: companyId, var: company_id}, {name: billCreditNoteId, var: bill_credit_note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, bill_credit_note_id: $bill_credit_note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bill payments
#
# GET /companies/{companyId}/data/billPayments
# Returns: record<results: table<accountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, paymentMethodRef: record, reference: string, supplementalData: record, supplierRef: record, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bill-payments
export def "list-bill-payments" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/billPayments"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bill payment
#
# GET /companies/{companyId}/data/billPayments/{billPaymentId}
# DEPRECATED
# Returns: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-bill-payments
@deprecated
export def "get-bill-payments" [
  company_id: string
  bill_payment_id: string
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
    path: "/companies/{companyId}/data/billPayments/{billPaymentId}"
    path_params: [{name: companyId, var: company_id}, {name: billPaymentId, var: bill_payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, bill_payment_id: $bill_payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bills
#
# GET /companies/{companyId}/data/bills
# Returns: record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-bills
export def "list-bills" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/bills"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bill
#
# GET /companies/{companyId}/data/bills/{billId}
# Returns: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectCost: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, purchaseOrderRefs: table<id: string, purchaseOrderNumber: string>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-bill
export def "get-bill" [
  company_id: string
  bill_id: string
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
    path: "/companies/{companyId}/data/bills/{billId}"
    path_params: [{name: companyId, var: company_id}, {name: billId, var: bill_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, bill_id: $bill_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List credit notes
#
# GET /companies/{companyId}/data/creditNotes
# Returns: record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-credit-notes
export def "list-credit-notes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/creditNotes"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get credit note
#
# GET /companies/{companyId}/data/creditNotes/{creditNoteId}
# DEPRECATED
# Returns: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-credit-note
@deprecated
export def "get-credit-note" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/creditNotes/{creditNoteId}"
    path_params: [{name: companyId, var: company_id}, {name: creditNoteId, var: credit_note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, credit_note_id: $credit_note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List customers
#
# GET /companies/{companyId}/data/customers
# Returns: record<results: table<addresses: list, contactName: string, contacts: list, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: get-customers
export def "get-customers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/customers"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get customer
#
# GET /companies/{companyId}/data/customers/{customerId}
# DEPRECATED
# Returns: record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, contacts: table<address: record, email: string, modifiedDate: string, name: string, phone: list, status: string>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-customer
@deprecated
export def "get-customer" [
  company_id: string
  customer_id: string
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
    path: "/companies/{companyId}/data/customers/{customerId}"
    path_params: [{name: companyId, var: company_id}, {name: customerId, var: customer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, customer_id: $customer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get balance sheet
#
# GET /companies/{companyId}/data/financials/balanceSheet
# Returns: record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: table<assets: record, date: string, equity: record, liabilities: record, netAssets: float>>
# operationId: get-balance-sheet
export def "get-balance-sheet" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/financials/balanceSheet"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: periodLength, var: period_length, required: true}, {name: periodsToCompare, var: periods_to_compare, required: true}, {name: startMonth, var: start_month}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, period_length: $period_length, periods_to_compare: $periods_to_compare, start_month: $start_month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cash flow statement
#
# GET /companies/{companyId}/data/financials/cashFlowStatement
# Returns: record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reportInput: string, reports: table<cashPayments: record, cashReceipts: record, fromDate: string, toDate: string>>
# operationId: get-cash-flow-statement
export def "get-cash-flow-statement" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/financials/cashFlowStatement"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: periodLength, var: period_length, required: true}, {name: periodsToCompare, var: periods_to_compare, required: true}, {name: startMonth, var: start_month}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, period_length: $period_length, periods_to_compare: $periods_to_compare, start_month: $start_month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profit and loss
#
# GET /companies/{companyId}/data/financials/profitAndLoss
# Returns: record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reports: table<costOfSales: record, expenses: record, fromDate: string, grossProfit: float, income: record, netOperatingProfit: float, netOtherIncome: float, netProfit: float, otherExpenses: record, otherIncome: record, toDate: string>>
# operationId: get-profit-and-loss
export def "get-profit-and-loss" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/financials/profitAndLoss"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: periodLength, var: period_length, required: true}, {name: periodsToCompare, var: periods_to_compare, required: true}, {name: startMonth, var: start_month}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, period_length: $period_length, periods_to_compare: $periods_to_compare, start_month: $start_month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get company info
#
# GET /companies/{companyId}/data/info
# Returns: record<accountingPlatformRef: string, addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, baseCurrency: string, companyLegalName: string, companyName: string, createdDate: string, financialYearStartDate: string, ledgerLockDate: string, phoneNumbers: table<number: string, type: string>, registrationNumber: string, sourceUrls: record, taxNumber: string, webLinks: table<type: string, url: string>>
# operationId: get-company-info
export def "get-company-info" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/info"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh company info
#
# POST /companies/{companyId}/data/info
# Returns: record<companyId: string, completed: string, connectionId: string, dataType: string, datasetLogsUrl: string, errorMessage: string, id: string, isCompleted: bool, isErrored: bool, progress: int, requested: string, status: string, validationInformationUrl: string>
# operationId: post-sync-info
export def "post-sync-info" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/companies/{companyId}/data/info"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List invoices
#
# GET /companies/{companyId}/data/invoices
# Returns: record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list, metadata: record, note: string, paidOnDate: string, paymentAllocations: list, salesOrderRefs: list, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-invoices
export def "list-invoices" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/invoices"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoice
#
# GET /companies/{companyId}/data/invoices/{invoiceId}
# DEPRECATED
# Returns: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: table<allocation: record, payment: record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-invoice
@deprecated
export def "get-invoice" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/invoices/{invoiceId}"
    path_params: [{name: companyId, var: company_id}, {name: invoiceId, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoice as PDF
#
# GET /companies/{companyId}/data/invoices/{invoiceId}/pdf
# operationId: Download-invoice-pdf
export def "download-invoice-pdf" [
  company_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/data/invoices/{invoiceId}/pdf"
    path_params: [{name: companyId, var: company_id}, {name: invoiceId, var: invoice_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List items
#
# GET /companies/{companyId}/data/items
# Returns: record<results: table<billItem: record, code: string, id: string, invoiceItem: record, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-items
export def "list-items" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/items"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get item
#
# GET /companies/{companyId}/data/items/{itemId}
# DEPRECATED
# Returns: record<billItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-item
@deprecated
export def "get-item" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/items/{itemId}"
    path_params: [{name: companyId, var: company_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List journal entries
#
# GET /companies/{companyId}/data/journalEntries
# Returns: record<results: table<createdOn: string, description: string, id: string, journalLines: list, journalRef: record, metadata: record, postedOn: string, recordRef: record, supplementalData: record, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-journal-entries
export def "list-journal-entries" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/journalEntries"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get journal entry
#
# GET /companies/{companyId}/data/journalEntries/{journalEntryId}
# DEPRECATED
# Returns: record<createdOn: string, description: string, id: string, journalLines: table<accountRef: record, currency: string, description: string, netAmount: float, tracking: record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-journal-entry
@deprecated
export def "get-journal-entry" [
  company_id: string
  journal_entry_id: string
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
    path: "/companies/{companyId}/data/journalEntries/{journalEntryId}"
    path_params: [{name: companyId, var: company_id}, {name: journalEntryId, var: journal_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, journal_entry_id: $journal_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List journals
#
# GET /companies/{companyId}/data/journals
# Returns: record<results: table<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-journals
export def "list-journals" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/journals"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get journal
#
# GET /companies/{companyId}/data/journals/{journalId}
# DEPRECATED
# Returns: record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-journal
@deprecated
export def "get-journal" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/journals/{journalId}"
    path_params: [{name: companyId, var: company_id}, {name: journalId, var: journal_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, journal_id: $journal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all payment methods
#
# GET /companies/{companyId}/data/paymentMethods
# DEPRECATED
# Returns: record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-payment-methods
@deprecated
export def "list-payment-methods" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/paymentMethods"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment method
#
# GET /companies/{companyId}/data/paymentMethods/{paymentMethodId}
# DEPRECATED
# Returns: record<id: string, metadata: record<isDeleted: bool>, name: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-payment-method
@deprecated
export def "get-payment-method" [
  company_id: string
  payment_method_id: string
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
    path: "/companies/{companyId}/data/paymentMethods/{paymentMethodId}"
    path_params: [{name: companyId, var: company_id}, {name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List payments
#
# GET /companies/{companyId}/data/payments
# Returns: record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-payments
export def "list-payments" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/payments"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment
#
# GET /companies/{companyId}/data/payments/{paymentId}
# DEPRECATED
# Returns: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-payment
@deprecated
export def "get-payment" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/payments/{paymentId}"
    path_params: [{name: companyId, var: company_id}, {name: paymentId, var: payment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, payment_id: $payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List purchase orders
#
# GET /companies/{companyId}/data/purchaseOrders
# Returns: record<results: table<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record, status: string, subTotal: float, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-purchase-orders
export def "list-purchase-orders" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/purchaseOrders"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get purchase order
#
# GET /companies/{companyId}/data/purchaseOrders/{purchaseOrderId}
# DEPRECATED
# Returns: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-purchase-order
@deprecated
export def "get-purchase-order" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/purchaseOrders/{purchaseOrderId}"
    path_params: [{name: companyId, var: company_id}, {name: purchaseOrderId, var: purchase_order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, purchase_order_id: $purchase_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sales orders
#
# GET /companies/{companyId}/data/salesOrders
# Returns: record<results: table<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: list, metadata: record, note: string, salesOrderNumber: string, shipTo: record, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-sales-orders
export def "list-sales-orders" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/salesOrders"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sales order
#
# GET /companies/{companyId}/data/salesOrders/{salesOrderId}
# DEPRECATED
# Returns: record<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record<companyName: string, id: string>, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, salesOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-sales-order
@deprecated
export def "get-sales-order" [
  company_id: string
  sales_order_id: string
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
    path: "/companies/{companyId}/data/salesOrders/{salesOrderId}"
    path_params: [{name: companyId, var: company_id}, {name: salesOrderId, var: sales_order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, sales_order_id: $sales_order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List suppliers
#
# GET /companies/{companyId}/data/suppliers
# Returns: record<results: table<addresses: list, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-suppliers
export def "list-suppliers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/suppliers"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get supplier
#
# GET /companies/{companyId}/data/suppliers/{supplierId}
# DEPRECATED
# Returns: record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-supplier
@deprecated
export def "get-supplier" [
  company_id: string
  supplier_id: string
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
    path: "/companies/{companyId}/data/suppliers/{supplierId}"
    path_params: [{name: companyId, var: company_id}, {name: supplierId, var: supplier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, supplier_id: $supplier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tax rates
#
# GET /companies/{companyId}/data/taxRates
# Returns: record<results: table<code: string, components: list, effectiveTaxRate: float, id: string, metadata: record, name: string, status: string, totalTaxRate: float, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-tax-rates
export def "list-tax-rates" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/taxRates"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tax rate
#
# GET /companies/{companyId}/data/taxRates/{taxRateId}
# DEPRECATED
# Returns: record<code: string, components: table<isCompound: bool, name: string, rate: float>, effectiveTaxRate: float, id: string, metadata: record<isDeleted: bool>, name: string, status: string, totalTaxRate: float, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-tax-rate
@deprecated
export def "get-tax-rate" [
  company_id: string
  tax_rate_id: string
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
    path: "/companies/{companyId}/data/taxRates/{taxRateId}"
    path_params: [{name: companyId, var: company_id}, {name: taxRateId, var: tax_rate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, tax_rate_id: $tax_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tracking categories
#
# GET /companies/{companyId}/data/trackingCategories
# Returns: record<results: table<hasChildren: bool, id: string, name: string, parentId: string, status: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>
# operationId: list-tracking-categories
export def "list-tracking-categories" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/trackingCategories"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: page, var: page, required: true, default: 1}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, page: $page, page_size: $page_size, query: $query, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tracking categories
#
# GET /companies/{companyId}/data/trackingCategories/{trackingCategoryId}
# DEPRECATED
# Returns: record<hasChildren: bool, id: string, name: string, parentId: string, status: string, subCategories: list<any>, modifiedDate: string, sourceModifiedDate: string>
# operationId: get-tracking-category
@deprecated
export def "get-tracking-category" [
  company_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/data/trackingCategories/{trackingCategoryId}"
    path_params: [{name: companyId, var: company_id}, {name: trackingCategoryId, var: tracking_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, tracking_category_id: $tracking_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aged creditors report
#
# GET /companies/{companyId}/reports/agedCreditor
# Returns: record<data: table<agedCurrencyOutstanding: list, supplierId: string, supplierName: string>, generated: string, reportDate: string>
# operationId: get-aged-creditors-report
export def "get-aged-creditors-report" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/agedCreditor"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportDate, var: report_date}, {name: numberOfPeriods, var: number_of_periods}, {name: periodLengthDays, var: period_length_days}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_date: $report_date, number_of_periods: $number_of_periods, period_length_days: $period_length_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aged creditors report available
#
# GET /companies/{companyId}/reports/agedCreditor/available
# Returns: bool
# operationId: is-aged-creditors-report-available
export def "is-aged-creditors-report-available" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/agedCreditor/available"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aged debtors report
#
# GET /companies/{companyId}/reports/agedDebtor
# Returns: record<data: table<agedCurrencyOutstanding: list, customerId: string, customerName: string>, generated: string, reportDate: string>
# operationId: get-aged-debtors-report
export def "get-aged-debtors-report" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/agedDebtor"
    path_params: [{name: companyId, var: company_id}]
    query: [{name: reportDate, var: report_date}, {name: numberOfPeriods, var: number_of_periods}, {name: periodLengthDays, var: period_length_days}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, report_date: $report_date, number_of_periods: $number_of_periods, period_length_days: $period_length_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aged debtors report available
#
# GET /companies/{companyId}/reports/agedDebtor/available
# Returns: bool
# operationId: is-aged-debtor-report-available
export def "is-aged-debtor-report-available" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/companies/{companyId}/reports/agedDebtor/available"
    path_params: [{name: companyId, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
