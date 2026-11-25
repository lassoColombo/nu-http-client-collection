# Auto-generated client for Ad Exchange Buyer API v1.4
# Source: https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer/v1.4/openapi.json
# Auth: --token flag or $env.AD_EXCHANGE_BUYER_API_TOKEN

const CLIENT = {
  base_url: "https://www.googleapis.com/adexchangebuyer/v1.4"
  token_env_var: "AD_EXCHANGE_BUYER_API_TOKEN"
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

def base-url-completer [] { ["https://www.googleapis.com/adexchangebuyer/v1.4"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def deals-status-filter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }
def open-auction-status-filter-completer [] { ["approved" "conditionally_approved" "disapproved" "not_checked"] }
def update-action-completer [] { ["accept" "cancel" "propose" "proposeAndAccept" "unknownAction" "updateNonTerms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    adexchangebuyer-accounts-list: "record<items: table<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: list, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>, kind: string>"
    adexchangebuyer-accounts-get: "record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>"
    adexchangebuyer-accounts-patch: "record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>"
    adexchangebuyer-accounts-update: "record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>"
    adexchangebuyer-billing-info-list: "record<items: table<accountId: int, accountName: string, billingId: list, kind: string>, kind: string>"
    adexchangebuyer-billing-info-get: "record<accountId: int, accountName: string, billingId: list<string>, kind: string>"
    adexchangebuyer-budget-get: "record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>"
    adexchangebuyer-budget-patch: "record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>"
    adexchangebuyer-budget-update: "record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>"
    adexchangebuyer-creatives-list: "record<items: table<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserId: list, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list, buyerCreativeId: string, clickThroughUrl: list, corrections: list, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list, filteringReasons: record, height: int, impressionTrackingUrl: list, kind: string, languages: list, nativeAd: record, openAuctionStatus: string, productCategories: list, restrictedCategories: list, sensitiveCategories: list, servingRestrictions: list, vendorType: list, version: int, videoURL: string, videoVastXML: string, width: int>, kind: string, nextPageToken: string>"
    adexchangebuyer-creatives-insert: "record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int>"
    adexchangebuyer-creatives-get: "record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int>"
    adexchangebuyer-creatives-list-deals: "record<dealStatuses: table<arcStatus: string, dealId: string, webPropertyId: int>, kind: string>"
    adexchangebuyer-performance-report-list: "record<kind: string, performanceReport: table<bidRate: float, bidRequestRate: float, calloutStatusRate: list, cookieMatcherStatusRate: list, creativeStatusRate: list, filteredBidRate: float, hostedMatchStatusRate: list, inventoryMatchRate: float, kind: string, latency50thPercentile: float, latency85thPercentile: float, latency95thPercentile: float, noQuotaInRegion: float, outOfQuota: float, pixelMatchRequests: float, pixelMatchResponses: float, quotaConfiguredLimit: float, quotaThrottledLimit: float, region: string, successfulRequestRate: float, timestamp: string, unsuccessfulRequestRate: float>>"
    adexchangebuyer-pretargeting-config-list: "record<items: table<billingId: string, configId: string, configName: string, creativeType: list, dimensions: list, excludedContentLabels: list, excludedGeoCriteriaIds: list, excludedPlacements: list, excludedUserLists: list, excludedVerticals: list, geoCriteriaIds: list, isActive: bool, kind: string, languages: list, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list, mobileDevices: list, mobileOperatingSystemVersions: list, placements: list, platforms: list, supportedCreativeAttributes: list, userIdentifierDataRequired: list, userLists: list, vendorTypes: list, verticals: list, videoPlayerSizes: list>, kind: string>"
    adexchangebuyer-pretargeting-config-insert: "record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>"
    adexchangebuyer-pretargeting-config-get: "record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>"
    adexchangebuyer-pretargeting-config-patch: "record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>"
    adexchangebuyer-pretargeting-config-update: "record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>"
    adexchangebuyer-products-search: "record<products: table<billedBuyer: record, buyer: record, creationTimeMs: string, creatorContacts: list, creatorRole: string, deliveryControl: record, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: list, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record, revisionNumber: string, seller: record, sharedTargetings: list, state: string, syndicationProduct: string, terms: record, webPropertyCode: string>>"
    adexchangebuyer-products-get: "record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, creationTimeMs: string, creatorContacts: table<email: string, name: string>, creatorRole: string, deliveryControl: record<creativeBlockingLevel: string, deliveryRateType: string, frequencyCaps: list<record>>, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record<dimensions: list<record>, weeklyImpressions: string, weeklyUniques: string>, revisionNumber: string, seller: record<accountId: string, subAccountId: string>, sharedTargetings: table<exclusions: list, inclusions: list, key: string>, state: string, syndicationProduct: string, terms: record<brandingType: string, crossListedExternalDealIdType: string, description: string, estimatedGrossSpend: record<amountMicros: float, currencyCode: string, expectedCpmMicros: float, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<billingInfo: record, fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, minimumDailyLooks: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricePerBuyers: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, rubiconNonGuaranteedTerms: record<priorityPrice: record, standardPrice: record>, sellerTimeZone: string>, webPropertyCode: string>"
    adexchangebuyer-proposals-insert: "record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>>"
    adexchangebuyer-proposals-search: "record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>>"
    adexchangebuyer-proposals-get: "record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>"
    adexchangebuyer-marketplacedeals-list: "record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>>"
    adexchangebuyer-marketplacedeals-delete: "record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string>"
    adexchangebuyer-marketplacedeals-insert: "record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string>"
    adexchangebuyer-marketplacedeals-update: "record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, orderRevisionNumber: string>"
    adexchangebuyer-marketplacenotes-list: "record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>>"
    adexchangebuyer-marketplacenotes-insert: "record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>>"
    adexchangebuyer-proposals-patch: "record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>"
    adexchangebuyer-proposals-update: "record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>"
    adexchangebuyer-pubprofiles-list: "record<profiles: table<audience: string, buyerPitchStatement: string, directContact: string, exchange: string, forecastInventory: string, googlePlusLink: string, isParent: bool, isPublished: bool, kind: string, logoUrl: string, mediaKitLink: string, name: string, overview: string, profileId: int, programmaticContact: string, publisherAppIds: list, publisherApps: list, publisherDomains: list, publisherProfileId: string, publisherProvidedForecast: record, rateCardInfoLink: string, samplePageLink: string, seller: record, state: string, topHeadlines: list>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["adexchangebuyer-accounts-list" "adexchangebuyer-accounts-get" "adexchangebuyer-accounts-patch" "adexchangebuyer-accounts-update" "adexchangebuyer-billing-info-list" "adexchangebuyer-billing-info-get" "adexchangebuyer-budget-get" "adexchangebuyer-budget-patch" "adexchangebuyer-budget-update" "adexchangebuyer-creatives-list" "adexchangebuyer-creatives-insert" "adexchangebuyer-creatives-get" "adexchangebuyer-creatives-add-deal" "adexchangebuyer-creatives-list-deals" "adexchangebuyer-creatives-remove-deal" "adexchangebuyer-performance-report-list" "adexchangebuyer-pretargeting-config-list" "adexchangebuyer-pretargeting-config-insert" "adexchangebuyer-pretargeting-config-delete" "adexchangebuyer-pretargeting-config-get" "adexchangebuyer-pretargeting-config-patch" "adexchangebuyer-pretargeting-config-update" "adexchangebuyer-marketplaceprivateauction-updateproposal" "adexchangebuyer-products-search" "adexchangebuyer-products-get" "adexchangebuyer-proposals-insert" "adexchangebuyer-proposals-search" "adexchangebuyer-proposals-get" "adexchangebuyer-marketplacedeals-list" "adexchangebuyer-marketplacedeals-delete" "adexchangebuyer-marketplacedeals-insert" "adexchangebuyer-marketplacedeals-update" "adexchangebuyer-marketplacenotes-list" "adexchangebuyer-marketplacenotes-insert" "adexchangebuyer-proposals-setupcomplete" "adexchangebuyer-proposals-patch" "adexchangebuyer-proposals-update" "adexchangebuyer-pubprofiles-list" "commands"] | sort) } | get name | first)
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

# Retrieves the authenticated user's list of accounts.
#
# GET /accounts
# Returns: record<items: table<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: list, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>, kind: string>
# operationId: adexchangebuyer.accounts.list
export def "adexchangebuyer-accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets one account by ID.
#
# GET /accounts/{id}
# Returns: record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>
# operationId: adexchangebuyer.accounts.get
export def "adexchangebuyer-accounts-get" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing account. This method supports patch semantics.
#
# PATCH /accounts/{id}
# Returns: record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>
# operationId: adexchangebuyer.accounts.patch
export def "adexchangebuyer-accounts-patch" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --confirm-unsafe-account-change: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --apply-pretargeting-to-non-guaranteed-deals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidder-location: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookie-matching-nid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookie-matching-url: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32) (spec name: id)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximum-active-creatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximum-total-qps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --number-active-creatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: confirmUnsafeAccountChange, var: confirm_unsafe_account_change}]
    body: {content_type: "application/json", kind: json, fields: [{name: applyPretargetingToNonGuaranteedDeals, var: apply_pretargeting_to_non_guaranteed_deals}, {name: bidderLocation, var: bidder_location}, {name: cookieMatchingNid, var: cookie_matching_nid}, {name: cookieMatchingUrl, var: cookie_matching_url}, {name: id, var: body_id}, {name: kind, var: kind}, {name: maximumActiveCreatives, var: maximum_active_creatives}, {name: maximumTotalQps, var: maximum_total_qps}, {name: numberActiveCreatives, var: number_active_creatives}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, confirm_unsafe_account_change: $confirm_unsafe_account_change, apply_pretargeting_to_non_guaranteed_deals: $apply_pretargeting_to_non_guaranteed_deals, bidder_location: $bidder_location, cookie_matching_nid: $cookie_matching_nid, cookie_matching_url: $cookie_matching_url, body_id: $body_id, kind: $kind, maximum_active_creatives: $maximum_active_creatives, maximum_total_qps: $maximum_total_qps, number_active_creatives: $number_active_creatives
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing account.
#
# PUT /accounts/{id}
# Returns: record<applyPretargetingToNonGuaranteedDeals: bool, bidderLocation: table<bidProtocol: string, maximumQps: int, region: string, url: string>, cookieMatchingNid: string, cookieMatchingUrl: string, id: int, kind: string, maximumActiveCreatives: int, maximumTotalQps: int, numberActiveCreatives: int>
# operationId: adexchangebuyer.accounts.update
export def "adexchangebuyer-accounts-update" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --confirm-unsafe-account-change: oneof<nothing, bool> # Confirmation for erasing bidder and cookie matching urls.
  --apply-pretargeting-to-non-guaranteed-deals: oneof<nothing, bool> # When this is false, bid requests that include a deal ID for a private auction or preferred deal are always sent to your bidder. When true, all active pretargeting configs will be applied to private auctions and preferred deals. Programmatic Guaranteed deals (when enabled) are always sent to your bidder.
  --bidder-location: list # Your bidder locations that have distinct URLs. — item shape: {bidProtocol?: string, maximumQps?: int, region?: string, url?: string}
  --cookie-matching-nid: string # The nid parameter value used in cookie match requests. Please contact your technical account manager if you need to change this.
  --cookie-matching-url: string # The base URL used in cookie match requests.
  --body-id: int # Account id. (format: int32) (spec name: id)
  --kind: string # Resource type. (default: adexchangebuyer#account)
  --maximum-active-creatives: int # The maximum number of active creatives that an account can have, where a creative is active if it was inserted or bid with in the last 30 days. Please contact your technical account manager if you need to change this. (format: int32)
  --maximum-total-qps: int # The sum of all bidderLocation.maximumQps values cannot exceed this. Please contact your technical account manager if you need to change this. (format: int32)
  --number-active-creatives: int # The number of creatives that this account inserted or bid with in the last 30 days. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: confirmUnsafeAccountChange, var: confirm_unsafe_account_change}]
    body: {content_type: "application/json", kind: json, fields: [{name: applyPretargetingToNonGuaranteedDeals, var: apply_pretargeting_to_non_guaranteed_deals}, {name: bidderLocation, var: bidder_location}, {name: cookieMatchingNid, var: cookie_matching_nid}, {name: cookieMatchingUrl, var: cookie_matching_url}, {name: id, var: body_id}, {name: kind, var: kind}, {name: maximumActiveCreatives, var: maximum_active_creatives}, {name: maximumTotalQps, var: maximum_total_qps}, {name: numberActiveCreatives, var: number_active_creatives}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, confirm_unsafe_account_change: $confirm_unsafe_account_change, apply_pretargeting_to_non_guaranteed_deals: $apply_pretargeting_to_non_guaranteed_deals, bidder_location: $bidder_location, cookie_matching_nid: $cookie_matching_nid, cookie_matching_url: $cookie_matching_url, body_id: $body_id, kind: $kind, maximum_active_creatives: $maximum_active_creatives, maximum_total_qps: $maximum_total_qps, number_active_creatives: $number_active_creatives
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of billing information for all accounts of the authenticated user.
#
# GET /billinginfo
# Returns: record<items: table<accountId: int, accountName: string, billingId: list, kind: string>, kind: string>
# operationId: adexchangebuyer.billingInfo.list
export def "adexchangebuyer-billing-info-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/billinginfo"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the billing information for one account specified by account ID.
#
# GET /billinginfo/{accountId}
# Returns: record<accountId: int, accountName: string, billingId: list<string>, kind: string>
# operationId: adexchangebuyer.billingInfo.get
export def "adexchangebuyer-billing-info-get" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/billinginfo/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the budget information for the adgroup specified by the accountId and billingId.
#
# GET /billinginfo/{accountId}/{billingId}
# Returns: record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>
# operationId: adexchangebuyer.budget.get
export def "adexchangebuyer-budget-get" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/billinginfo/{accountId}/{billingId}"
    path_params: [{name: accountId, var: account_id}, {name: billingId, var: billing_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, billing_id: $billing_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request. This method supports patch semantics.
#
# PATCH /billinginfo/{accountId}/{billingId}
# Returns: record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>
# operationId: adexchangebuyer.budget.patch
export def "adexchangebuyer-budget-patch" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # The id of the account. This is required for get and update requests. (format: int64) (spec name: accountId)
  --body-billing-id: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64) (spec name: billingId)
  --budget-amount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currency-code: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/billinginfo/{accountId}/{billingId}"
    path_params: [{name: accountId, var: account_id}, {name: billingId, var: billing_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: billingId, var: body_billing_id}, {name: budgetAmount, var: budget_amount}, {name: currencyCode, var: currency_code}, {name: id, var: id}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, billing_id: $billing_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, body_billing_id: $body_billing_id, budget_amount: $budget_amount, currency_code: $currency_code, id: $id, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the budget amount for the budget of the adgroup specified by the accountId and billingId, with the budget amount in the request.
#
# PUT /billinginfo/{accountId}/{billingId}
# Returns: record<accountId: string, billingId: string, budgetAmount: string, currencyCode: string, id: string, kind: string>
# operationId: adexchangebuyer.budget.update
export def "adexchangebuyer-budget-update" [
  account_id: string
  billing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # The id of the account. This is required for get and update requests. (format: int64) (spec name: accountId)
  --body-billing-id: string # The billing id to determine which adgroup to provide budget information for. This is required for get and update requests. (format: int64) (spec name: billingId)
  --budget-amount: string # The daily budget amount in unit amount of the account currency to apply for the billingId provided. This is required for update requests. (format: int64)
  --currency-code: string # The currency code for the buyer. This cannot be altered here.
  --id: string # The unique id that describes this item.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#budget". (default: adexchangebuyer#budget)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/billinginfo/{accountId}/{billingId}"
    path_params: [{name: accountId, var: account_id}, {name: billingId, var: billing_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: body_account_id}, {name: billingId, var: body_billing_id}, {name: budgetAmount, var: budget_amount}, {name: currencyCode, var: currency_code}, {name: id, var: id}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, billing_id: $billing_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body_account_id: $body_account_id, body_billing_id: $body_billing_id, budget_amount: $budget_amount, currency_code: $currency_code, id: $id, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of the authenticated user's active creatives. A creative will be available 30-40 minutes after submission.
#
# GET /creatives
# Returns: record<items: table<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record, advertiserId: list, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list, buyerCreativeId: string, clickThroughUrl: list, corrections: list, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list, filteringReasons: record, height: int, impressionTrackingUrl: list, kind: string, languages: list, nativeAd: record, openAuctionStatus: string, productCategories: list, restrictedCategories: list, sensitiveCategories: list, servingRestrictions: list, vendorType: list, version: int, videoURL: string, videoVastXML: string, width: int>, kind: string, nextPageToken: string>
# operationId: adexchangebuyer.creatives.list
export def "adexchangebuyer-creatives-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-id: list<int> # When specified, only creatives for the given account ids are returned.
  --buyer-creative-id: list<string> # When specified, only creatives for the given buyer creative ids are returned.
  --deals-status-filter: string@deals-status-filter-completer # When specified, only creatives having the given deals status are returned.
  --max-results: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --open-auction-status-filter: string@open-auction-status-filter-completer # When specified, only creatives having the given open auction status are returned.
  --page-token: string # A continuation token, used to page through ad clients. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/creatives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: accountId, var: account_id, style: multi}, {name: buyerCreativeId, var: buyer_creative_id, style: multi}, {name: dealsStatusFilter, var: deals_status_filter}, {name: maxResults, var: max_results}, {name: openAuctionStatusFilter, var: open_auction_status_filter}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, account_id: $account_id, buyer_creative_id: $buyer_creative_id, deals_status_filter: $deals_status_filter, max_results: $max_results, open_auction_status_filter: $open_auction_status_filter, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new creative.
#
# POST /creatives
# Returns: record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int>
# operationId: adexchangebuyer.creatives.insert
export def "adexchangebuyer-creatives-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --html-snippet: string # The HTML snippet that displays the ad when inserted in the web page. If set, videoURL, videoVastXML, and nativeAd should not be set.
  --account-id: int # Account id. (format: int32)
  --ad-choices-destination-url: string # The link to the Ad Preferences page. This is only supported for native ads.
  --ad-technology-providers: record # shape: {detectedProviderIds?: list<string>, hasUnidentifiedProvider?: bool}
  --advertiser-id: list<string> # Detected advertiser id, if any. Read-only. This field should not be set in requests.
  --advertiser-name: string # The name of the company being advertised in the creative. A list of advertisers is provided in the advertisers.txt file.
  --agency-id: string # The agency id for this creative. (format: int64)
  --api-upload-timestamp: string # The last upload timestamp of this creative if it was uploaded via API. Read-only. The value of this field is generated, and will be ignored for uploads. (formatted RFC 3339 timestamp). (format: date-time)
  --attribute: list<int> # List of buyer selectable attributes for the ads that may be shown from this snippet. Each attribute is represented by an integer as defined in buyer-declarable-creative-attributes.txt.
  --buyer-creative-id: string # A buyer-specific id identifying the creative in this ad.
  --click-through-url: list<string> # The set of destination urls for the snippet.
  --corrections: list # Shows any corrections that were applied to this creative. Read-only. This field should not be set in requests. — item shape: {contexts?: list, details?: list<string>, reason?: string}
  --creative-status-identity-type: string # Creative status identity type that the creative item applies to. Ad Exchange real-time bidding is migrating to the sizeless creative verification. Originally, Ad Exchange assigned creative verification status to a unique combination of a buyer creative ID and creative dimensions. Post-migration, a single verification status will be assigned at the buyer creative ID level. This field allows to distinguish whether a given creative status applies to a unique combination of a buyer creative ID and creative dimensions, or to a buyer creative ID as a whole.
  --deals-status: string # Top-level deals status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=DIRECT_DEALS (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from servingRestrictions directly.
  --detected-domains: list<string> # Detected domains for this creative. Read-only. This field should not be set in requests.
  --filtering-reasons: record # The filtering reasons for the creative. Read-only. This field should not be set in requests. — shape: {date?: string, reasons?: list}
  --height: int # Ad height. (format: int32)
  --impression-tracking-url: list<string> # The set of urls to be called to record an impression.
  --kind: string # Resource type. (default: adexchangebuyer#creative)
  --languages: list<string> # Detected languages for this creative. Read-only. This field should not be set in requests.
  --native-ad: record # If nativeAd is set, HTMLSnippet, videoVastXML, and the videoURL outside of nativeAd should not be set. (The videoURL inside nativeAd can be set.) — shape: {advertiser?: string, appIcon?: record, body?: string, callToAction?: string, clickLinkUrl?: string, clickTrackingUrl?: string, headline?: string, image?: record, impressionTrackingUrl?: list<string>, logo?: record, price?: string, starRating?: float, videoURL?: string}
  --open-auction-status: string # Top-level open auction status. Read-only. This field should not be set in requests. If disapproved, an entry for auctionType=OPEN_AUCTION (or ALL) in servingRestrictions will also exist. Note that this may be nuanced with other contextual restrictions, in which case it may be preferable to read from ServingRestrictions directly.
  --product-categories: list<int> # Detected product categories, if any. Each category is represented by an integer as defined in ad-product-categories.txt. Read-only. This field should not be set in requests.
  --restricted-categories: list<int> # All restricted categories for the ads that may be shown from this snippet. Each category is represented by an integer as defined in the ad-restricted-categories.txt.
  --sensitive-categories: list<int> # Detected sensitive categories, if any. Each category is represented by an integer as defined in ad-sensitive-categories.txt. Read-only. This field should not be set in requests.
  --serving-restrictions: list # The granular status of this ad in specific contexts. A context here relates to where something ultimately serves (for example, a physical location, a platform, an HTTPS vs HTTP request, or the type of auction). Read-only. This field should not be set in requests. See the examples in the Creatives guide for more details. — item shape: {contexts?: list, disapprovalReasons?: list, reason?: string}
  --vendor-type: list<int> # List of vendor types for the ads that may be shown from this snippet. Each vendor type is represented by an integer as defined in vendors.txt.
  --version: int # The version for this creative. Read-only. This field should not be set in requests. (format: int32)
  --video-url: string # The URL to fetch a video ad. If set, HTMLSnippet, videoVastXML, and nativeAd should not be set. Note, this is different from resource.native_ad.video_url above.
  --video-vast-xml: string # The contents of a VAST document for a video ad. This document should conform to the VAST 2.0 or 3.0 standard. If set, HTMLSnippet, videoURL, and nativeAd and should not be set.
  --width: int # Ad width. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/creatives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: HTMLSnippet, var: html_snippet}, {name: accountId, var: account_id}, {name: adChoicesDestinationUrl, var: ad_choices_destination_url}, {name: adTechnologyProviders, var: ad_technology_providers}, {name: advertiserId, var: advertiser_id}, {name: advertiserName, var: advertiser_name}, {name: agencyId, var: agency_id}, {name: apiUploadTimestamp, var: api_upload_timestamp}, {name: attribute, var: attribute}, {name: buyerCreativeId, var: buyer_creative_id}, {name: clickThroughUrl, var: click_through_url}, {name: corrections, var: corrections}, {name: creativeStatusIdentityType, var: creative_status_identity_type}, {name: dealsStatus, var: deals_status}, {name: detectedDomains, var: detected_domains}, {name: filteringReasons, var: filtering_reasons}, {name: height, var: height}, {name: impressionTrackingUrl, var: impression_tracking_url}, {name: kind, var: kind}, {name: languages, var: languages}, {name: nativeAd, var: native_ad}, {name: openAuctionStatus, var: open_auction_status}, {name: productCategories, var: product_categories}, {name: restrictedCategories, var: restricted_categories}, {name: sensitiveCategories, var: sensitive_categories}, {name: servingRestrictions, var: serving_restrictions}, {name: vendorType, var: vendor_type}, {name: version, var: version}, {name: videoURL, var: video_url}, {name: videoVastXML, var: video_vast_xml}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, html_snippet: $html_snippet, account_id: $account_id, ad_choices_destination_url: $ad_choices_destination_url, ad_technology_providers: $ad_technology_providers, advertiser_id: $advertiser_id, advertiser_name: $advertiser_name, agency_id: $agency_id, api_upload_timestamp: $api_upload_timestamp, attribute: $attribute, buyer_creative_id: $buyer_creative_id, click_through_url: $click_through_url, corrections: $corrections, creative_status_identity_type: $creative_status_identity_type, deals_status: $deals_status, detected_domains: $detected_domains, filtering_reasons: $filtering_reasons, height: $height, impression_tracking_url: $impression_tracking_url, kind: $kind, languages: $languages, native_ad: $native_ad, open_auction_status: $open_auction_status, product_categories: $product_categories, restricted_categories: $restricted_categories, sensitive_categories: $sensitive_categories, serving_restrictions: $serving_restrictions, vendor_type: $vendor_type, version: $version, video_url: $video_url, video_vast_xml: $video_vast_xml, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status for a single creative. A creative will be available 30-40 minutes after submission.
#
# GET /creatives/{accountId}/{buyerCreativeId}
# Returns: record<HTMLSnippet: string, accountId: int, adChoicesDestinationUrl: string, adTechnologyProviders: record<detectedProviderIds: list<string>, hasUnidentifiedProvider: bool>, advertiserId: list<string>, advertiserName: string, agencyId: string, apiUploadTimestamp: string, attribute: list<int>, buyerCreativeId: string, clickThroughUrl: list<string>, corrections: table<contexts: list, details: list, reason: string>, creativeStatusIdentityType: string, dealsStatus: string, detectedDomains: list<string>, filteringReasons: record<date: string, reasons: list<record>>, height: int, impressionTrackingUrl: list<string>, kind: string, languages: list<string>, nativeAd: record<advertiser: string, appIcon: record<height: int, url: string, width: int>, body: string, callToAction: string, clickLinkUrl: string, clickTrackingUrl: string, headline: string, image: record<height: int, url: string, width: int>, impressionTrackingUrl: list<string>, logo: record<height: int, url: string, width: int>, price: string, starRating: float, videoURL: string>, openAuctionStatus: string, productCategories: list<int>, restrictedCategories: list<int>, sensitiveCategories: list<int>, servingRestrictions: table<contexts: list, disapprovalReasons: list, reason: string>, vendorType: list<int>, version: int, videoURL: string, videoVastXML: string, width: int>
# operationId: adexchangebuyer.creatives.get
export def "adexchangebuyer-creatives-get" [
  account_id: int
  buyer_creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/creatives/{accountId}/{buyerCreativeId}"
    path_params: [{name: accountId, var: account_id}, {name: buyerCreativeId, var: buyer_creative_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, buyer_creative_id: $buyer_creative_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a deal id association for the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/addDeal/{dealId}
# operationId: adexchangebuyer.creatives.addDeal
export def "adexchangebuyer-creatives-add-deal" [
  account_id: int
  buyer_creative_id: string
  deal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: post
    path: "/creatives/{accountId}/{buyerCreativeId}/addDeal/{dealId}"
    path_params: [{name: accountId, var: account_id}, {name: buyerCreativeId, var: buyer_creative_id}, {name: dealId, var: deal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, buyer_creative_id: $buyer_creative_id, deal_id: $deal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the external deal ids associated with the creative.
#
# GET /creatives/{accountId}/{buyerCreativeId}/listDeals
# Returns: record<dealStatuses: table<arcStatus: string, dealId: string, webPropertyId: int>, kind: string>
# operationId: adexchangebuyer.creatives.listDeals
export def "adexchangebuyer-creatives-list-deals" [
  account_id: int
  buyer_creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/creatives/{accountId}/{buyerCreativeId}/listDeals"
    path_params: [{name: accountId, var: account_id}, {name: buyerCreativeId, var: buyer_creative_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, buyer_creative_id: $buyer_creative_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a deal id associated with the creative.
#
# POST /creatives/{accountId}/{buyerCreativeId}/removeDeal/{dealId}
# operationId: adexchangebuyer.creatives.removeDeal
export def "adexchangebuyer-creatives-remove-deal" [
  account_id: int
  buyer_creative_id: string
  deal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: post
    path: "/creatives/{accountId}/{buyerCreativeId}/removeDeal/{dealId}"
    path_params: [{name: accountId, var: account_id}, {name: buyerCreativeId, var: buyer_creative_id}, {name: dealId, var: deal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, buyer_creative_id: $buyer_creative_id, deal_id: $deal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the authenticated user's list of performance metrics.
#
# GET /performancereport
# Returns: record<kind: string, performanceReport: table<bidRate: float, bidRequestRate: float, calloutStatusRate: list, cookieMatcherStatusRate: list, creativeStatusRate: list, filteredBidRate: float, hostedMatchStatusRate: list, inventoryMatchRate: float, kind: string, latency50thPercentile: float, latency85thPercentile: float, latency95thPercentile: float, noQuotaInRegion: float, outOfQuota: float, pixelMatchRequests: float, pixelMatchResponses: float, quotaConfiguredLimit: float, quotaThrottledLimit: float, region: string, successfulRequestRate: float, timestamp: string, unsuccessfulRequestRate: float>>
# operationId: adexchangebuyer.performanceReport.list
export def "adexchangebuyer-performance-report-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-id: string # The account id to get the reports. (required)
  --end-date-time: string # The end time of the report in ISO 8601 timestamp format using UTC. (required)
  --start-date-time: string # The start time of the report in ISO 8601 timestamp format using UTC. (required)
  --max-results: int # Maximum number of entries returned on one result page. If not set, the default is 100. Optional.
  --page-token: string # A continuation token, used to page through performance reports. To retrieve the next page, set this parameter to the value of "nextPageToken" from the previous response. Optional.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/performancereport"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: accountId, var: account_id, required: true}, {name: endDateTime, var: end_date_time, required: true}, {name: startDateTime, var: start_date_time, required: true}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, account_id: $account_id, end_date_time: $end_date_time, start_date_time: $start_date_time, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of the authenticated user's pretargeting configurations.
#
# GET /pretargetingconfigs/{accountId}
# Returns: record<items: table<billingId: string, configId: string, configName: string, creativeType: list, dimensions: list, excludedContentLabels: list, excludedGeoCriteriaIds: list, excludedPlacements: list, excludedUserLists: list, excludedVerticals: list, geoCriteriaIds: list, isActive: bool, kind: string, languages: list, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list, mobileDevices: list, mobileOperatingSystemVersions: list, placements: list, platforms: list, supportedCreativeAttributes: list, userIdentifierDataRequired: list, userLists: list, vendorTypes: list, verticals: list, videoPlayerSizes: list>, kind: string>
# operationId: adexchangebuyer.pretargetingConfig.list
export def "adexchangebuyer-pretargeting-config-list" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pretargetingconfigs/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new pretargeting configuration.
#
# POST /pretargetingconfigs/{accountId}
# Returns: record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>
# operationId: adexchangebuyer.pretargetingConfig.insert
export def "adexchangebuyer-pretargeting-config-insert" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pretargetingconfigs/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingId, var: billing_id}, {name: configId, var: config_id}, {name: configName, var: config_name}, {name: creativeType, var: creative_type}, {name: dimensions, var: dimensions}, {name: excludedContentLabels, var: excluded_content_labels}, {name: excludedGeoCriteriaIds, var: excluded_geo_criteria_ids}, {name: excludedPlacements, var: excluded_placements}, {name: excludedUserLists, var: excluded_user_lists}, {name: excludedVerticals, var: excluded_verticals}, {name: geoCriteriaIds, var: geo_criteria_ids}, {name: isActive, var: is_active}, {name: kind, var: kind}, {name: languages, var: languages}, {name: maximumQps, var: maximum_qps}, {name: minimumViewabilityDecile, var: minimum_viewability_decile}, {name: mobileCarriers, var: mobile_carriers}, {name: mobileDevices, var: mobile_devices}, {name: mobileOperatingSystemVersions, var: mobile_operating_system_versions}, {name: placements, var: placements}, {name: platforms, var: platforms}, {name: supportedCreativeAttributes, var: supported_creative_attributes}, {name: userIdentifierDataRequired, var: user_identifier_data_required}, {name: userLists, var: user_lists}, {name: vendorTypes, var: vendor_types}, {name: verticals, var: verticals}, {name: videoPlayerSizes, var: video_player_sizes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, billing_id: $billing_id, config_id: $config_id, config_name: $config_name, creative_type: $creative_type, dimensions: $dimensions, excluded_content_labels: $excluded_content_labels, excluded_geo_criteria_ids: $excluded_geo_criteria_ids, excluded_placements: $excluded_placements, excluded_user_lists: $excluded_user_lists, excluded_verticals: $excluded_verticals, geo_criteria_ids: $geo_criteria_ids, is_active: $is_active, kind: $kind, languages: $languages, maximum_qps: $maximum_qps, minimum_viewability_decile: $minimum_viewability_decile, mobile_carriers: $mobile_carriers, mobile_devices: $mobile_devices, mobile_operating_system_versions: $mobile_operating_system_versions, placements: $placements, platforms: $platforms, supported_creative_attributes: $supported_creative_attributes, user_identifier_data_required: $user_identifier_data_required, user_lists: $user_lists, vendor_types: $vendor_types, verticals: $verticals, video_player_sizes: $video_player_sizes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing pretargeting config.
#
# DELETE /pretargetingconfigs/{accountId}/{configId}
# operationId: adexchangebuyer.pretargetingConfig.delete
export def "adexchangebuyer-pretargeting-config-delete" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/pretargetingconfigs/{accountId}/{configId}"
    path_params: [{name: accountId, var: account_id}, {name: configId, var: config_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, config_id: $config_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific pretargeting configuration
#
# GET /pretargetingconfigs/{accountId}/{configId}
# Returns: record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>
# operationId: adexchangebuyer.pretargetingConfig.get
export def "adexchangebuyer-pretargeting-config-get" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pretargetingconfigs/{accountId}/{configId}"
    path_params: [{name: accountId, var: account_id}, {name: configId, var: config_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, config_id: $config_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing pretargeting config. This method supports patch semantics.
#
# PATCH /pretargetingconfigs/{accountId}/{configId}
# Returns: record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>
# operationId: adexchangebuyer.pretargetingConfig.patch
export def "adexchangebuyer-pretargeting-config-patch" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64) (spec name: configId)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pretargetingconfigs/{accountId}/{configId}"
    path_params: [{name: accountId, var: account_id}, {name: configId, var: config_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingId, var: billing_id}, {name: configId, var: body_config_id}, {name: configName, var: config_name}, {name: creativeType, var: creative_type}, {name: dimensions, var: dimensions}, {name: excludedContentLabels, var: excluded_content_labels}, {name: excludedGeoCriteriaIds, var: excluded_geo_criteria_ids}, {name: excludedPlacements, var: excluded_placements}, {name: excludedUserLists, var: excluded_user_lists}, {name: excludedVerticals, var: excluded_verticals}, {name: geoCriteriaIds, var: geo_criteria_ids}, {name: isActive, var: is_active}, {name: kind, var: kind}, {name: languages, var: languages}, {name: maximumQps, var: maximum_qps}, {name: minimumViewabilityDecile, var: minimum_viewability_decile}, {name: mobileCarriers, var: mobile_carriers}, {name: mobileDevices, var: mobile_devices}, {name: mobileOperatingSystemVersions, var: mobile_operating_system_versions}, {name: placements, var: placements}, {name: platforms, var: platforms}, {name: supportedCreativeAttributes, var: supported_creative_attributes}, {name: userIdentifierDataRequired, var: user_identifier_data_required}, {name: userLists, var: user_lists}, {name: vendorTypes, var: vendor_types}, {name: verticals, var: verticals}, {name: videoPlayerSizes, var: video_player_sizes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, config_id: $config_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, billing_id: $billing_id, body_config_id: $body_config_id, config_name: $config_name, creative_type: $creative_type, dimensions: $dimensions, excluded_content_labels: $excluded_content_labels, excluded_geo_criteria_ids: $excluded_geo_criteria_ids, excluded_placements: $excluded_placements, excluded_user_lists: $excluded_user_lists, excluded_verticals: $excluded_verticals, geo_criteria_ids: $geo_criteria_ids, is_active: $is_active, kind: $kind, languages: $languages, maximum_qps: $maximum_qps, minimum_viewability_decile: $minimum_viewability_decile, mobile_carriers: $mobile_carriers, mobile_devices: $mobile_devices, mobile_operating_system_versions: $mobile_operating_system_versions, placements: $placements, platforms: $platforms, supported_creative_attributes: $supported_creative_attributes, user_identifier_data_required: $user_identifier_data_required, user_lists: $user_lists, vendor_types: $vendor_types, verticals: $verticals, video_player_sizes: $video_player_sizes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing pretargeting config.
#
# PUT /pretargetingconfigs/{accountId}/{configId}
# Returns: record<billingId: string, configId: string, configName: string, creativeType: list<string>, dimensions: table<height: string, width: string>, excludedContentLabels: list<string>, excludedGeoCriteriaIds: list<string>, excludedPlacements: table<token: string, type: string>, excludedUserLists: list<string>, excludedVerticals: list<string>, geoCriteriaIds: list<string>, isActive: bool, kind: string, languages: list<string>, maximumQps: string, minimumViewabilityDecile: int, mobileCarriers: list<string>, mobileDevices: list<string>, mobileOperatingSystemVersions: list<string>, placements: table<token: string, type: string>, platforms: list<string>, supportedCreativeAttributes: list<string>, userIdentifierDataRequired: list<string>, userLists: list<string>, vendorTypes: list<string>, verticals: list<string>, videoPlayerSizes: table<aspectRatio: string, minHeight: string, minWidth: string>>
# operationId: adexchangebuyer.pretargetingConfig.update
export def "adexchangebuyer-pretargeting-config-update" [
  account_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billing-id: string # The id for billing purposes, provided for reference. Leave this field blank for insert requests; the id will be generated automatically. (format: int64)
  --body-config-id: string # The config id; generated automatically. Leave this field blank for insert requests. (format: int64) (spec name: configId)
  --config-name: string # The name of the config. Must be unique. Required for all requests.
  --creative-type: list<string> # List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or PRETARGETING_CREATIVE_TYPE_VIDEO.
  --dimensions: list # Requests which allow one of these (width, height) pairs will match. All pairs must be supported ad dimensions. — item shape: {height?: string, width?: string}
  --excluded-content-labels: list<string> # Requests with any of these content labels will not match. Values are from content-labels.txt in the downloadable files section.
  --excluded-geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will not match.
  --excluded-placements: list # Requests containing any of these placements will not match. — item shape: {token?: string, type?: string}
  --excluded-user-lists: list<string> # Requests containing any of these users list ids will not match.
  --excluded-verticals: list<string> # Requests containing any of these vertical ids will not match. Values are from the publisher-verticals.txt file in the downloadable files section.
  --geo-criteria-ids: list<string> # Requests containing any of these geo criteria ids will match.
  --is-active: oneof<nothing, bool> # Whether this config is active. Required for all requests.
  --kind: string # The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig". (default: adexchangebuyer#pretargetingConfig)
  --languages: list<string> # Request containing any of these language codes will match.
  --maximum-qps: string # The maximum QPS allocated to this pretargeting configuration, used for pretargeting-level QPS limits. By default, this is not set, which indicates that there is no QPS limit at the configuration level (a global or account-level limit may still be imposed). (format: int64)
  --minimum-viewability-decile: int # Requests where the predicted viewability is below the specified decile will not match. E.g. if the buyer sets this value to 5, requests from slots where the predicted viewability is below 50% will not match. If the predicted viewability is unknown this field will be ignored. (format: int32)
  --mobile-carriers: list<string> # Requests containing any of these mobile carrier ids will match. Values are from mobile-carriers.csv in the downloadable files section.
  --mobile-devices: list<string> # Requests containing any of these mobile device ids will match. Values are from mobile-devices.csv in the downloadable files section.
  --mobile-operating-system-versions: list<string> # Requests containing any of these mobile operating system version ids will match. Values are from mobile-os.csv in the downloadable files section.
  --placements: list # Requests containing any of these placements will match. — item shape: {token?: string, type?: string}
  --platforms: list<string> # Requests matching any of these platforms will match. Possible values are PRETARGETING_PLATFORM_MOBILE, PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  --supported-creative-attributes: list<string> # Creative attributes should be declared here if all creatives corresponding to this pretargeting configuration have that creative attribute. Values are from pretargetable-creative-attributes.txt in the downloadable files section.
  --user-identifier-data-required: list<string> # Requests containing the specified type of user data will match. Possible values are HOSTED_MATCH_DATA, which means the request is cookie-targetable and has a match in the buyer's hosted match table, and COOKIE_OR_IDFA, which means the request has either a targetable cookie or an iOS IDFA.
  --user-lists: list<string> # Requests containing any of these user list ids will match.
  --vendor-types: list<string> # Requests that allow any of these vendor ids will match. Values are from vendors.txt in the downloadable files section.
  --verticals: list<string> # Requests containing any of these vertical ids will match.
  --video-player-sizes: list # Video requests satisfying any of these player size constraints will match. — item shape: {aspectRatio?: string, minHeight?: string, minWidth?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/pretargetingconfigs/{accountId}/{configId}"
    path_params: [{name: accountId, var: account_id}, {name: configId, var: config_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingId, var: billing_id}, {name: configId, var: body_config_id}, {name: configName, var: config_name}, {name: creativeType, var: creative_type}, {name: dimensions, var: dimensions}, {name: excludedContentLabels, var: excluded_content_labels}, {name: excludedGeoCriteriaIds, var: excluded_geo_criteria_ids}, {name: excludedPlacements, var: excluded_placements}, {name: excludedUserLists, var: excluded_user_lists}, {name: excludedVerticals, var: excluded_verticals}, {name: geoCriteriaIds, var: geo_criteria_ids}, {name: isActive, var: is_active}, {name: kind, var: kind}, {name: languages, var: languages}, {name: maximumQps, var: maximum_qps}, {name: minimumViewabilityDecile, var: minimum_viewability_decile}, {name: mobileCarriers, var: mobile_carriers}, {name: mobileDevices, var: mobile_devices}, {name: mobileOperatingSystemVersions, var: mobile_operating_system_versions}, {name: placements, var: placements}, {name: platforms, var: platforms}, {name: supportedCreativeAttributes, var: supported_creative_attributes}, {name: userIdentifierDataRequired, var: user_identifier_data_required}, {name: userLists, var: user_lists}, {name: vendorTypes, var: vendor_types}, {name: verticals, var: verticals}, {name: videoPlayerSizes, var: video_player_sizes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, config_id: $config_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, billing_id: $billing_id, body_config_id: $body_config_id, config_name: $config_name, creative_type: $creative_type, dimensions: $dimensions, excluded_content_labels: $excluded_content_labels, excluded_geo_criteria_ids: $excluded_geo_criteria_ids, excluded_placements: $excluded_placements, excluded_user_lists: $excluded_user_lists, excluded_verticals: $excluded_verticals, geo_criteria_ids: $geo_criteria_ids, is_active: $is_active, kind: $kind, languages: $languages, maximum_qps: $maximum_qps, minimum_viewability_decile: $minimum_viewability_decile, mobile_carriers: $mobile_carriers, mobile_devices: $mobile_devices, mobile_operating_system_versions: $mobile_operating_system_versions, placements: $placements, platforms: $platforms, supported_creative_attributes: $supported_creative_attributes, user_identifier_data_required: $user_identifier_data_required, user_lists: $user_lists, vendor_types: $vendor_types, verticals: $verticals, video_player_sizes: $video_player_sizes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a given private auction proposal
#
# POST /privateauction/{privateAuctionId}/updateproposal
# operationId: adexchangebuyer.marketplaceprivateauction.updateproposal
export def "adexchangebuyer-marketplaceprivateauction-updateproposal" [
  private_auction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --external-deal-id: string # The externalDealId of the deal to be updated.
  --note: record # A proposal is associated with a bunch of notes which may optionally be associated with a deal and/or revision number. — shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
  --proposal-revision-number: string # The current revision number of the proposal to be updated. (format: int64)
  --update-action: string # The proposed action on the private auction proposal.
]: any -> any {
  $in | http-request {
    method: post
    path: "/privateauction/{privateAuctionId}/updateproposal"
    path_params: [{name: privateAuctionId, var: private_auction_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalDealId, var: external_deal_id}, {name: note, var: note}, {name: proposalRevisionNumber, var: proposal_revision_number}, {name: updateAction, var: update_action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    private_auction_id: $private_auction_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, external_deal_id: $external_deal_id, note: $note, proposal_revision_number: $proposal_revision_number, update_action: $update_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested product.
#
# GET /products/search
# Returns: record<products: table<billedBuyer: record, buyer: record, creationTimeMs: string, creatorContacts: list, creatorRole: string, deliveryControl: record, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: list, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record, revisionNumber: string, seller: record, sharedTargetings: list, state: string, syndicationProduct: string, terms: record, webPropertyCode: string>>
# operationId: adexchangebuyer.products.search
export def "adexchangebuyer-products-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # The pql query used to query for products.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/search"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pqlQuery, var: pql_query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, pql_query: $pql_query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested product by id.
#
# GET /products/{productId}
# Returns: record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, creationTimeMs: string, creatorContacts: table<email: string, name: string>, creatorRole: string, deliveryControl: record<creativeBlockingLevel: string, deliveryRateType: string, frequencyCaps: list<record>>, flightEndTimeMs: string, flightStartTimeMs: string, hasCreatorSignedOff: bool, inventorySource: string, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdateTimeMs: string, legacyOfferId: string, marketplacePublisherProfileId: string, name: string, privateAuctionId: string, productId: string, publisherProfileId: string, publisherProvidedForecast: record<dimensions: list<record>, weeklyImpressions: string, weeklyUniques: string>, revisionNumber: string, seller: record<accountId: string, subAccountId: string>, sharedTargetings: table<exclusions: list, inclusions: list, key: string>, state: string, syndicationProduct: string, terms: record<brandingType: string, crossListedExternalDealIdType: string, description: string, estimatedGrossSpend: record<amountMicros: float, currencyCode: string, expectedCpmMicros: float, pricingType: string>, estimatedImpressionsPerDay: string, guaranteedFixedPriceTerms: record<billingInfo: record, fixedPrices: list, guaranteedImpressions: string, guaranteedLooks: string, minimumDailyLooks: string>, nonGuaranteedAuctionTerms: record<autoOptimizePrivateAuction: bool, reservePricePerBuyers: list>, nonGuaranteedFixedPriceTerms: record<fixedPrices: list>, rubiconNonGuaranteedTerms: record<priorityPrice: record, standardPrice: record>, sellerTimeZone: string>, webPropertyCode: string>
# operationId: adexchangebuyer.products.get
export def "adexchangebuyer-products-get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{productId}"
    path_params: [{name: productId, var: product_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    product_id: $product_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create the given list of proposals
#
# POST /proposals/insert
# Returns: record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>>
# operationId: adexchangebuyer.proposals.insert
export def "adexchangebuyer-proposals-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --proposals: list # The list of proposals to create. — item shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
  --web-property-code: string # Web property id of the seller creating these orders
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proposals/insert"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: proposals, var: proposals}, {name: webPropertyCode, var: web_property_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, proposals: $proposals, web_property_code: $web_property_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for proposals using pql query
#
# GET /proposals/search
# Returns: record<proposals: table<billedBuyer: record, buyer: record, buyerContacts: list, buyerPrivateData: record, dbmAdvertiserIds: list, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: list, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record, sellerContacts: list>>
# operationId: adexchangebuyer.proposals.search
export def "adexchangebuyer-proposals-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific proposals.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/proposals/search"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pqlQuery, var: pql_query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, pql_query: $pql_query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a proposal given its id
#
# GET /proposals/{proposalId}
# Returns: record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>
# operationId: adexchangebuyer.proposals.get
export def "adexchangebuyer-proposals-get" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/proposals/{proposalId}"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the deals for a given proposal
#
# GET /proposals/{proposalId}/deals
# Returns: record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>>
# operationId: adexchangebuyer.marketplacedeals.list
export def "adexchangebuyer-marketplacedeals-list" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific deals.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/proposals/{proposalId}/deals"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pqlQuery, var: pql_query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, pql_query: $pql_query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the specified deals from the proposal
#
# POST /proposals/{proposalId}/deals/delete
# Returns: record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string>
# operationId: adexchangebuyer.marketplacedeals.delete
export def "adexchangebuyer-marketplacedeals-delete" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deal-ids: list<string> # List of deals to delete for a given proposal
  --proposal-revision-number: string # The last known proposal revision number. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proposals/{proposalId}/deals/delete"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: dealIds, var: deal_ids}, {name: proposalRevisionNumber, var: proposal_revision_number}, {name: updateAction, var: update_action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, deal_ids: $deal_ids, proposal_revision_number: $proposal_revision_number, update_action: $update_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new deals for the specified proposal
#
# POST /proposals/{proposalId}/deals/insert
# Returns: record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, proposalRevisionNumber: string>
# operationId: adexchangebuyer.marketplacedeals.insert
export def "adexchangebuyer-marketplacedeals-insert" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deals: list # The list of deals to add — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
  --proposal-revision-number: string # The last known proposal revision number. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proposals/{proposalId}/deals/insert"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: deals, var: deals}, {name: proposalRevisionNumber, var: proposal_revision_number}, {name: updateAction, var: update_action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, deals: $deals, proposal_revision_number: $proposal_revision_number, update_action: $update_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces all the deals in the proposal with the passed in deals
#
# POST /proposals/{proposalId}/deals/update
# Returns: record<deals: table<buyerPrivateData: record, creationTimeMs: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, dealId: string, dealServingMetadata: record, deliveryControl: record, externalDealId: string, flightEndTimeMs: string, flightStartTimeMs: string, inventoryDescription: string, isRfpTemplate: bool, isSetupComplete: bool, kind: string, lastUpdateTimeMs: string, makegoodRequestedReason: string, name: string, productId: string, productRevisionNumber: string, programmaticCreativeSource: string, proposalId: string, sellerContacts: list, sharedTargetings: list, syndicationProduct: string, terms: record, webPropertyCode: string>, orderRevisionNumber: string>
# operationId: adexchangebuyer.marketplacedeals.update
export def "adexchangebuyer-marketplacedeals-update" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --deals: list # List of deals to edit. Service may perform 3 different operations based on comparison of deals in this list vs deals already persisted in database: 1. Add new deal to proposal If a deal in this list does not exist in the proposal, the service will create a new deal and add it to the proposal. Validation will follow AddOrderDealsRequest. 2. Update existing deal in the proposal If a deal in this list already exist in the proposal, the service will update that existing deal to this new deal in the request. Validation will follow UpdateOrderDealsRequest. 3. Delete deals from the proposal (just need the id) If a existing deal in the proposal is not present in this list, the service will delete that deal from the proposal. Validation will follow DeleteOrderDealsRequest. — item shape: {buyerPrivateData?: record, creationTimeMs?: string, creativePreApprovalPolicy?: string, creativeSafeFrameCompatibility?: string, dealId?: string, dealServingMetadata?: record, deliveryControl?: record, externalDealId?: string, flightEndTimeMs?: string, flightStartTimeMs?: string, inventoryDescription?: string, isRfpTemplate?: bool, isSetupComplete?: bool, kind?: string, lastUpdateTimeMs?: string, makegoodRequestedReason?: string, name?: string, productId?: string, productRevisionNumber?: string, ... (7 more fields)}
  --proposal: record # Represents a proposal in the marketplace. A proposal is the unit of negotiation between a seller and a buyer and contains deals which are served. Each field in a proposal can have one of the following setting: (readonly) - It is an error to try and set this field. (buyer-readonly) - Only the seller can set this field. (seller-readonly) - Only the buyer can set this field. (updatable) - The field is updatable at all times by either buyer or the seller. — shape: {billedBuyer?: record, buyer?: record, buyerContacts?: list, buyerPrivateData?: record, dbmAdvertiserIds?: list<string>, hasBuyerSignedOff?: bool, hasSellerSignedOff?: bool, inventorySource?: string, isRenegotiating?: bool, isSetupComplete?: bool, kind?: string, labels?: list, lastUpdaterOrCommentorRole?: string, name?: string, negotiationId?: string, originatorRole?: string, privateAuctionId?: string, proposalId?: string, proposalState?: string, revisionNumber?: string, revisionTimeMs?: string, ... (2 more fields)}
  --proposal-revision-number: string # The last known revision number for the proposal. (format: int64)
  --update-action: string # Indicates an optional action to take on the proposal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proposals/{proposalId}/deals/update"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: deals, var: deals}, {name: proposal, var: proposal}, {name: proposalRevisionNumber, var: proposal_revision_number}, {name: updateAction, var: update_action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, deals: $deals, proposal: $proposal, proposal_revision_number: $proposal_revision_number, update_action: $update_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the notes associated with a proposal
#
# GET /proposals/{proposalId}/notes
# Returns: record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>>
# operationId: adexchangebuyer.marketplacenotes.list
export def "adexchangebuyer-marketplacenotes-list" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --pql-query: string # Query string to retrieve specific notes. To search the text contents of notes, please use syntax like "WHERE note.note = "foo" or "WHERE note.note LIKE "%bar%"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/proposals/{proposalId}/notes"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pqlQuery, var: pql_query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, pql_query: $pql_query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add notes to the proposal
#
# POST /proposals/{proposalId}/notes/insert
# Returns: record<notes: table<creatorRole: string, dealId: string, kind: string, note: string, noteId: string, proposalId: string, proposalRevisionNumber: string, timestampMs: string>>
# operationId: adexchangebuyer.marketplacenotes.insert
export def "adexchangebuyer-marketplacenotes-insert" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --notes: list # The list of notes to add. — item shape: {creatorRole?: string, dealId?: string, kind?: string, note?: string, noteId?: string, proposalId?: string, proposalRevisionNumber?: string, timestampMs?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/proposals/{proposalId}/notes/insert"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given proposal to indicate that setup has been completed.
#
# POST /proposals/{proposalId}/setupcomplete
# operationId: adexchangebuyer.proposals.setupcomplete
export def "adexchangebuyer-proposals-setupcomplete" [
  proposal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: post
    path: "/proposals/{proposalId}/setupcomplete"
    path_params: [{name: proposalId, var: proposal_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given proposal. This method supports patch semantics.
#
# PATCH /proposals/{proposalId}/{revisionNumber}/{updateAction}
# Returns: record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>
# operationId: adexchangebuyer.proposals.patch
export def "adexchangebuyer-proposals-patch" [
  proposal_id: string
  revision_number: string
  update_action: string@update-action-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billed-buyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyer-contacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyer-private-data: record # shape: {referenceId?: string, referencePayload?: string}
  --dbm-advertiser-ids: list<string> # IDs of DBM advertisers permission to this proposal.
  --has-buyer-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --has-seller-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventory-source: string # What exchange will provide this inventory (readonly, except on create).
  --is-renegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --is-setup-complete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --last-updater-or-commentor-role: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiation-id: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originator-role: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --private-auction-id: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposal-id: string # The unique id of the proposal. (readonly). (spec name: proposalId)
  --proposal-state: string # The current state of the proposal. (readonly)
  --body-revision-number: string # The revision number for the proposal (readonly). (format: int64) (spec name: revisionNumber)
  --revision-time-ms: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --seller-contacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/proposals/{proposalId}/{revisionNumber}/{updateAction}"
    path_params: [{name: proposalId, var: proposal_id}, {name: revisionNumber, var: revision_number}, {name: updateAction, var: update_action}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: billedBuyer, var: billed_buyer}, {name: buyer, var: buyer}, {name: buyerContacts, var: buyer_contacts}, {name: buyerPrivateData, var: buyer_private_data}, {name: dbmAdvertiserIds, var: dbm_advertiser_ids}, {name: hasBuyerSignedOff, var: has_buyer_signed_off}, {name: hasSellerSignedOff, var: has_seller_signed_off}, {name: inventorySource, var: inventory_source}, {name: isRenegotiating, var: is_renegotiating}, {name: isSetupComplete, var: is_setup_complete}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastUpdaterOrCommentorRole, var: last_updater_or_commentor_role}, {name: name, var: name}, {name: negotiationId, var: negotiation_id}, {name: originatorRole, var: originator_role}, {name: privateAuctionId, var: private_auction_id}, {name: proposalId, var: body_proposal_id}, {name: proposalState, var: proposal_state}, {name: revisionNumber, var: body_revision_number}, {name: revisionTimeMs, var: revision_time_ms}, {name: seller, var: seller}, {name: sellerContacts, var: seller_contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, revision_number: $revision_number, update_action: $update_action, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, billed_buyer: $billed_buyer, buyer: $buyer, buyer_contacts: $buyer_contacts, buyer_private_data: $buyer_private_data, dbm_advertiser_ids: $dbm_advertiser_ids, has_buyer_signed_off: $has_buyer_signed_off, has_seller_signed_off: $has_seller_signed_off, inventory_source: $inventory_source, is_renegotiating: $is_renegotiating, is_setup_complete: $is_setup_complete, kind: $kind, labels: $labels, last_updater_or_commentor_role: $last_updater_or_commentor_role, name: $name, negotiation_id: $negotiation_id, originator_role: $originator_role, private_auction_id: $private_auction_id, body_proposal_id: $body_proposal_id, proposal_state: $proposal_state, body_revision_number: $body_revision_number, revision_time_ms: $revision_time_ms, seller: $seller, seller_contacts: $seller_contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the given proposal
#
# PUT /proposals/{proposalId}/{revisionNumber}/{updateAction}
# Returns: record<billedBuyer: record<accountId: string>, buyer: record<accountId: string>, buyerContacts: table<email: string, name: string>, buyerPrivateData: record<referenceId: string, referencePayload: string>, dbmAdvertiserIds: list<string>, hasBuyerSignedOff: bool, hasSellerSignedOff: bool, inventorySource: string, isRenegotiating: bool, isSetupComplete: bool, kind: string, labels: table<accountId: string, createTimeMs: string, deprecatedMarketplaceDealParty: record, label: string>, lastUpdaterOrCommentorRole: string, name: string, negotiationId: string, originatorRole: string, privateAuctionId: string, proposalId: string, proposalState: string, revisionNumber: string, revisionTimeMs: string, seller: record<accountId: string, subAccountId: string>, sellerContacts: table<email: string, name: string>>
# operationId: adexchangebuyer.proposals.update
export def "adexchangebuyer-proposals-update" [
  proposal_id: string
  revision_number: string
  update_action: string@update-action-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --billed-buyer: record # shape: {accountId?: string}
  --buyer: record # shape: {accountId?: string}
  --buyer-contacts: list # Optional contact information of the buyer. (seller-readonly) — item shape: {email?: string, name?: string}
  --buyer-private-data: record # shape: {referenceId?: string, referencePayload?: string}
  --dbm-advertiser-ids: list<string> # IDs of DBM advertisers permission to this proposal.
  --has-buyer-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off. Once both sides have signed off on a deal, the proposal can be finalized by the seller. (seller-readonly)
  --has-seller-signed-off: oneof<nothing, bool> # When an proposal is in an accepted state, indicates whether the buyer has signed off Once both sides have signed off on a deal, the proposal can be finalized by the seller. (buyer-readonly)
  --inventory-source: string # What exchange will provide this inventory (readonly, except on create).
  --is-renegotiating: oneof<nothing, bool> # True if the proposal is being renegotiated (readonly).
  --is-setup-complete: oneof<nothing, bool> # True, if the buyside inventory setup is complete for this proposal. (readonly, except via OrderSetupCompleted action) Deprecated in favor of deal level setup complete flag.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "adexchangebuyer#proposal". (default: adexchangebuyer#proposal)
  --labels: list # List of labels associated with the proposal. (readonly) — item shape: {accountId?: string, createTimeMs?: string, deprecatedMarketplaceDealParty?: record, label?: string}
  --last-updater-or-commentor-role: string # The role of the last user that either updated the proposal or left a comment. (readonly)
  --name: string # The name for the proposal (updatable)
  --negotiation-id: string # Optional negotiation id if this proposal is a preferred deal proposal.
  --originator-role: string # Indicates whether the buyer/seller created the proposal.(readonly)
  --private-auction-id: string # Optional private auction id if this proposal is a private auction proposal.
  --body-proposal-id: string # The unique id of the proposal. (readonly). (spec name: proposalId)
  --proposal-state: string # The current state of the proposal. (readonly)
  --body-revision-number: string # The revision number for the proposal (readonly). (format: int64) (spec name: revisionNumber)
  --revision-time-ms: string # The time (ms since epoch) when the proposal was last revised (readonly). (format: int64)
  --seller: record # shape: {accountId?: string, subAccountId?: string}
  --seller-contacts: list # Optional contact information of the seller (buyer-readonly). — item shape: {email?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/proposals/{proposalId}/{revisionNumber}/{updateAction}"
    path_params: [{name: proposalId, var: proposal_id}, {name: revisionNumber, var: revision_number}, {name: updateAction, var: update_action}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: billedBuyer, var: billed_buyer}, {name: buyer, var: buyer}, {name: buyerContacts, var: buyer_contacts}, {name: buyerPrivateData, var: buyer_private_data}, {name: dbmAdvertiserIds, var: dbm_advertiser_ids}, {name: hasBuyerSignedOff, var: has_buyer_signed_off}, {name: hasSellerSignedOff, var: has_seller_signed_off}, {name: inventorySource, var: inventory_source}, {name: isRenegotiating, var: is_renegotiating}, {name: isSetupComplete, var: is_setup_complete}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastUpdaterOrCommentorRole, var: last_updater_or_commentor_role}, {name: name, var: name}, {name: negotiationId, var: negotiation_id}, {name: originatorRole, var: originator_role}, {name: privateAuctionId, var: private_auction_id}, {name: proposalId, var: body_proposal_id}, {name: proposalState, var: proposal_state}, {name: revisionNumber, var: body_revision_number}, {name: revisionTimeMs, var: revision_time_ms}, {name: seller, var: seller}, {name: sellerContacts, var: seller_contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal_id: $proposal_id, revision_number: $revision_number, update_action: $update_action, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, billed_buyer: $billed_buyer, buyer: $buyer, buyer_contacts: $buyer_contacts, buyer_private_data: $buyer_private_data, dbm_advertiser_ids: $dbm_advertiser_ids, has_buyer_signed_off: $has_buyer_signed_off, has_seller_signed_off: $has_seller_signed_off, inventory_source: $inventory_source, is_renegotiating: $is_renegotiating, is_setup_complete: $is_setup_complete, kind: $kind, labels: $labels, last_updater_or_commentor_role: $last_updater_or_commentor_role, name: $name, negotiation_id: $negotiation_id, originator_role: $originator_role, private_auction_id: $private_auction_id, body_proposal_id: $body_proposal_id, proposal_state: $proposal_state, body_revision_number: $body_revision_number, revision_time_ms: $revision_time_ms, seller: $seller, seller_contacts: $seller_contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested publisher profile(s) by publisher accountId.
#
# GET /publisher/{accountId}/profiles
# Returns: record<profiles: table<audience: string, buyerPitchStatement: string, directContact: string, exchange: string, forecastInventory: string, googlePlusLink: string, isParent: bool, isPublished: bool, kind: string, logoUrl: string, mediaKitLink: string, name: string, overview: string, profileId: int, programmaticContact: string, publisherAppIds: list, publisherApps: list, publisherDomains: list, publisherProfileId: string, publisherProvidedForecast: record, rateCardInfoLink: string, samplePageLink: string, seller: record, state: string, topHeadlines: list>>
# operationId: adexchangebuyer.pubprofiles.list
export def "adexchangebuyer-pubprofiles-list" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/publisher/{accountId}/profiles"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
