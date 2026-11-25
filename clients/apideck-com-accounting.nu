# Auto-generated client for Accounting API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/accounting/9.3.0/openapi.json
# Auth: --token flag or $env.ACCOUNTING_API_TOKEN

const CLIENT = {
  base_url: "https://unify.apideck.com"
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTC" "BTN" "BWP" "BYR" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "ETH" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LVL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRC" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "UNKNOWN_CURRENCY" "USD" "USN" "USS" "UYI" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XTS" "XXX" "YER" "ZAR" "ZMK" "ZMW"] }
def status-completer [] { ["authorised" "credit" "deleted" "draft" "paid" "partially_paid" "submitted" "void"] }
def status-completer-1 [] { ["authorised" "deleted" "draft" "paid" "voided"] }
def type-completer [] { ["accounts_payable_credit" "accounts_receivable_credit"] }
def status-completer-2 [] { ["active" "archived" "gdpr-erasure-request" "inactive" "unknown"] }
def type-completer-1 [] { ["inventory" "other" "service"] }
def type-completer-2 [] { ["credit" "other" "product" "service" "standard" "supplier"] }
def classification-completer [] { ["asset" "costs_of_sales" "equity" "expense" "income" "liability" "other_expense" "other_income" "revenue"] }
def status-completer-3 [] { ["active" "archived" "inactive"] }
def type-completer-3 [] { ["accounts_payable" "accounts_receivable" "balancesheet" "bank" "costs_of_sales" "credit_card" "current_asset" "current_liability" "equity" "expense" "fixed_asset" "non_current_asset" "non_current_liability" "other_asset" "other_expense" "other_income" "other_liability" "revenue" "sales"] }
def status-completer-4 [] { ["authorised" "deleted" "paid" "voided"] }
def type-completer-4 [] { ["accounts_payable" "accounts_payable_credit" "accounts_payable_overpayment" "accounts_payable_prepayment" "accounts_receivable" "accounts_receivable_credit" "accounts_receivable_overpayment" "accounts_receivable_prepayment"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    balance-sheet-one: "record<data: record<assets: record<current_assets: record, fixed_assets: record, total: float>, created_at: string, created_by: string, end_date: string, equity: record<items: list, total: float>, id: string, liabilities: record<accounts: list, total: float>, report_name: string, start_date: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    bills-all: "record<data: table<balance: float, bill_date: string, bill_number: string, created_at: string, created_by: string, currency: string, currency_rate: float, deposit: float, downstream_id: string, due_date: string, id: string, ledger_account: record, line_items: list, notes: string, paid_date: string, po_number: string, reference: string, row_version: string, status: string, sub_total: float, supplier: record, tax_code: string, tax_inclusive: bool, terms: string, total: float, total_tax: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    bills-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    bills-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    bills-one: "record<data: record<balance: float, bill_date: string, bill_number: string, created_at: string, created_by: string, currency: string, currency_rate: float, deposit: float, downstream_id: string, due_date: string, id: string, ledger_account: record<code: string, id: string, name: string, nominal_code: string>, line_items: list<record>, notes: string, paid_date: string, po_number: string, reference: string, row_version: string, status: string, sub_total: float, supplier: record<address: record, company_name: string, display_name: string, id: string>, tax_code: string, tax_inclusive: bool, terms: string, total: float, total_tax: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    bills-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    company-info-one: "record<data: record<addresses: list<record>, automated_sales_tax: bool, company_name: string, company_start_date: string, country: string, created_at: string, created_by: string, currency: string, default_sales_tax: record<code: string, id: string, name: string, rate: float>, emails: list<record>, fiscal_year_start_month: string, id: string, language: string, legal_name: string, phone_numbers: list<record>, row_version: string, sales_tax_enabled: bool, sales_tax_number: string, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    credit-notes-all: "record<data: table<account: record, allocations: list, balance: float, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, date_issued: string, date_paid: string, id: string, line_items: list, note: string, number: string, reference: string, remaining_credit: float, row_version: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, terms: string, total_amount: float, total_tax: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    credit-notes-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    credit-notes-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    credit-notes-one: "record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, allocations: list<record>, balance: float, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, date_issued: string, date_paid: string, id: string, line_items: list<record>, note: string, number: string, reference: string, remaining_credit: float, row_version: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, terms: string, total_amount: float, total_tax: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    credit-notes-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    customers-all: "record<data: table<account: record, addresses: list, bank_accounts: list, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, parent: record, phone_numbers: list, project: bool, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record, title: string, updated_at: string, updated_by: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    customers-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    customers-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    customers-one: "record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, addresses: list<record>, bank_accounts: list<record>, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list<record>, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, parent: record<id: string, name: string>, phone_numbers: list<record>, project: bool, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record<code: string, id: string, name: string, rate: float>, title: string, updated_at: string, updated_by: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    customers-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoice-items-all: "record<data: table<active: bool, asset_account: record, code: string, created_at: string, created_by: string, description: string, expense_account: record, id: string, income_account: record, inventory_date: string, name: string, purchase_details: record, purchased: bool, quantity: float, row_version: string, sales_details: record, sold: bool, taxable: bool, tracked: bool, type: string, unit_price: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoice-items-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoice-items-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoice-items-one: "record<data: record<active: bool, asset_account: record<code: string, id: string, name: string, nominal_code: string>, code: string, created_at: string, created_by: string, description: string, expense_account: record<code: string, id: string, name: string, nominal_code: string>, id: string, income_account: record<code: string, id: string, name: string, nominal_code: string>, inventory_date: string, name: string, purchase_details: record<tax_inclusive: bool, tax_rate: record, unit_of_measure: string, unit_price: float>, purchased: bool, quantity: float, row_version: string, sales_details: record<tax_inclusive: bool, tax_rate: record, unit_of_measure: string, unit_price: float>, sold: bool, taxable: bool, tracked: bool, type: string, unit_price: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoice-items-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoices-all: "record<data: table<balance: float, billing_address: record, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, customer_memo: string, deposit: float, discount_amount: float, discount_percentage: float, downstream_id: string, due_date: string, id: string, invoice_date: string, invoice_sent: bool, line_items: list, number: string, po_number: string, reference: string, row_version: string, shipping_address: record, source_document_url: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, template_id: string, terms: string, total: float, total_tax: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoices-add: "record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoices-delete: "record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoices-one: "record<data: record<balance: float, billing_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, customer_memo: string, deposit: float, discount_amount: float, discount_percentage: float, downstream_id: string, due_date: string, id: string, invoice_date: string, invoice_sent: bool, line_items: list<record>, number: string, po_number: string, reference: string, row_version: string, shipping_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, source_document_url: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, template_id: string, terms: string, total: float, total_tax: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    invoices-update: "record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    journal-entries-all: "record<data: table<created_at: string, created_by: string, currency: string, currency_rate: float, id: string, journal_symbol: string, line_items: list, memo: string, posted_at: string, row_version: string, title: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    journal-entries-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    journal-entries-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    journal-entries-one: "record<data: record<created_at: string, created_by: string, currency: string, currency_rate: float, id: string, journal_symbol: string, line_items: list<record>, memo: string, posted_at: string, row_version: string, title: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    journal-entries-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    ledger-accounts-all: "record<data: table<active: bool, bank_account: record, categories: list, classification: string, code: string, created_at: string, created_by: string, currency: string, current_balance: float, description: string, display_id: string, fully_qualified_name: string, header: bool, id: string, last_reconciliation_date: string, level: float, name: string, nominal_code: string, opening_balance: float, parent_account: record, row_version: string, status: string, sub_account: bool, sub_accounts: list, sub_type: string, tax_rate: record, tax_type: string, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    ledger-accounts-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    ledger-accounts-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    ledger-accounts-one: "record<data: record<active: bool, bank_account: record<account_name: string, account_number: string, account_type: string, bank_code: string, bic: string, branch_identifier: string, bsb_number: string, currency: string, iban: string>, categories: list<record>, classification: string, code: string, created_at: string, created_by: string, currency: string, current_balance: float, description: string, display_id: string, fully_qualified_name: string, header: bool, id: string, last_reconciliation_date: string, level: float, name: string, nominal_code: string, opening_balance: float, parent_account: record<display_id: string, id: string, name: string>, row_version: string, status: string, sub_account: bool, sub_accounts: list<record>, sub_type: string, tax_rate: record<code: string, id: string, name: string, rate: float>, tax_type: string, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    ledger-accounts-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-all: "record<data: table<account: record, accounts_receivable_account_id: string, accounts_receivable_account_type: string, allocations: list, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, display_id: string, downstream_id: string, id: string, note: string, payment_method: string, payment_method_id: string, payment_method_reference: string, reconciled: bool, reference: string, row_version: string, status: string, supplier: record, total_amount: float, transaction_date: string, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-one: "record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, accounts_receivable_account_id: string, accounts_receivable_account_type: string, allocations: list<record>, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, display_id: string, downstream_id: string, id: string, note: string, payment_method: string, payment_method_id: string, payment_method_reference: string, reconciled: bool, reference: string, row_version: string, status: string, supplier: record<address: record, company_name: string, display_name: string, id: string>, total_amount: float, transaction_date: string, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    payments-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    profit-and-loss-one: "record<data: record<currency: string, customer_id: string, end_date: string, expenses: record<records: list, total: float>, gross_profit: record<records: list, total: float>, id: string, income: record<records: list, total: float>, net_income: record<records: list, total: float>, net_operating_income: record<records: list, total: float>, report_name: string, start_date: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    suppliers-all: "record<data: table<account: record, addresses: list, bank_accounts: list, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, phone_numbers: list, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record, title: string, updated_at: string, updated_by: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    suppliers-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    suppliers-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    suppliers-one: "record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, addresses: list<record>, bank_accounts: list<record>, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list<record>, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, phone_numbers: list<record>, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record<code: string, id: string, name: string, rate: float>, title: string, updated_at: string, updated_by: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    suppliers-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tax-rates-all: "record<data: table<code: string, components: list, created_at: string, created_by: string, description: string, effective_tax_rate: float, id: string, name: string, original_tax_rate_id: string, report_tax_type: string, row_version: string, status: string, tax_payable_account_id: string, tax_remitted_account_id: string, total_tax_rate: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tax-rates-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tax-rates-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tax-rates-one: "record<data: record<code: string, components: list<record>, created_at: string, created_by: string, description: string, effective_tax_rate: float, id: string, name: string, original_tax_rate_id: string, report_tax_type: string, row_version: string, status: string, tax_payable_account_id: string, tax_remitted_account_id: string, total_tax_rate: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    tax-rates-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["balance-sheet-one" "bills-all" "bills-add" "bills-delete" "bills-one" "bills-update" "company-info-one" "credit-notes-all" "credit-notes-add" "credit-notes-delete" "credit-notes-one" "credit-notes-update" "customers-all" "customers-add" "customers-delete" "customers-one" "customers-update" "invoice-items-all" "invoice-items-add" "invoice-items-delete" "invoice-items-one" "invoice-items-update" "invoices-all" "invoices-add" "invoices-delete" "invoices-one" "invoices-update" "journal-entries-all" "journal-entries-add" "journal-entries-delete" "journal-entries-one" "journal-entries-update" "ledger-accounts-all" "ledger-accounts-add" "ledger-accounts-delete" "ledger-accounts-one" "ledger-accounts-update" "payments-all" "payments-add" "payments-delete" "payments-one" "payments-update" "profit-and-loss-one" "suppliers-all" "suppliers-add" "suppliers-delete" "suppliers-one" "suppliers-update" "tax-rates-all" "tax-rates-add" "tax-rates-delete" "tax-rates-one" "tax-rates-update" "commands"] | sort) } | get name | first)
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

