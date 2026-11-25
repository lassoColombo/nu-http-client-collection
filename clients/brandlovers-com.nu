# Auto-generated client for BrandLovers Marketplace API V1 v1.0.0
# Source: https://api.apis.guru/v2/specs/brandlovers.com/1.0.0/swagger.json
# Auth: --token flag or $env.BRANDLOVERS_MARKETPLACE_API_V1_TOKEN

const CLIENT = {
  base_url: "https://api.brandlovers.com/marketplace/v1"
  token_env_var: "BRANDLOVERS_MARKETPLACE_API_V1_TOKEN"
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

def base-url-completer [] { ["https://api.brandlovers.com/marketplace/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["APPROVED" "DECLINED" "NEW" "PENDING"] }
def status-completer-1 [] { ["CLOSED" "OPEN" "REOPENED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-order-order-id: "record<approvedAt: string, billingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, createdAt: string, customer: record<documentNumber: string, email: string, id: string, name: string, phones: list<record>, type: string>, freight: record<ETA: string, additionalInfo: string, chargedAmount: int, crossDockingTime: int, defaultAmount: int, scheduledPeriod: string, transitTime: int, type: string>, items: table<freight: record, giftWrap: record, id: string, name: string, promotions: list, salePrice: int, sent: bool, skuSellerId: string>, orderId: string, orderMarketplaceId: string, seller: record<id: string, name: string>, shipments: table<courier: record, cte: string, description: string, id: string, invoice: record, items: list, number: string, occurredAt: string, sellerShipmentId: string, status: string, trackingUrl: string>, shippingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>"
    get-orders: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-shipments-delivered: "record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>>"
    get-orders-shipments-shipped: "record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>>"
    get-orders-status-approved: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-canceled: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-delivered: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-new: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-partially-delivered: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-partially-sent: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-orders-status-sent: "record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>"
    get-product-sku-seller-id: "record<attributes: table<name: string, value: string>, brand: string, categories: list<string>, description: string, dimensions: record<height: int, length: int, weight: int, width: int>, errors: table<message: string, skuSellerId: string, type: string>, giftWrap: record<available: bool, messageSupport: bool, value: int>, gtin: list<string>, images: list<string>, price: record<default: int, offer: int>, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list<string>>"
    get-products: "record<metadata: table<key: string, value: string>, skus: table<attributes: list, brand: string, categories: list, description: string, dimensions: record, errors: list, giftWrap: record, gtin: list, images: list, price: record, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list>>"
    get-products-status: "record<metadata: table<key: string, value: string>, skus: table<errors: list, price: record, skuSellerId: string, status: string, stock: int>>"
    get-products-status-selling: "record<metadata: table<key: string, value: string>, sellerItems: table<attributes: list, brand: string, dimensions: record, giftWrap: record, gtin: list, images: list, prices: list, product: record, skuSellerId: string, status: list, stocks: list, title: string, urls: list>>"
    get-ticket-ticket-id-messages: "record<messages: table<body: string, createdAt: string, id: string, visibility: string>, metadata: table<key: string, value: string>>"
    get-tickets: "record<metadata: table<key: string, value: string>, tickets: table<closedAt: string, createdAt: string, customer: record, description: string, metadata: list, priority: string, sla: string, status: string, subject: string, ticketId: string, type: string, updatedAt: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-order-order-id" "post-order-order-id-shipment-cancel" "post-order-order-id-shipment-delivered" "post-order-order-id-shipment-exchange" "post-order-order-id-shipment-return" "post-order-order-id-shipment-sent" "get-orders" "get-orders-shipments-delivered" "post-orders-shipments-delivered" "get-orders-shipments-shipped" "post-orders-shipments-shipped" "get-orders-status-approved" "get-orders-status-canceled" "get-orders-status-delivered" "get-orders-status-new" "get-orders-status-partially-delivered" "get-orders-status-partially-sent" "get-orders-status-sent" "post-product" "get-product-sku-seller-id" "put-product-sku-seller-id" "put-product-sku-seller-id-prices" "put-product-sku-seller-id-status" "put-product-sku-seller-id-stock" "get-products" "post-products" "put-products-prices" "get-products-status" "put-products-status" "get-products-status-selling" "put-products-stocks" "post-ticket" "post-ticket-ticket-id-message" "get-ticket-ticket-id-messages" "put-ticket-ticket-id-status" "get-tickets" "commands"] | sort) } | get name | first)
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

# Returns all details of a order
#
# GET /order/{orderId}
# Returns: record<approvedAt: string, billingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, createdAt: string, customer: record<documentNumber: string, email: string, id: string, name: string, phones: list<record>, type: string>, freight: record<ETA: string, additionalInfo: string, chargedAmount: int, crossDockingTime: int, defaultAmount: int, scheduledPeriod: string, transitTime: int, type: string>, items: table<freight: record, giftWrap: record, id: string, name: string, promotions: list, salePrice: int, sent: bool, skuSellerId: string>, orderId: string, orderMarketplaceId: string, seller: record<id: string, name: string>, shipments: table<courier: record, cte: string, description: string, id: string, invoice: record, items: list, number: string, occurredAt: string, sellerShipmentId: string, status: string, trackingUrl: string>, shippingAddress: record<address: string, city: string, complement: string, countryId: string, neighbourhood: string, number: string, recipientName: string, reference: string, state: string, zipCode: string>, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>
export def "get-order-order-id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm shipment canceletion (when requested by the customer) or failure to deliver
#
# POST /order/{orderId}/shipment/cancel
export def "post-order-order-id-shipment-cancel" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipment/cancel"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: cte, var: cte}, {name: info, var: info}, {name: items, var: items}, {name: number, var: number}, {name: occurredAt, var: occurred_at}, {name: sellerShipmentId, var: seller_shipment_id}, {name: tranckingUrl, var: trancking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization, courier: $courier, cte: $cte, info: $info, items: $items, number: $number, occurred_at: $occurred_at, seller_shipment_id: $seller_shipment_id, trancking_url: $trancking_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms that a shipment was delivered
#
# POST /order/{orderId}/shipment/delivered
export def "post-order-order-id-shipment-delivered" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  invoice: any # shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
  items: list<string> # List of Order IDs of this items from this order that will be updated in this shipment
  --number: string # Unique id shipment Id in the courier system
  occurred_at: string # Data da ocorrência (format: date-time)
  seller_shipment_id: string # Unique Seller shipment Id. This must be unique across all orders and shipmnents
  --tracking-url: string # Courier tracking URL
]: any -> any {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipment/delivered"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: cte, var: cte}, {name: invoice, var: invoice}, {name: items, var: items}, {name: number, var: number}, {name: occurredAt, var: occurred_at}, {name: sellerShipmentId, var: seller_shipment_id}, {name: trackingUrl, var: tracking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization, courier: $courier, cte: $cte, invoice: $invoice, items: $items, number: $number, occurred_at: $occurred_at, seller_shipment_id: $seller_shipment_id, tracking_url: $tracking_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm item exchange
#
# POST /order/{orderId}/shipment/exchange
export def "post-order-order-id-shipment-exchange" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipment/exchange"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: cte, var: cte}, {name: info, var: info}, {name: items, var: items}, {name: number, var: number}, {name: occurredAt, var: occurred_at}, {name: sellerShipmentId, var: seller_shipment_id}, {name: tranckingUrl, var: trancking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization, courier: $courier, cte: $cte, info: $info, items: $items, number: $number, occurred_at: $occurred_at, seller_shipment_id: $seller_shipment_id, trancking_url: $trancking_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm order item return and refund
#
# POST /order/{orderId}/shipment/return
export def "post-order-order-id-shipment-return" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  info: string # Aditional information about this shippment
  items: list # item shape: {quantity: int, skuSellerId: string}
  --number: string # Tracking Id in the courier
  --occurred-at: string # Date time that this was created (format: date-time)
  --seller-shipment-id: string # Unique Seller shipment Id. This must be unique across all orders and shipments
  --trancking-url: string # Courier tracking URL
]: any -> any {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipment/return"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: cte, var: cte}, {name: info, var: info}, {name: items, var: items}, {name: number, var: number}, {name: occurredAt, var: occurred_at}, {name: sellerShipmentId, var: seller_shipment_id}, {name: tranckingUrl, var: trancking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization, courier: $courier, cte: $cte, info: $info, items: $items, number: $number, occurred_at: $occurred_at, seller_shipment_id: $seller_shipment_id, trancking_url: $trancking_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update new order to include shipment information
#
# POST /order/{orderId}/shipment/sent
export def "post-order-order-id-shipment-sent" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  courier: any # shape: {name: string, taxID?: string}
  --cte: string # Conhecimento do Transporte Eletrônico
  invoice: any # shape: {accessKey: string, cnpj?: string, issuedAt?: string, linkDanfe?: string, linkXml?: string, number: string, serie: string}
  items: list<string> # List of Order IDs of this items from this order that will be updated in this shipment
  --number: string # Unique id shipment Id in the courier system
  occurred_at: string # Data da ocorrência (format: date-time)
  seller_shipment_id: string # Unique Seller shipment Id. This must be unique across all orders and shipmnents
  --tracking-url: string # Courier tracking URL
]: any -> any {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipment/sent"
    path_params: [{name: orderId, var: order_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: courier, var: courier}, {name: cte, var: cte}, {name: invoice, var: invoice}, {name: items, var: items}, {name: number, var: number}, {name: occurredAt, var: occurred_at}, {name: sellerShipmentId, var: seller_shipment_id}, {name: trackingUrl, var: tracking_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, authorization: $authorization, courier: $courier, cte: $cte, invoice: $invoice, items: $items, number: $number, occurred_at: $occurred_at, seller_shipment_id: $seller_shipment_id, tracking_url: $tracking_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns orders details
#
# GET /orders
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of shipments
#
# GET /orders/shipments/delivered
# Returns: record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>>
export def "get-orders-shipments-delivered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Query by shippment status.
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/shipments/delivered"
    query: [{name: status, var: status}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update of order shipments
#
# POST /orders/shipments/delivered
export def "post-orders-shipments-delivered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --shipments: list # item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/shipments/delivered"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shipments, var: shipments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, shipments: $shipments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of shipments shipped
#
# GET /orders/shipments/shipped
# Returns: record<metadata: table<key: string, value: string>, shipments: table<errors: list, items: list, shipmentId: string, status: string, trackingUrl: string>>
export def "get-orders-shipments-shipped" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Product status.
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/shipments/shipped"
    query: [{name: status, var: status}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk update of order shipments
#
# POST /orders/shipments/shipped
export def "post-orders-shipments-shipped" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shipments: list # item shape: {courier?: any, cte?: string, invoice?: any, items?: list, number?: string, occurredAt?: string, order?: string, sellerShipmentId?: string, status?: string, trackingUrl?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/shipments/shipped"
    body: {content_type: "application/json", kind: json, fields: [{name: shipments, var: shipments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shipments: $shipments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return list of approved orders
#
# GET /orders/status/approved
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-approved" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100, max 200. Use this in conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/approved"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns lists of canceled orders
#
# GET /orders/status/canceled
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-canceled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Default 100, max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/canceled"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of orders successfully delivered associated with this seller.
#
# GET /orders/status/delivered
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-delivered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/delivered"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of orders flagged as new.
#
# GET /orders/status/new
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/new"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of partially deliverd orders
#
# GET /orders/status/partiallyDelivered
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-partially-delivered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Max 250. Use this conjuction with `offset` to paginate across the results. (default: 100)
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/partiallyDelivered"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of orders partially fullfiled
#
# GET /orders/status/partiallySent
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-partially-sent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 100. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/partiallySent"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list with orders fully sent
#
# GET /orders/status/sent
# Returns: record<metadata: table<key: string, value: string>, orders: table<approvedAt: string, billingAddress: record, createdAt: string, customer: record, freight: record, items: list, orderId: string, orderMarketplaceId: string, seller: record, shipments: list, shippingAddress: record, status: string, totalAmount: int, totalDiscountAmount: int, totalItemsAmount: int, totalShippingAmount: int, updatedAt: string>>
export def "get-orders-status-sent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/sent"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product to the marketplace
#
# POST /product
export def "post-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  attributes: list # List of `key` `value` attributes of this product. This is very important for search and SEO optmization. Include all relevant information — item shape: {name: string, value: string}
  brand: string # Brand name
  categories: list<string> # Array of categories associated with this product
  description: string # Product description.
  --dimensions: any # shape: {height: int, length: int, weight: int, width: int}
  --gift-wrap: any # shape: {available: bool, messageSupport?: bool, value: int}
  --gtin: list<string> # Array of product EAN and/or ISBN and/or ASIN codes
  images: list<string> # List of valid Product image URLs. HTTP or HTTPS are valid. HTTPS is prefered.
  price: any # shape: {default: int, offer: int}
  --product-group-id: string # Unique Product Group ID. Products with the same `productGroupId` will be grouped and displayed as a unique entry. Use `productGroupId` to group diferent SKUs that represent diferent colors, sizes, capacities, etc..
  --product-id: string # Brand Lovers Product ID. Use this to suggest a product association. This field is optional.
  sku_seller_id: string # Unique Product Id (SKU) in the seller system
  stock: int # Number of products availble for sale from the seller. Each new successfull order will automatically reduce the number of products available.
  title: string # Product name as advertised by manufacturer. This how the product will be displayed in the Marketplace
  --videos: list<string> # List of videos de URLs associated with this product. HTTP or HTTPS are valid. HTTPS is prefered.
]: any -> any {
  $in | http-request {
    method: post
    path: "/product"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: brand, var: brand}, {name: categories, var: categories}, {name: description, var: description}, {name: dimensions, var: dimensions}, {name: giftWrap, var: gift_wrap}, {name: gtin, var: gtin}, {name: images, var: images}, {name: price, var: price}, {name: productGroupId, var: product_group_id}, {name: productId, var: product_id}, {name: skuSellerId, var: sku_seller_id}, {name: stock, var: stock}, {name: title, var: title}, {name: videos, var: videos}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, attributes: $attributes, brand: $brand, categories: $categories, description: $description, dimensions: $dimensions, gift_wrap: $gift_wrap, gtin: $gtin, images: $images, price: $price, product_group_id: $product_group_id, product_id: $product_id, sku_seller_id: $sku_seller_id, stock: $stock, title: $title, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of a single product using the seller `skuSellerId`
#
# GET /product/{skuSellerId}
# Returns: record<attributes: table<name: string, value: string>, brand: string, categories: list<string>, description: string, dimensions: record<height: int, length: int, weight: int, width: int>, errors: table<message: string, skuSellerId: string, type: string>, giftWrap: record<available: bool, messageSupport: bool, value: int>, gtin: list<string>, images: list<string>, price: record<default: int, offer: int>, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list<string>>
export def "get-product-sku-seller-id" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product/{skuSellerId}"
    path_params: [{name: skuSellerId, var: sku_seller_id}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sku_seller_id: $sku_seller_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update product details
#
# PUT /product/{skuSellerId}
export def "put-product-sku-seller-id" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --attributes: list # List of `key` `value` attributes of this product. This is very important for search and SEO optmization. Include all relevant information — item shape: {name: string, value: string}
  --brand: string # Brand name
  --categories: list<string> # Array of categories associated with this product
  --description: string # Product text description.
  --dimensions: any # shape: {height: int, length: int, weight: int, width: int}
  --gift-wrap: any # shape: {available: bool, messageSupport?: bool, value: int}
  --gtin: list<string> # Array of product EAN and/or ISBN and/or ASIN codes
  --images: list<string> # List of valid Product image URLs. HTTP or HTTPS are valid. HTTPS is prefered.
  --price: any # shape: {default: int, offer: int}
  --product-group-id: string # Unique Product Group ID. Products with the same `productGroupId` will be grouped and displayed as a unique entry. Use `productGroupId` to group diferent SKUs that represent diferent colors, sizes, capacities, etc..
  --product-id: string # Brand Lovers Product Id. Use this to recommend a product association
  --body-sku-seller-id: string # Unique Product Id (SKU) in the seller system (spec name: skuSellerId)
  --stock: int # Number of products availble for sale from the seller. Each new successfull order will automatically reduce the number of products available.
  --title: string # Product name as advertised by manufacturer. This how the product will be displayed in the Marketplace
  --videos: list<string> # List of videos de URLs associated with this product. HTTP or HTTPS are valid. HTTPS is prefered.
]: any -> any {
  $in | http-request {
    method: put
    path: "/product/{skuSellerId}"
    path_params: [{name: skuSellerId, var: sku_seller_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: brand, var: brand}, {name: categories, var: categories}, {name: description, var: description}, {name: dimensions, var: dimensions}, {name: giftWrap, var: gift_wrap}, {name: gtin, var: gtin}, {name: images, var: images}, {name: price, var: price}, {name: productGroupId, var: product_group_id}, {name: productId, var: product_id}, {name: skuSellerId, var: body_sku_seller_id, required: true}, {name: stock, var: stock}, {name: title, var: title}, {name: videos, var: videos}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sku_seller_id: $sku_seller_id, authorization: $authorization, attributes: $attributes, brand: $brand, categories: $categories, description: $description, dimensions: $dimensions, gift_wrap: $gift_wrap, gtin: $gtin, images: $images, price: $price, product_group_id: $product_group_id, product_id: $product_id, body_sku_seller_id: $body_sku_seller_id, stock: $stock, title: $title, videos: $videos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows seller to update prices of a single SKU
#
# PUT /product/{skuSellerId}/prices
export def "put-product-sku-seller-id-prices" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  default: int # List price, also known as MSRP (Manufacturer Suggest Retail Price) or the recommended retail price (RRP). All prices must be provided in cents. No commas or periods are accepeted. For example one dollar should be informed as 100. $1,2345.67 should be informed solely as 1234567
  offer: int # Product price. This is what will be offered to the customer. All prices must be provided in cents. No commas or periods are accepeted. For example one dollar should be informed as 100. $1,2345.67 should be informed solely as 1234567
]: any -> any {
  $in | http-request {
    method: put
    path: "/product/{skuSellerId}/prices"
    path_params: [{name: skuSellerId, var: sku_seller_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: offer, var: offer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sku_seller_id: $sku_seller_id, authorization: $authorization, default: $default, offer: $offer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/disable a single product in the Marketplace
#
# PUT /product/{skuSellerId}/status
export def "put-product-sku-seller-id-status" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --active: oneof<nothing, bool> # Defines if this product is ready for sale. Active `true`, disabled `false`
]: any -> any {
  $in | http-request {
    method: put
    path: "/product/{skuSellerId}/status"
    path_params: [{name: skuSellerId, var: sku_seller_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sku_seller_id: $sku_seller_id, authorization: $authorization, active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single product stock
#
# PUT /product/{skuSellerId}/stock
export def "put-product-sku-seller-id-stock" [
  sku_seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --cross-docking-time: int # Time it will take to manufacture, prepare or setup this product. Time must be provided in seconds. For example 1 day should be informed as 86400. This time will be included in the product ETA informed to the customer (default: 0)
  quantity: int # Stock available
]: any -> any {
  $in | http-request {
    method: put
    path: "/product/{skuSellerId}/stock"
    path_params: [{name: skuSellerId, var: sku_seller_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: crossDockingTime, var: cross_docking_time}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sku_seller_id: $sku_seller_id, authorization: $authorization, cross_docking_time: $cross_docking_time, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of products loaded into BrandLovers Marketplace
#
# GET /products
# Returns: record<metadata: table<key: string, value: string>, skus: table<attributes: list, brand: string, categories: list, description: string, dimensions: record, errors: list, giftWrap: record, gtin: list, images: list, price: record, productGroupId: string, skuSellerId: string, status: string, stock: int, title: string, videos: list>>
export def "get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number of items to retun. Defaults to 100. Max alowed is 200. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows new products from the seller to be loaded into the marketplace
#
# POST /products
export def "post-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/products"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows bulk update of product prices.
#
# PUT /products/prices
export def "put-products-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/products/prices"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns seller products status in the marketplace
#
# GET /products/status
# Returns: record<metadata: table<key: string, value: string>, skus: table<errors: list, price: record, skuSellerId: string, status: string, stock: int>>
export def "get-products-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number of items to return in this query. Defaults to 250. Maximum 1000. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/status"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk enable/disable products in the marketplace
#
# PUT /products/status
export def "put-products-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/products/status"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns products that are successfully listed for sale.
#
# GET /products/status/selling
# Returns: record<metadata: table<key: string, value: string>, sellerItems: table<attributes: list, brand: string, dimensions: record, giftWrap: record, gtin: list, images: list, prices: list, product: record, skuSellerId: string, status: list, stocks: list, title: string, urls: list>>
export def "get-products-status-selling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/status/selling"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk product stock update
#
# PUT /products/stocks
export def "put-products-stocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/products/stocks"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new trouble ticket
#
# POST /ticket
export def "post-ticket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  body: string # Message to the customer
  --customer: any # shape: {name?: string, phoneNumber?: string}
  --description: string # Trouble ticked brief description
  from: string # Friendly name of the person sending this message, if not provided the seller `name` will be used
  --message: any # shape: {body: string, visibility: string}
  order_id: string # Unique order Id that this trouble ticket belongs to
  type: string # Trouble ticket type.
]: any -> any {
  $in | http-request {
    method: post
    path: "/ticket"
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: customer, var: customer}, {name: description, var: description}, {name: from, var: from}, {name: message, var: message}, {name: orderId, var: order_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, body: $body, customer: $customer, description: $description, from: $from, message: $message, order_id: $order_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new message to trouble ticket
#
# POST /ticket/{ticketId}/message
export def "post-ticket-ticket-id-message" [
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
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  body: string # Message text
  visibility: string # Defines if this message is `CUSTOMER` (customer will receive a copy) or `INTERNAL`
]: any -> any {
  $in | http-request {
    method: post
    path: "/ticket/{ticketId}/message"
    path_params: [{name: ticketId, var: ticket_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, authorization: $authorization, body: $body, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trouble ticket messages
#
# GET /ticket/{ticketId}/messages
# Returns: record<messages: table<body: string, createdAt: string, id: string, visibility: string>, metadata: table<key: string, value: string>>
export def "get-ticket-ticket-id-messages" [
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
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ticket/{ticketId}/messages"
    path_params: [{name: ticketId, var: ticket_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update trouble ticket status
#
# PUT /ticket/{ticketId}/status
export def "put-ticket-ticket-id-status" [
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
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
  ticket_status: string # New trouble ticket status. Valid options are `REOPENED`, `CLOSED`
]: any -> any {
  $in | http-request {
    method: put
    path: "/ticket/{ticketId}/status"
    path_params: [{name: ticketId, var: ticket_id}]
    header: [{name: authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ticketStatus, var: ticket_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ticket_id: $ticket_id, authorization: $authorization, ticket_status: $ticket_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get customers trouble tickets
#
# GET /tickets
# Returns: record<metadata: table<key: string, value: string>, tickets: table<closedAt: string, createdAt: string, customer: record, description: string, metadata: list, priority: string, sla: string, status: string, subject: string, ticketId: string, type: string, updatedAt: string>>
export def "get-tickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Query by trouble ticket status
  --offset: int # Number or items to skip when executing query. List starts at zero. If omitted will default to zero. Use this conjuction with `limit` to paginate across the results.
  --limit: int # Number or items to return when executing query. Defaults to 10. Use this conjuction with `offset` to paginate across the results.
  --authorization: string # Authorization token. The Authorization token can be found in your Admin console. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tickets"
    query: [{name: status, var: status}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, offset: $offset, limit: $limit, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