# Get BalanceSheet
#
# GET /accounting/balance-sheet
# Returns: record<data: record<assets: record<current_assets: record, fixed_assets: record, total: float>, created_at: string, created_by: string, end_date: string, equity: record<items: list, total: float>, id: string, liabilities: record<accounts: list, total: float>, report_name: string, start_date: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: balanceSheetOne
export def "balance-sheet-one" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --filter: record # Apply filters (e.g. {end_date: 2021-12-31, start_date: 2021-01-01})
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/balance-sheet"
    query: [{name: pass_through, var: pass_through, style: deepObject}, {name: filter, var: filter, style: deepObject}, {name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pass_through: $pass_through, filter: $filter, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Bills
#
# GET /accounting/bills
# Returns: record<data: table<balance: float, bill_date: string, bill_number: string, created_at: string, created_by: string, currency: string, currency_rate: float, deposit: float, downstream_id: string, due_date: string, id: string, ledger_account: record, line_items: list, notes: string, paid_date: string, po_number: string, reference: string, row_version: string, status: string, sub_total: float, supplier: record, tax_code: string, tax_inclusive: bool, terms: string, total: float, total_tax: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: billsAll
export def "bills-all" [
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
  --sort: record # Apply sorting (e.g. {by: updated_at, direction: desc})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/bills"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort, var: sort, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, sort: $sort, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Bill
#
# POST /accounting/bills
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: billsAdd
export def "bills-add" [
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
  --balance: float # Balance of bill due. (nullable, e.g. 27500)
  --bill-date: string # Date bill was issued - YYYY-MM-DD. (format: date, e.g. 2020-09-30)
  --bill-number: string # nullable, e.g. 10001
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --deposit: float # Amount of deposit made to this bill. (nullable, e.g. 0)
  --due-date: string # The due date is the date on which a payment is scheduled to be received by the supplier - YYYY-MM-DD. (format: date, e.g. 2020-10-30)
  --ledger-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
  --notes: string # nullable, e.g. Some notes about this bill.
  --paid-date: string # The paid date is the date on which a payment was sent to the supplier - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional bill reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of bill, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this bill. (nullable, e.g. 2500)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/bills"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: bill_date, var: bill_date}, {name: bill_number, var: bill_number}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: deposit, var: deposit}, {name: due_date, var: due_date}, {name: ledger_account, var: ledger_account}, {name: line_items, var: line_items}, {name: notes, var: notes}, {name: paid_date, var: paid_date}, {name: po_number, var: po_number}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: supplier, var: supplier}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: terms, var: terms}, {name: total, var: total}, {name: total_tax, var: total_tax}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, balance: $balance, bill_date: $bill_date, bill_number: $bill_number, currency: $currency, currency_rate: $currency_rate, deposit: $deposit, due_date: $due_date, ledger_account: $ledger_account, line_items: $line_items, notes: $notes, paid_date: $paid_date, po_number: $po_number, reference: $reference, row_version: $row_version, status: $status, sub_total: $sub_total, supplier: $supplier, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total: $total, total_tax: $total_tax
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Bill
#
# DELETE /accounting/bills/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: billsDelete
export def "bills-delete" [
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
    path: "/accounting/bills/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Bill
#
# GET /accounting/bills/{id}
# Returns: record<data: record<balance: float, bill_date: string, bill_number: string, created_at: string, created_by: string, currency: string, currency_rate: float, deposit: float, downstream_id: string, due_date: string, id: string, ledger_account: record<code: string, id: string, name: string, nominal_code: string>, line_items: list<record>, notes: string, paid_date: string, po_number: string, reference: string, row_version: string, status: string, sub_total: float, supplier: record<address: record, company_name: string, display_name: string, id: string>, tax_code: string, tax_inclusive: bool, terms: string, total: float, total_tax: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: billsOne
export def "bills-one" [
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
    path: "/accounting/bills/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Bill
#
# PATCH /accounting/bills/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: billsUpdate
export def "bills-update" [
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
  --balance: float # Balance of bill due. (nullable, e.g. 27500)
  --bill-date: string # Date bill was issued - YYYY-MM-DD. (format: date, e.g. 2020-09-30)
  --bill-number: string # nullable, e.g. 10001
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --deposit: float # Amount of deposit made to this bill. (nullable, e.g. 0)
  --due-date: string # The due date is the date on which a payment is scheduled to be received by the supplier - YYYY-MM-DD. (format: date, e.g. 2020-10-30)
  --ledger-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
  --notes: string # nullable, e.g. Some notes about this bill.
  --paid-date: string # The paid date is the date on which a payment was sent to the supplier - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional bill reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of bill, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this bill. (nullable, e.g. 2500)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/bills/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: bill_date, var: bill_date}, {name: bill_number, var: bill_number}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: deposit, var: deposit}, {name: due_date, var: due_date}, {name: ledger_account, var: ledger_account}, {name: line_items, var: line_items}, {name: notes, var: notes}, {name: paid_date, var: paid_date}, {name: po_number, var: po_number}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: supplier, var: supplier}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: terms, var: terms}, {name: total, var: total}, {name: total_tax, var: total_tax}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, balance: $balance, bill_date: $bill_date, bill_number: $bill_number, currency: $currency, currency_rate: $currency_rate, deposit: $deposit, due_date: $due_date, ledger_account: $ledger_account, line_items: $line_items, notes: $notes, paid_date: $paid_date, po_number: $po_number, reference: $reference, row_version: $row_version, status: $status, sub_total: $sub_total, supplier: $supplier, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total: $total, total_tax: $total_tax
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get company info
#
# GET /accounting/company-info
# Returns: record<data: record<addresses: list<record>, automated_sales_tax: bool, company_name: string, company_start_date: string, country: string, created_at: string, created_by: string, currency: string, default_sales_tax: record<code: string, id: string, name: string, rate: float>, emails: list<record>, fiscal_year_start_month: string, id: string, language: string, legal_name: string, phone_numbers: list<record>, row_version: string, sales_tax_enabled: bool, sales_tax_number: string, status: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companyInfoOne
export def "company-info-one" [
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
    path: "/accounting/company-info"
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Credit Notes
#
# GET /accounting/credit-notes
# Returns: record<data: table<account: record, allocations: list, balance: float, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, date_issued: string, date_paid: string, id: string, line_items: list, note: string, number: string, reference: string, remaining_credit: float, row_version: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, terms: string, total_amount: float, total_tax: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: creditNotesAll
export def "credit-notes-all" [
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
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/credit-notes"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Credit Note
#
# POST /accounting/credit-notes
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: creditNotesAdd
export def "credit-notes-add" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --balance: float # The balance reflecting any payments made against the transaction. (nullable, e.g. 27500)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --date-issued: string # Date credit note issued - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --date-paid: string # Date credit note paid - YYYY:MM::DDThh:mm:ss.sTZD (nullable, format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --note: string # Optional note to be associated with the credit note. (nullable, e.g. Some notes about this credit note)
  --number: string # Credit note number. (nullable, e.g. OIT00546)
  --reference: string # Optional reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --remaining-credit: float # Indicates the total credit amount still available to apply towards the payment. (nullable, e.g. 27500)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-1 # Status of credit notes (e.g. authorised)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --terms: string # Optional terms to be associated with the credit note. (nullable, e.g. Some terms about this credit note)
  total_amount: float # Amount of transaction (e.g. 49.99)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer # Type of payment (e.g. accounts_receivable_credit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/credit-notes"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: allocations, var: allocations}, {name: balance, var: balance}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: date_issued, var: date_issued}, {name: date_paid, var: date_paid}, {name: line_items, var: line_items}, {name: note, var: note}, {name: number, var: number}, {name: reference, var: reference}, {name: remaining_credit, var: remaining_credit}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: terms, var: terms}, {name: total_amount, var: total_amount}, {name: total_tax, var: total_tax}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, allocations: $allocations, balance: $balance, currency: $currency, currency_rate: $currency_rate, customer: $customer, date_issued: $date_issued, date_paid: $date_paid, line_items: $line_items, note: $note, number: $number, reference: $reference, remaining_credit: $remaining_credit, row_version: $row_version, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total_amount: $total_amount, total_tax: $total_tax, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Credit Note
#
# DELETE /accounting/credit-notes/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: creditNotesDelete
export def "credit-notes-delete" [
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
    path: "/accounting/credit-notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Credit Note
#
# GET /accounting/credit-notes/{id}
# Returns: record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, allocations: list<record>, balance: float, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, date_issued: string, date_paid: string, id: string, line_items: list<record>, note: string, number: string, reference: string, remaining_credit: float, row_version: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, terms: string, total_amount: float, total_tax: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: creditNotesOne
export def "credit-notes-one" [
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
    path: "/accounting/credit-notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Credit Note
#
# PATCH /accounting/credit-notes/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: creditNotesUpdate
export def "credit-notes-update" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --balance: float # The balance reflecting any payments made against the transaction. (nullable, e.g. 27500)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --date-issued: string # Date credit note issued - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --date-paid: string # Date credit note paid - YYYY:MM::DDThh:mm:ss.sTZD (nullable, format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --note: string # Optional note to be associated with the credit note. (nullable, e.g. Some notes about this credit note)
  --number: string # Credit note number. (nullable, e.g. OIT00546)
  --reference: string # Optional reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --remaining-credit: float # Indicates the total credit amount still available to apply towards the payment. (nullable, e.g. 27500)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-1 # Status of credit notes (e.g. authorised)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --terms: string # Optional terms to be associated with the credit note. (nullable, e.g. Some terms about this credit note)
  total_amount: float # Amount of transaction (e.g. 49.99)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer # Type of payment (e.g. accounts_receivable_credit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/credit-notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: allocations, var: allocations}, {name: balance, var: balance}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: date_issued, var: date_issued}, {name: date_paid, var: date_paid}, {name: line_items, var: line_items}, {name: note, var: note}, {name: number, var: number}, {name: reference, var: reference}, {name: remaining_credit, var: remaining_credit}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: terms, var: terms}, {name: total_amount, var: total_amount}, {name: total_tax, var: total_tax}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, allocations: $allocations, balance: $balance, currency: $currency, currency_rate: $currency_rate, customer: $customer, date_issued: $date_issued, date_paid: $date_paid, line_items: $line_items, note: $note, number: $number, reference: $reference, remaining_credit: $remaining_credit, row_version: $row_version, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total_amount: $total_amount, total_tax: $total_tax, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Customers
#
# GET /accounting/customers
# Returns: record<data: table<account: record, addresses: list, bank_accounts: list, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, parent: record, phone_numbers: list, project: bool, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record, title: string, updated_at: string, updated_by: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: customersAll
export def "customers-all" [
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
  --filter: record # Apply filters (e.g. {company_name: SpaceX, display_name: Elon Musk, email: elon@musk.com, first_name: Elon, last_name: Musk})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/customers"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Customer
#
# POST /accounting/customers
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: customersAdd
export def "customers-add" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: oneof<nothing, bool> # Is this an individual or business customer (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this customer (nullable, e.g. Some notes about this customer)
  --parent: record # The parent customer this entity is linked to. (nullable) — shape: {id: string, name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --project: oneof<nothing, bool> # If true, indicates this is a Project. (nullable, e.g. false)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Customer status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/customers"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: addresses, var: addresses}, {name: bank_accounts, var: bank_accounts}, {name: company_name, var: company_name}, {name: currency, var: currency}, {name: display_id, var: display_id}, {name: display_name, var: display_name}, {name: emails, var: emails}, {name: first_name, var: first_name}, {name: individual, var: individual}, {name: last_name, var: last_name}, {name: middle_name, var: middle_name}, {name: notes, var: notes}, {name: parent, var: parent}, {name: phone_numbers, var: phone_numbers}, {name: project, var: project}, {name: row_version, var: row_version}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tax_number, var: tax_number}, {name: tax_rate, var: tax_rate}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, parent: $parent, phone_numbers: $phone_numbers, project: $project, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Customer
#
# DELETE /accounting/customers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: customersDelete
export def "customers-delete" [
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
    path: "/accounting/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Customer
#
# GET /accounting/customers/{id}
# Returns: record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, addresses: list<record>, bank_accounts: list<record>, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list<record>, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, parent: record<id: string, name: string>, phone_numbers: list<record>, project: bool, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record<code: string, id: string, name: string, rate: float>, title: string, updated_at: string, updated_by: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: customersOne
export def "customers-one" [
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
    path: "/accounting/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Customer
#
# PATCH /accounting/customers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: customersUpdate
export def "customers-update" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: oneof<nothing, bool> # Is this an individual or business customer (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this customer (nullable, e.g. Some notes about this customer)
  --parent: record # The parent customer this entity is linked to. (nullable) — shape: {id: string, name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --project: oneof<nothing, bool> # If true, indicates this is a Project. (nullable, e.g. false)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Customer status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/customers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: addresses, var: addresses}, {name: bank_accounts, var: bank_accounts}, {name: company_name, var: company_name}, {name: currency, var: currency}, {name: display_id, var: display_id}, {name: display_name, var: display_name}, {name: emails, var: emails}, {name: first_name, var: first_name}, {name: individual, var: individual}, {name: last_name, var: last_name}, {name: middle_name, var: middle_name}, {name: notes, var: notes}, {name: parent, var: parent}, {name: phone_numbers, var: phone_numbers}, {name: project, var: project}, {name: row_version, var: row_version}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tax_number, var: tax_number}, {name: tax_rate, var: tax_rate}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, parent: $parent, phone_numbers: $phone_numbers, project: $project, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Invoice Items
#
# GET /accounting/invoice-items
# Returns: record<data: table<active: bool, asset_account: record, code: string, created_at: string, created_by: string, description: string, expense_account: record, id: string, income_account: record, inventory_date: string, name: string, purchase_details: record, purchased: bool, quantity: float, row_version: string, sales_details: record, sold: bool, taxable: bool, tracked: bool, type: string, unit_price: float, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoiceItemsAll
export def "invoice-items-all" [
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
  --filter: record # Apply filters (e.g. {name: Widgets Large})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/invoice-items"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Invoice Item
#
# POST /accounting/invoice-items
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoiceItemsAdd
export def "invoice-items-add" [
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
  --active: oneof<nothing, bool> # nullable, e.g. true
  --asset-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --code: string # User defined item code (nullable, e.g. 120-C)
  --description: string # A short description of the item (nullable, e.g. Model Y is a fully electric, mid-size SUV, with seating for up to seven, dual motor AWD and unparalleled protection.)
  --expense-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --income-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --inventory-date: string # The date of opening balance if inventory item is tracked - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --name: string # Item name (nullable, e.g. Model Y)
  --purchase-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --purchased: oneof<nothing, bool> # Item is available for purchase transactions (nullable, e.g. true)
  --quantity: float # nullable, e.g. 1
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --sales-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --sold: oneof<nothing, bool> # Item will be available on sales transactions (nullable, e.g. true)
  --taxable: oneof<nothing, bool> # If true, transactions for this item are taxable (nullable, e.g. true)
  --tracked: oneof<nothing, bool> # Item is inventoried (nullable, e.g. true)
  --type: string@type-completer-1 # Item type (nullable, e.g. inventory)
  --unit-price: float # nullable, e.g. 27500.5
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/invoice-items"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: asset_account, var: asset_account}, {name: code, var: code}, {name: description, var: description}, {name: expense_account, var: expense_account}, {name: income_account, var: income_account}, {name: inventory_date, var: inventory_date}, {name: name, var: name}, {name: purchase_details, var: purchase_details}, {name: purchased, var: purchased}, {name: quantity, var: quantity}, {name: row_version, var: row_version}, {name: sales_details, var: sales_details}, {name: sold, var: sold}, {name: taxable, var: taxable}, {name: tracked, var: tracked}, {name: type, var: type}, {name: unit_price, var: unit_price}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, asset_account: $asset_account, code: $code, description: $description, expense_account: $expense_account, income_account: $income_account, inventory_date: $inventory_date, name: $name, purchase_details: $purchase_details, purchased: $purchased, quantity: $quantity, row_version: $row_version, sales_details: $sales_details, sold: $sold, taxable: $taxable, tracked: $tracked, type: $type, unit_price: $unit_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Invoice Item
#
# DELETE /accounting/invoice-items/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoiceItemsDelete
export def "invoice-items-delete" [
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
    path: "/accounting/invoice-items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Invoice Item
#
# GET /accounting/invoice-items/{id}
# Returns: record<data: record<active: bool, asset_account: record<code: string, id: string, name: string, nominal_code: string>, code: string, created_at: string, created_by: string, description: string, expense_account: record<code: string, id: string, name: string, nominal_code: string>, id: string, income_account: record<code: string, id: string, name: string, nominal_code: string>, inventory_date: string, name: string, purchase_details: record<tax_inclusive: bool, tax_rate: record, unit_of_measure: string, unit_price: float>, purchased: bool, quantity: float, row_version: string, sales_details: record<tax_inclusive: bool, tax_rate: record, unit_of_measure: string, unit_price: float>, sold: bool, taxable: bool, tracked: bool, type: string, unit_price: float, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoiceItemsOne
export def "invoice-items-one" [
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
    path: "/accounting/invoice-items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Invoice Item
#
# PATCH /accounting/invoice-items/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoiceItemsUpdate
export def "invoice-items-update" [
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
  --active: oneof<nothing, bool> # nullable, e.g. true
  --asset-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --code: string # User defined item code (nullable, e.g. 120-C)
  --description: string # A short description of the item (nullable, e.g. Model Y is a fully electric, mid-size SUV, with seating for up to seven, dual motor AWD and unparalleled protection.)
  --expense-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --income-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --inventory-date: string # The date of opening balance if inventory item is tracked - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --name: string # Item name (nullable, e.g. Model Y)
  --purchase-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --purchased: oneof<nothing, bool> # Item is available for purchase transactions (nullable, e.g. true)
  --quantity: float # nullable, e.g. 1
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --sales-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --sold: oneof<nothing, bool> # Item will be available on sales transactions (nullable, e.g. true)
  --taxable: oneof<nothing, bool> # If true, transactions for this item are taxable (nullable, e.g. true)
  --tracked: oneof<nothing, bool> # Item is inventoried (nullable, e.g. true)
  --type: string@type-completer-1 # Item type (nullable, e.g. inventory)
  --unit-price: float # nullable, e.g. 27500.5
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/invoice-items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: asset_account, var: asset_account}, {name: code, var: code}, {name: description, var: description}, {name: expense_account, var: expense_account}, {name: income_account, var: income_account}, {name: inventory_date, var: inventory_date}, {name: name, var: name}, {name: purchase_details, var: purchase_details}, {name: purchased, var: purchased}, {name: quantity, var: quantity}, {name: row_version, var: row_version}, {name: sales_details, var: sales_details}, {name: sold, var: sold}, {name: taxable, var: taxable}, {name: tracked, var: tracked}, {name: type, var: type}, {name: unit_price, var: unit_price}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, asset_account: $asset_account, code: $code, description: $description, expense_account: $expense_account, income_account: $income_account, inventory_date: $inventory_date, name: $name, purchase_details: $purchase_details, purchased: $purchased, quantity: $quantity, row_version: $row_version, sales_details: $sales_details, sold: $sold, taxable: $taxable, tracked: $tracked, type: $type, unit_price: $unit_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Invoices
#
# GET /accounting/invoices
# Returns: record<data: table<balance: float, billing_address: record, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, customer_memo: string, deposit: float, discount_amount: float, discount_percentage: float, downstream_id: string, due_date: string, id: string, invoice_date: string, invoice_sent: bool, line_items: list, number: string, po_number: string, reference: string, row_version: string, shipping_address: record, source_document_url: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, template_id: string, terms: string, total: float, total_tax: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoicesAll
export def "invoices-all" [
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
  --sort: record # Apply sorting (e.g. {by: updated_at, direction: desc})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/invoices"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: sort, var: sort, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, sort: $sort, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Invoice
#
# POST /accounting/invoices
# Returns: record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoicesAdd
export def "invoices-add" [
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
  --balance: float # Balance of invoice due. (nullable, e.g. 27500)
  --billing-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --customer-memo: string # Customer memo (nullable, e.g. Thank you for your business and have a great day!)
  --deposit: float # Amount of deposit made to this invoice. (nullable, e.g. 0)
  --discount-amount: float # Discount amount applied to this invoice. (nullable, e.g. 25)
  --discount-percentage: float # Discount percentage applied to this invoice. (nullable, e.g. 5.5)
  --due-date: string # The invoice due date is the date on which a payment or invoice is scheduled to be received by the seller - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-date: string # Date invoice was issued - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-sent: oneof<nothing, bool> # Invoice sent to contact/customer. (e.g. true)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --number: string # Invoice number. (nullable, e.g. OIT00546)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional invoice reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --shipping-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --source-document-url: string # URL link to a source document - shown as 'Go to [appName]' in the downstream app. Currently only supported for Xero. (nullable, e.g. https://www.invoicesolution.com/invoice/123456)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --template-id: string # Optional invoice template (nullable, e.g. 123456)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of invoice, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer-2 # Invoice type (nullable, e.g. service)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/invoices"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: billing_address, var: billing_address}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: customer_memo, var: customer_memo}, {name: deposit, var: deposit}, {name: discount_amount, var: discount_amount}, {name: discount_percentage, var: discount_percentage}, {name: due_date, var: due_date}, {name: invoice_date, var: invoice_date}, {name: invoice_sent, var: invoice_sent}, {name: line_items, var: line_items}, {name: number, var: number}, {name: po_number, var: po_number}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: shipping_address, var: shipping_address}, {name: source_document_url, var: source_document_url}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: template_id, var: template_id}, {name: terms, var: terms}, {name: total, var: total}, {name: total_tax, var: total_tax}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, balance: $balance, billing_address: $billing_address, currency: $currency, currency_rate: $currency_rate, customer: $customer, customer_memo: $customer_memo, deposit: $deposit, discount_amount: $discount_amount, discount_percentage: $discount_percentage, due_date: $due_date, invoice_date: $invoice_date, invoice_sent: $invoice_sent, line_items: $line_items, number: $number, po_number: $po_number, reference: $reference, row_version: $row_version, shipping_address: $shipping_address, source_document_url: $source_document_url, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, template_id: $template_id, terms: $terms, total: $total, total_tax: $total_tax, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Invoice
#
# DELETE /accounting/invoices/{id}
# Returns: record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoicesDelete
export def "invoices-delete" [
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
    path: "/accounting/invoices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Invoice
#
# GET /accounting/invoices/{id}
# Returns: record<data: record<balance: float, billing_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, customer_memo: string, deposit: float, discount_amount: float, discount_percentage: float, downstream_id: string, due_date: string, id: string, invoice_date: string, invoice_sent: bool, line_items: list<record>, number: string, po_number: string, reference: string, row_version: string, shipping_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, source_document_url: string, status: string, sub_total: float, tax_code: string, tax_inclusive: bool, template_id: string, terms: string, total: float, total_tax: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoicesOne
export def "invoices-one" [
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
    path: "/accounting/invoices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Invoice
#
# PATCH /accounting/invoices/{id}
# Returns: record<data: record<downstream_id: string, id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: invoicesUpdate
export def "invoices-update" [
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
  --balance: float # Balance of invoice due. (nullable, e.g. 27500)
  --billing-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --customer-memo: string # Customer memo (nullable, e.g. Thank you for your business and have a great day!)
  --deposit: float # Amount of deposit made to this invoice. (nullable, e.g. 0)
  --discount-amount: float # Discount amount applied to this invoice. (nullable, e.g. 25)
  --discount-percentage: float # Discount percentage applied to this invoice. (nullable, e.g. 5.5)
  --due-date: string # The invoice due date is the date on which a payment or invoice is scheduled to be received by the seller - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-date: string # Date invoice was issued - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-sent: oneof<nothing, bool> # Invoice sent to contact/customer. (e.g. true)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --number: string # Invoice number. (nullable, e.g. OIT00546)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional invoice reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --shipping-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --source-document-url: string # URL link to a source document - shown as 'Go to [appName]' in the downstream app. Currently only supported for Xero. (nullable, e.g. https://www.invoicesolution.com/invoice/123456)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: oneof<nothing, bool> # Amounts are including tax (nullable, e.g. true)
  --template-id: string # Optional invoice template (nullable, e.g. 123456)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of invoice, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer-2 # Invoice type (nullable, e.g. service)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/invoices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: billing_address, var: billing_address}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: customer_memo, var: customer_memo}, {name: deposit, var: deposit}, {name: discount_amount, var: discount_amount}, {name: discount_percentage, var: discount_percentage}, {name: due_date, var: due_date}, {name: invoice_date, var: invoice_date}, {name: invoice_sent, var: invoice_sent}, {name: line_items, var: line_items}, {name: number, var: number}, {name: po_number, var: po_number}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: shipping_address, var: shipping_address}, {name: source_document_url, var: source_document_url}, {name: status, var: status}, {name: sub_total, var: sub_total}, {name: tax_code, var: tax_code}, {name: tax_inclusive, var: tax_inclusive}, {name: template_id, var: template_id}, {name: terms, var: terms}, {name: total, var: total}, {name: total_tax, var: total_tax}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, balance: $balance, billing_address: $billing_address, currency: $currency, currency_rate: $currency_rate, customer: $customer, customer_memo: $customer_memo, deposit: $deposit, discount_amount: $discount_amount, discount_percentage: $discount_percentage, due_date: $due_date, invoice_date: $invoice_date, invoice_sent: $invoice_sent, line_items: $line_items, number: $number, po_number: $po_number, reference: $reference, row_version: $row_version, shipping_address: $shipping_address, source_document_url: $source_document_url, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, template_id: $template_id, terms: $terms, total: $total, total_tax: $total_tax, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Journal Entries
#
# GET /accounting/journal-entries
# Returns: record<data: table<created_at: string, created_by: string, currency: string, currency_rate: float, id: string, journal_symbol: string, line_items: list, memo: string, posted_at: string, row_version: string, title: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: journalEntriesAll
export def "journal-entries-all" [
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
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/journal-entries"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Journal Entry
#
# POST /accounting/journal-entries
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: journalEntriesAdd
export def "journal-entries-add" [
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
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --journal-symbol: string # Journal symbol of the entry. For example IND for indirect costs (nullable, e.g. IND)
  --line-items: list # Requires a minimum of 2 line items that sum to 0 — item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
  --memo: string # Reference for the journal entry. (nullable, e.g. Thank you for your business and have a great day!)
  --posted-at: string # This is the date on which the journal entry was added. This can be different from the creation date and can also be backdated. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --title: string # Journal entry title (nullable, e.g. Purchase Invoice-Inventory (USD): 2019/02/01 Batch Summary Entry)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/journal-entries"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: journal_symbol, var: journal_symbol}, {name: line_items, var: line_items}, {name: memo, var: memo}, {name: posted_at, var: posted_at}, {name: row_version, var: row_version}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, currency: $currency, currency_rate: $currency_rate, journal_symbol: $journal_symbol, line_items: $line_items, memo: $memo, posted_at: $posted_at, row_version: $row_version, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Journal Entry
#
# DELETE /accounting/journal-entries/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: journalEntriesDelete
export def "journal-entries-delete" [
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
    path: "/accounting/journal-entries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Journal Entry
#
# GET /accounting/journal-entries/{id}
# Returns: record<data: record<created_at: string, created_by: string, currency: string, currency_rate: float, id: string, journal_symbol: string, line_items: list<record>, memo: string, posted_at: string, row_version: string, title: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: journalEntriesOne
export def "journal-entries-one" [
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
    path: "/accounting/journal-entries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Journal Entry
#
# PATCH /accounting/journal-entries/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: journalEntriesUpdate
export def "journal-entries-update" [
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
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --journal-symbol: string # Journal symbol of the entry. For example IND for indirect costs (nullable, e.g. IND)
  --line-items: list # Requires a minimum of 2 line items that sum to 0 — item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
  --memo: string # Reference for the journal entry. (nullable, e.g. Thank you for your business and have a great day!)
  --posted-at: string # This is the date on which the journal entry was added. This can be different from the creation date and can also be backdated. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --title: string # Journal entry title (nullable, e.g. Purchase Invoice-Inventory (USD): 2019/02/01 Batch Summary Entry)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/journal-entries/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: journal_symbol, var: journal_symbol}, {name: line_items, var: line_items}, {name: memo, var: memo}, {name: posted_at, var: posted_at}, {name: row_version, var: row_version}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, currency: $currency, currency_rate: $currency_rate, journal_symbol: $journal_symbol, line_items: $line_items, memo: $memo, posted_at: $posted_at, row_version: $row_version, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Ledger Accounts
#
# GET /accounting/ledger-accounts
# Returns: record<data: table<active: bool, bank_account: record, categories: list, classification: string, code: string, created_at: string, created_by: string, currency: string, current_balance: float, description: string, display_id: string, fully_qualified_name: string, header: bool, id: string, last_reconciliation_date: string, level: float, name: string, nominal_code: string, opening_balance: float, parent_account: record, row_version: string, status: string, sub_account: bool, sub_accounts: list, sub_type: string, tax_rate: record, tax_type: string, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ledgerAccountsAll
export def "ledger-accounts-all" [
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
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/ledger-accounts"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Ledger Account
#
# POST /accounting/ledger-accounts
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ledgerAccountsAdd
@deprecated --flag nominal-code
export def "ledger-accounts-add" [
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
  --active: oneof<nothing, bool> # Whether the account is active or not. (nullable, e.g. true)
  --bank-account: record # shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --classification: string@classification-completer # The classification of account. (nullable, e.g. asset)
  --code: string # The code assigned to the account. (nullable, e.g. 453)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --current-balance: float # The current balance of the account. (nullable, e.g. 20000)
  --description: string # The description of the account. (nullable, e.g. Main checking account)
  --display-id: string # The human readable display ID used when displaying the account (e.g. 1-12345)
  --fully-qualified-name: string # The fully qualified name of the account. (nullable, e.g. Asset.Bank.Checking_Account)
  --header: oneof<nothing, bool> # Whether the account is a header or not. (nullable, e.g. true)
  --last-reconciliation-date: string # Reconciliation Date means the last calendar day of each Reconciliation Period. (nullable, format: date, e.g. 2020-09-30)
  --level: float # nullable, e.g. 1
  --name: string # The name of the account. (nullable, e.g. Bank account)
  --nominal-code: string # The nominal code of the ledger account. (DEPRECATED, nullable, e.g. N091)
  --opening-balance: float # The opening balance of the account. (nullable, e.g. 75000)
  --parent-account: record # shape: {display_id?: string, id?: string, name?: string}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # The status of the account. (nullable, e.g. active)
  --sub-account: oneof<nothing, bool> # Whether the account is a sub account or not. (nullable, e.g. false)
  --sub-type: string # The sub type of account. (nullable, e.g. CHECKING_ACCOUNT)
  --tax-rate: record # shape: {id?: string}
  --tax-type: string # The tax type of the account. (nullable, e.g. NONE)
  --type: string@type-completer-3 # The type of account. (e.g. bank)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/ledger-accounts"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: bank_account, var: bank_account}, {name: classification, var: classification}, {name: code, var: code}, {name: currency, var: currency}, {name: current_balance, var: current_balance}, {name: description, var: description}, {name: display_id, var: display_id}, {name: fully_qualified_name, var: fully_qualified_name}, {name: header, var: header}, {name: last_reconciliation_date, var: last_reconciliation_date}, {name: level, var: level}, {name: name, var: name}, {name: nominal_code, var: nominal_code}, {name: opening_balance, var: opening_balance}, {name: parent_account, var: parent_account}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_account, var: sub_account}, {name: sub_type, var: sub_type}, {name: tax_rate, var: tax_rate}, {name: tax_type, var: tax_type}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, bank_account: $bank_account, classification: $classification, code: $code, currency: $currency, current_balance: $current_balance, description: $description, display_id: $display_id, fully_qualified_name: $fully_qualified_name, header: $header, last_reconciliation_date: $last_reconciliation_date, level: $level, name: $name, nominal_code: $nominal_code, opening_balance: $opening_balance, parent_account: $parent_account, row_version: $row_version, status: $status, sub_account: $sub_account, sub_type: $sub_type, tax_rate: $tax_rate, tax_type: $tax_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Ledger Account
#
# DELETE /accounting/ledger-accounts/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ledgerAccountsDelete
export def "ledger-accounts-delete" [
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
    path: "/accounting/ledger-accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Ledger Account
#
# GET /accounting/ledger-accounts/{id}
# Returns: record<data: record<active: bool, bank_account: record<account_name: string, account_number: string, account_type: string, bank_code: string, bic: string, branch_identifier: string, bsb_number: string, currency: string, iban: string>, categories: list<record>, classification: string, code: string, created_at: string, created_by: string, currency: string, current_balance: float, description: string, display_id: string, fully_qualified_name: string, header: bool, id: string, last_reconciliation_date: string, level: float, name: string, nominal_code: string, opening_balance: float, parent_account: record<display_id: string, id: string, name: string>, row_version: string, status: string, sub_account: bool, sub_accounts: list<record>, sub_type: string, tax_rate: record<code: string, id: string, name: string, rate: float>, tax_type: string, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ledgerAccountsOne
export def "ledger-accounts-one" [
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
    path: "/accounting/ledger-accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Ledger Account
#
# PATCH /accounting/ledger-accounts/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: ledgerAccountsUpdate
@deprecated --flag nominal-code
export def "ledger-accounts-update" [
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
  --active: oneof<nothing, bool> # Whether the account is active or not. (nullable, e.g. true)
  --bank-account: record # shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --classification: string@classification-completer # The classification of account. (nullable, e.g. asset)
  --code: string # The code assigned to the account. (nullable, e.g. 453)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --current-balance: float # The current balance of the account. (nullable, e.g. 20000)
  --description: string # The description of the account. (nullable, e.g. Main checking account)
  --display-id: string # The human readable display ID used when displaying the account (e.g. 1-12345)
  --fully-qualified-name: string # The fully qualified name of the account. (nullable, e.g. Asset.Bank.Checking_Account)
  --header: oneof<nothing, bool> # Whether the account is a header or not. (nullable, e.g. true)
  --last-reconciliation-date: string # Reconciliation Date means the last calendar day of each Reconciliation Period. (nullable, format: date, e.g. 2020-09-30)
  --level: float # nullable, e.g. 1
  --name: string # The name of the account. (nullable, e.g. Bank account)
  --nominal-code: string # The nominal code of the ledger account. (DEPRECATED, nullable, e.g. N091)
  --opening-balance: float # The opening balance of the account. (nullable, e.g. 75000)
  --parent-account: record # shape: {display_id?: string, id?: string, name?: string}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # The status of the account. (nullable, e.g. active)
  --sub-account: oneof<nothing, bool> # Whether the account is a sub account or not. (nullable, e.g. false)
  --sub-type: string # The sub type of account. (nullable, e.g. CHECKING_ACCOUNT)
  --tax-rate: record # shape: {id?: string}
  --tax-type: string # The tax type of the account. (nullable, e.g. NONE)
  --type: string@type-completer-3 # The type of account. (e.g. bank)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/ledger-accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: bank_account, var: bank_account}, {name: classification, var: classification}, {name: code, var: code}, {name: currency, var: currency}, {name: current_balance, var: current_balance}, {name: description, var: description}, {name: display_id, var: display_id}, {name: fully_qualified_name, var: fully_qualified_name}, {name: header, var: header}, {name: last_reconciliation_date, var: last_reconciliation_date}, {name: level, var: level}, {name: name, var: name}, {name: nominal_code, var: nominal_code}, {name: opening_balance, var: opening_balance}, {name: parent_account, var: parent_account}, {name: row_version, var: row_version}, {name: status, var: status}, {name: sub_account, var: sub_account}, {name: sub_type, var: sub_type}, {name: tax_rate, var: tax_rate}, {name: tax_type, var: tax_type}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, bank_account: $bank_account, classification: $classification, code: $code, currency: $currency, current_balance: $current_balance, description: $description, display_id: $display_id, fully_qualified_name: $fully_qualified_name, header: $header, last_reconciliation_date: $last_reconciliation_date, level: $level, name: $name, nominal_code: $nominal_code, opening_balance: $opening_balance, parent_account: $parent_account, row_version: $row_version, status: $status, sub_account: $sub_account, sub_type: $sub_type, tax_rate: $tax_rate, tax_type: $tax_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Payments
#
# GET /accounting/payments
# Returns: record<data: table<account: record, accounts_receivable_account_id: string, accounts_receivable_account_type: string, allocations: list, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record, display_id: string, downstream_id: string, id: string, note: string, payment_method: string, payment_method_id: string, payment_method_reference: string, reconciled: bool, reference: string, row_version: string, status: string, supplier: record, total_amount: float, transaction_date: string, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsAll
export def "payments-all" [
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
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/payments"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Payment
#
# POST /accounting/payments
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsAdd
@deprecated --flag accounts-receivable-account-id
@deprecated --flag accounts-receivable-account-type
export def "payments-add" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --accounts-receivable-account-id: string # Unique identifier for the account to allocate payment to. (DEPRECATED, nullable, e.g. 123456)
  --accounts-receivable-account-type: string # Type of accounts receivable account. (DEPRECATED, nullable, e.g. Account)
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --display-id: string # Payment id to be displayed. (nullable, e.g. 123456)
  --note: string # Optional note to be associated with the payment. (nullable, e.g. Some notes about this payment)
  --payment-method: string # Payment method name (nullable, e.g. Credit Card)
  --payment-method-id: string # Unique identifier for the payment method. (nullable, e.g. 123456)
  --payment-method-reference: string # Optional reference message returned by payment method on processing (nullable, e.g. 123456)
  --reconciled: oneof<nothing, bool> # Payment has been reconciled (e.g. true)
  --reference: string # Optional payment reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-4 # Status of payment (e.g. authorised)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  total_amount: float # Amount of payment (e.g. 49.99)
  transaction_date: string # Date transaction was entered - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --type: string@type-completer-4 # Type of payment (e.g. accounts_receivable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/payments"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: accounts_receivable_account_id, var: accounts_receivable_account_id}, {name: accounts_receivable_account_type, var: accounts_receivable_account_type}, {name: allocations, var: allocations}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: display_id, var: display_id}, {name: note, var: note}, {name: payment_method, var: payment_method}, {name: payment_method_id, var: payment_method_id}, {name: payment_method_reference, var: payment_method_reference}, {name: reconciled, var: reconciled}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: status, var: status}, {name: supplier, var: supplier}, {name: total_amount, var: total_amount}, {name: transaction_date, var: transaction_date}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, accounts_receivable_account_id: $accounts_receivable_account_id, accounts_receivable_account_type: $accounts_receivable_account_type, allocations: $allocations, currency: $currency, currency_rate: $currency_rate, customer: $customer, display_id: $display_id, note: $note, payment_method: $payment_method, payment_method_id: $payment_method_id, payment_method_reference: $payment_method_reference, reconciled: $reconciled, reference: $reference, row_version: $row_version, status: $status, supplier: $supplier, total_amount: $total_amount, transaction_date: $transaction_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Payment
#
# DELETE /accounting/payments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsDelete
export def "payments-delete" [
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
    path: "/accounting/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment
#
# GET /accounting/payments/{id}
# Returns: record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, accounts_receivable_account_id: string, accounts_receivable_account_type: string, allocations: list<record>, created_at: string, created_by: string, currency: string, currency_rate: float, customer: record<company_name: string, display_id: string, display_name: string, id: string, name: string>, display_id: string, downstream_id: string, id: string, note: string, payment_method: string, payment_method_id: string, payment_method_reference: string, reconciled: bool, reference: string, row_version: string, status: string, supplier: record<address: record, company_name: string, display_name: string, id: string>, total_amount: float, transaction_date: string, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsOne
export def "payments-one" [
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
    path: "/accounting/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Payment
#
# PATCH /accounting/payments/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: paymentsUpdate
@deprecated --flag accounts-receivable-account-id
@deprecated --flag accounts-receivable-account-type
export def "payments-update" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --accounts-receivable-account-id: string # Unique identifier for the account to allocate payment to. (DEPRECATED, nullable, e.g. 123456)
  --accounts-receivable-account-type: string # Type of accounts receivable account. (DEPRECATED, nullable, e.g. Account)
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --display-id: string # Payment id to be displayed. (nullable, e.g. 123456)
  --note: string # Optional note to be associated with the payment. (nullable, e.g. Some notes about this payment)
  --payment-method: string # Payment method name (nullable, e.g. Credit Card)
  --payment-method-id: string # Unique identifier for the payment method. (nullable, e.g. 123456)
  --payment-method-reference: string # Optional reference message returned by payment method on processing (nullable, e.g. 123456)
  --reconciled: oneof<nothing, bool> # Payment has been reconciled (e.g. true)
  --reference: string # Optional payment reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-4 # Status of payment (e.g. authorised)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  total_amount: float # Amount of payment (e.g. 49.99)
  transaction_date: string # Date transaction was entered - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --type: string@type-completer-4 # Type of payment (e.g. accounts_receivable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: accounts_receivable_account_id, var: accounts_receivable_account_id}, {name: accounts_receivable_account_type, var: accounts_receivable_account_type}, {name: allocations, var: allocations}, {name: currency, var: currency}, {name: currency_rate, var: currency_rate}, {name: customer, var: customer}, {name: display_id, var: display_id}, {name: note, var: note}, {name: payment_method, var: payment_method}, {name: payment_method_id, var: payment_method_id}, {name: payment_method_reference, var: payment_method_reference}, {name: reconciled, var: reconciled}, {name: reference, var: reference}, {name: row_version, var: row_version}, {name: status, var: status}, {name: supplier, var: supplier}, {name: total_amount, var: total_amount}, {name: transaction_date, var: transaction_date}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, accounts_receivable_account_id: $accounts_receivable_account_id, accounts_receivable_account_type: $accounts_receivable_account_type, allocations: $allocations, currency: $currency, currency_rate: $currency_rate, customer: $customer, display_id: $display_id, note: $note, payment_method: $payment_method, payment_method_id: $payment_method_id, payment_method_reference: $payment_method_reference, reconciled: $reconciled, reference: $reference, row_version: $row_version, status: $status, supplier: $supplier, total_amount: $total_amount, transaction_date: $transaction_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Profit and Loss
#
# GET /accounting/profit-and-loss
# Returns: record<data: record<currency: string, customer_id: string, end_date: string, expenses: record<records: list, total: float>, gross_profit: record<records: list, total: float>, id: string, income: record<records: list, total: float>, net_income: record<records: list, total: float>, net_operating_income: record<records: list, total: float>, report_name: string, start_date: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: profitAndLossOne
export def "profit-and-loss-one" [
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
  --filter: record # Apply filters (e.g. {customer_id: 123abc, end_date: 2021-12-31, start_date: 2021-01-01})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/profit-and-loss"
    query: [{name: raw, var: qp_raw}, {name: filter, var: filter, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, filter: $filter, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Suppliers
#
# GET /accounting/suppliers
# Returns: record<data: table<account: record, addresses: list, bank_accounts: list, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, phone_numbers: list, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record, title: string, updated_at: string, updated_by: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: suppliersAll
export def "suppliers-all" [
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
  --filter: record # Apply filters (e.g. {company_name: SpaceX, email: elon@musk.com})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/suppliers"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Supplier
#
# POST /accounting/suppliers
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: suppliersAdd
export def "suppliers-add" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: oneof<nothing, bool> # Is this an individual or business supplier (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this supplier (nullable, e.g. Some notes about this supplier)
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Supplier status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/suppliers"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: addresses, var: addresses}, {name: bank_accounts, var: bank_accounts}, {name: company_name, var: company_name}, {name: currency, var: currency}, {name: display_id, var: display_id}, {name: display_name, var: display_name}, {name: emails, var: emails}, {name: first_name, var: first_name}, {name: individual, var: individual}, {name: last_name, var: last_name}, {name: middle_name, var: middle_name}, {name: notes, var: notes}, {name: phone_numbers, var: phone_numbers}, {name: row_version, var: row_version}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tax_number, var: tax_number}, {name: tax_rate, var: tax_rate}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, phone_numbers: $phone_numbers, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Supplier
#
# DELETE /accounting/suppliers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: suppliersDelete
export def "suppliers-delete" [
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
    path: "/accounting/suppliers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Supplier
#
# GET /accounting/suppliers/{id}
# Returns: record<data: record<account: record<code: string, id: string, name: string, nominal_code: string>, addresses: list<record>, bank_accounts: list<record>, company_name: string, created_at: string, created_by: string, currency: string, display_id: string, display_name: string, downstream_id: string, emails: list<record>, first_name: string, id: string, individual: bool, last_name: string, middle_name: string, notes: string, phone_numbers: list<record>, row_version: string, status: string, suffix: string, tax_number: string, tax_rate: record<code: string, id: string, name: string, rate: float>, title: string, updated_at: string, updated_by: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: suppliersOne
export def "suppliers-one" [
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
    path: "/accounting/suppliers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Supplier
#
# PATCH /accounting/suppliers/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: suppliersUpdate
export def "suppliers-update" [
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
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: oneof<nothing, bool> # Is this an individual or business supplier (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this supplier (nullable, e.g. Some notes about this supplier)
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Supplier status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/suppliers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: addresses, var: addresses}, {name: bank_accounts, var: bank_accounts}, {name: company_name, var: company_name}, {name: currency, var: currency}, {name: display_id, var: display_id}, {name: display_name, var: display_name}, {name: emails, var: emails}, {name: first_name, var: first_name}, {name: individual, var: individual}, {name: last_name, var: last_name}, {name: middle_name, var: middle_name}, {name: notes, var: notes}, {name: phone_numbers, var: phone_numbers}, {name: row_version, var: row_version}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tax_number, var: tax_number}, {name: tax_rate, var: tax_rate}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, phone_numbers: $phone_numbers, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Tax Rates
#
# GET /accounting/tax-rates
# Returns: record<data: table<code: string, components: list, created_at: string, created_by: string, description: string, effective_tax_rate: float, id: string, name: string, original_tax_rate_id: string, report_tax_type: string, row_version: string, status: string, tax_payable_account_id: string, tax_remitted_account_id: string, total_tax_rate: float, type: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: taxRatesAll
export def "tax-rates-all" [
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
  --filter: record # Apply filters (e.g. {assets: true, equity: true, expenses: true, liabilities: true, revenue: true})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounting/tax-rates"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: pass_through, var: pass_through, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, pass_through: $pass_through, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Tax Rate
#
# POST /accounting/tax-rates
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: taxRatesAdd
export def "tax-rates-add" [
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
  --code: string # Tax code assigned to identify this tax rate. (nullable, e.g. ABN)
  --components: list # nullable — item shape: {compound?: bool, id?: string, name?: string, rate?: float}
  --description: string # Description of tax rate (nullable, e.g. Reduced rate GST Purchases)
  --effective-tax-rate: float # Effective tax rate (nullable, e.g. 10)
  --id: string # ID assigned to identify this tax rate. (nullable, e.g. 1234)
  --name: string # Name assigned to identify this tax rate. (e.g. GST on Purchases)
  --original-tax-rate-id: string # ID of the original tax rate from which the new tax rate is derived. Helps to understand the relationship between corresponding tax rate entities. (nullable, e.g. 12345)
  --report-tax-type: string # Report Tax type to aggregate tax collected or paid for reporting purposes (nullable, e.g. NONE)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # Tax rate status (nullable, e.g. active)
  --tax-payable-account-id: string # Unique identifier for the account for tax collected. (nullable, e.g. 123456)
  --tax-remitted-account-id: string # Unique identifier for the account for tax remitted. (nullable, e.g. 123456)
  --total-tax-rate: float # Not compounded sum of the components of a tax rate (nullable, e.g. 10)
  --type: string # Tax type used to indicate the source of tax collected or paid (nullable, e.g. NONE)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounting/tax-rates"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: components, var: components}, {name: description, var: description}, {name: effective_tax_rate, var: effective_tax_rate}, {name: id, var: id}, {name: name, var: name}, {name: original_tax_rate_id, var: original_tax_rate_id}, {name: report_tax_type, var: report_tax_type}, {name: row_version, var: row_version}, {name: status, var: status}, {name: tax_payable_account_id, var: tax_payable_account_id}, {name: tax_remitted_account_id, var: tax_remitted_account_id}, {name: total_tax_rate, var: total_tax_rate}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, code: $code, components: $components, description: $description, effective_tax_rate: $effective_tax_rate, id: $id, name: $name, original_tax_rate_id: $original_tax_rate_id, report_tax_type: $report_tax_type, row_version: $row_version, status: $status, tax_payable_account_id: $tax_payable_account_id, tax_remitted_account_id: $tax_remitted_account_id, total_tax_rate: $total_tax_rate, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Tax Rate
#
# DELETE /accounting/tax-rates/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: taxRatesDelete
export def "tax-rates-delete" [
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
    path: "/accounting/tax-rates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tax Rate
#
# GET /accounting/tax-rates/{id}
# Returns: record<data: record<code: string, components: list<record>, created_at: string, created_by: string, description: string, effective_tax_rate: float, id: string, name: string, original_tax_rate_id: string, report_tax_type: string, row_version: string, status: string, tax_payable_account_id: string, tax_remitted_account_id: string, total_tax_rate: float, type: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: taxRatesOne
export def "tax-rates-one" [
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
    path: "/accounting/tax-rates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Tax Rate
#
# PATCH /accounting/tax-rates/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: taxRatesUpdate
export def "tax-rates-update" [
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
  --code: string # Tax code assigned to identify this tax rate. (nullable, e.g. ABN)
  --components: list # nullable — item shape: {compound?: bool, id?: string, name?: string, rate?: float}
  --description: string # Description of tax rate (nullable, e.g. Reduced rate GST Purchases)
  --effective-tax-rate: float # Effective tax rate (nullable, e.g. 10)
  --body-id: string # ID assigned to identify this tax rate. (nullable, e.g. 1234) (spec name: id)
  --name: string # Name assigned to identify this tax rate. (e.g. GST on Purchases)
  --original-tax-rate-id: string # ID of the original tax rate from which the new tax rate is derived. Helps to understand the relationship between corresponding tax rate entities. (nullable, e.g. 12345)
  --report-tax-type: string # Report Tax type to aggregate tax collected or paid for reporting purposes (nullable, e.g. NONE)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # Tax rate status (nullable, e.g. active)
  --tax-payable-account-id: string # Unique identifier for the account for tax collected. (nullable, e.g. 123456)
  --tax-remitted-account-id: string # Unique identifier for the account for tax remitted. (nullable, e.g. 123456)
  --total-tax-rate: float # Not compounded sum of the components of a tax rate (nullable, e.g. 10)
  --type: string # Tax type used to indicate the source of tax collected or paid (nullable, e.g. NONE)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounting/tax-rates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: components, var: components}, {name: description, var: description}, {name: effective_tax_rate, var: effective_tax_rate}, {name: id, var: body_id}, {name: name, var: name}, {name: original_tax_rate_id, var: original_tax_rate_id}, {name: report_tax_type, var: report_tax_type}, {name: row_version, var: row_version}, {name: status, var: status}, {name: tax_payable_account_id, var: tax_payable_account_id}, {name: tax_remitted_account_id, var: tax_remitted_account_id}, {name: total_tax_rate, var: total_tax_rate}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, code: $code, components: $components, description: $description, effective_tax_rate: $effective_tax_rate, body_id: $body_id, name: $name, original_tax_rate_id: $original_tax_rate_id, report_tax_type: $report_tax_type, row_version: $row_version, status: $status, tax_payable_account_id: $tax_payable_account_id, tax_remitted_account_id: $tax_remitted_account_id, total_tax_rate: $total_tax_rate, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
