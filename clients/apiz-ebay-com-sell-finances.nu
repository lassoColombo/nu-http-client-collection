# Auto-generated client for eBay Finances API v1.15.0
# Source: https://api.apis.guru/v2/specs/apiz.ebay.com/sell-finances/v1.15.0/openapi.json
# Auth: --token flag or $env.EBAY_FINANCES_API_TOKEN

const CLIENT = {
  base_url: "https://apiz.ebay.com/sell/finances/v1"
  token_env_var: "EBAY_FINANCES_API_TOKEN"
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

def base-url-completer [] { ["https://apiz.ebay.com/sell/finances/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-payouts: "record<href: string, limit: int, next: string, offset: int, payouts: table<amount: record, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record, totalFee: record, transactionCount: int>, prev: string, total: int>"
    get-payout: "record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record<accountLastFourDigits: string, instrumentType: string, nickname: string>, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transactionCount: int>"
    get-payout-summary: "record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, payoutCount: int, transactionCount: int>"
    get-seller-funds-summary: "record<availableFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, fundsOnHold: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, processingFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>>"
    get-transactions: "record<href: string, limit: int, next: string, offset: int, prev: string, total: int, transactions: table<amount: record, bookingEntry: string, buyer: record, eBayCollectedTaxAmount: record, feeJurisdiction: record, feeType: string, orderId: string, orderLineItems: list, paymentsEntity: string, payoutId: string, references: list, salesRecordReference: string, totalFeeAmount: record, totalFeeBasisAmount: record, transactionDate: string, transactionId: string, transactionMemo: string, transactionStatus: string, transactionType: string>>"
    get-transaction-summary: "record<adjustmentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, adjustmentBookingEntry: string, adjustmentCount: int, balanceTransferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, balanceTransferBookingEntry: string, balanceTransferCount: int, creditAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, creditBookingEntry: string, creditCount: int, disputeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, disputeBookingEntry: string, disputeCount: int, loanRepaymentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, loanRepaymentBookingEntry: string, loanRepaymentCount: int, nonSaleChargeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, nonSaleChargeBookingEntry: string, nonSaleChargeCount: int, onHoldAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, onHoldBookingEntry: string, onHoldCount: int, refundAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, refundBookingEntry: string, refundCount: int, shippingLabelAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, shippingLabelBookingEntry: string, shippingLabelCount: int, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferBookingEntry: string, transferCount: int, withdrawalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, withdrawalBookingEntry: string, withdrawalCount: int>"
    get-transfer: "record<fundingSource: record<brand: string, memo: string, type: string>, transactionDate: string, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferDetail: record<balanceAdjustment: record<adjustmentAmount: record, adjustmentType: string>, charges: list<record>, totalChargeNetAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>>, transferId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-payouts" "get-payout" "get-payout-summary" "get-seller-funds-summary" "get-transactions" "get-transaction-summary" "get-transfer" "commands"] | sort) } | get name | first)
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

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.This method is used to retrieve the details of one or more seller payouts. By using the filter query parameter, users can retrieve payouts processed within a specific date range, and/or they can retrieve payouts in a specific state.There are also pagination and sort query parameters that allow users to control the payouts that are returned in the response.If no payouts match the input criteria, an empty payload is returned.
#
# GET /payout
# Returns: record<href: string, limit: int, next: string, offset: int, payouts: table<amount: record, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record, totalFee: record, transactionCount: int>, prev: string, total: int>
# operationId: getPayouts
export def "get-payouts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The three filter types that can be used here are discussed below. If none of these filters are used, all recent payouts in all states are returned:payoutDate: search for payouts within a specific range of dates. The date format to use is YYYY-MM-DDTHH:MM:SS.SSSZ. Below is the proper syntax to use if filtering by a date range: https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past.lastAttemptedPayoutDate: search for attempted payouts that failed within a specific range of dates. In order to use this filter, the payoutStatus filter must also be used and its value must be set to RETRYABLE_FAILED. The date format to use is YYYY-MM-DDTHH:MM:SS.SSSZ. The same syntax used for the payoutDate filter is also used for the lastAttemptedPayoutDate filter. This filter is only applicable (and will return results) if one or more seller payouts have failed, but are retryable. payoutStatus: search for payouts in a particular state. Only one payout state can be specified with this filter. The supported payoutStatus values are as follows:INITIATED: search for payouts that have been initiated but not processed.SUCCEEDED: search for successful payouts.RETRYABLE_FAILED: search for payouts that failed, but ones which will be tried again. This value must be used if filtering by lastAttemptedPayoutDate. TERMINAL_FAILED: search for payouts that failed, and ones that will not be tried again. REVERSED: search for payouts that were reversed. Below is the proper syntax to use if filtering by payout status: https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutStatus:{SUCCEEDED}If both the payoutDate and payoutStatus filters are used, payouts must satisfy both criteria to be returned. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --limit: string # The number of payouts to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the method retrieves payouts 11 thru 20 from the result set. Note: This feature employs a zero-based list, where the first payout in the results set has an offset value of 0. Maximum: 200 Default: 20
  --offset: string # This integer value indicates the actual position that the first payout returned on the current page has in the results set. So, if you wanted to view the 11th payout of the result set, you would set the offset value in the request to 10. In the request, you can use the offset parameter in conjunction with the limit parameter to control the pagination of the output. For example, if offset is set to 30 and limit is set to 10, the method retrieves payouts 31 thru 40 from the resulting collection of payouts. Note: This feature employs a zero-based list, where the first payout in the results set has an offset value of 0.Default: 0 (zero)
  --sort: string # By default, payouts or failed payouts that match the input criteria are sorted in descending order according to the payout date/last attempted payout date (i.e., most recent payouts returned first).To view payouts in ascending order instead (i.e., oldest payouts/attempted payouts first,) you would include the sort query parameter, and then set the value of its field parameter to payoutDate or lastAttemptedPayoutDate (if searching for failed, retryable payouts). Below is the proper syntax to use if filtering by a payout date range in ascending order:https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]&sort=payoutDatePayouts can only be sorted according to payout date, and can not be sorted by payout status. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:SortField
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payout"
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    filter: $filter, limit: $limit, offset: $offset, sort: $sort, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.This method retrieves details on a specific seller payout. The unique identfier of the payout is passed in as a path parameter at the end of the call URI. The getPayouts method can be used to retrieve the unique identifier of a payout, or the user can check Seller Hub.
#
# GET /payout/{payout_Id}
# Returns: record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record<accountLastFourDigits: string, instrumentType: string, nickname: string>, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transactionCount: int>
# operationId: getPayout
export def "get-payout" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payout/{payout_Id}"
    path_params: [{name: payout_Id, var: payout_id}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payout_id: $payout_id, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.This method is used to retrieve cumulative values for payouts in a particular state, or all states. The metadata in the response includes total payouts, the total number of monetary transactions (sales, refunds, credits) associated with those payouts, and the total dollar value of all payouts.If the filter query parameter is used to filter by payout status, only one payout status value may be used. If the filter query parameter is not used to filter by a specific payout status, cumulative values for payouts in all states are returned.The user can also use the filter query parameter to specify a date range, and then only payouts that were processed within that date range are considered.
#
# GET /payout_summary
# Returns: record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, payoutCount: int, transactionCount: int>
# operationId: getPayoutSummary
export def "get-payout-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The two filter types that can be used here are discussed below. One or both of these filter types can be used. If none of these filters are used, the data returned in the response will reflect payouts, in all states, processed within the last 90 days. payoutDate: consider payouts processed within a specific range of dates. The date format to use is YYYY-MM-DDTHH:MM:SS.SSSZ. Below is the proper syntax to use if filtering by a date range: https://apiz.ebay.com/sell/finances/v1/payout_summary?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past. payoutStatus: consider only the payouts in a particular state. Only one payout state can be specified with this filter. The supported payoutStatus values are as follows:INITIATED: search for payouts that have been initiated but not processed.SUCCEEDED: consider only successful payouts.RETRYABLE_FAILED: consider only payouts that failed, but ones which will be tried again.TERMINAL_FAILED: consider only payouts that failed, and ones that will not be tried again. REVERSED: consider only payouts that were reversed. Below is the proper syntax to use if filtering by payout status: https://apiz.ebay.com/sell/finances/v1/payout_summary?filter=payoutStatus:{SUCCEEDED}If both the payoutDate and payoutStatus filters are used, only the payouts that satisfy both criteria are considered in the results. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payout_summary"
    query: [{name: filter, var: filter}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.This method retrieves all pending funds that have not yet been distibuted through a seller payout.There are no input parameters for this method. The response payload includes available funds, funds being processed, funds on hold, and also an aggregate count of all three of these categories.If there are no funds that are pending, on hold, or being processed for the seller's account, no response payload is returned, and an http status code of 204 - No Content is returned instead.
#
# GET /seller_funds_summary
# Returns: record<availableFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, fundsOnHold: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, processingFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>>
# operationId: getSellerFundsSummary
export def "get-seller-funds-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/seller_funds_summary"
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.The getTransactions method allows a seller to retrieve information about one or more of their monetary transactions.Note: For a complete list of transaction types, refer to TransactionTypeEnum (/api-docs/sell/finances/types/pay:TransactionTypeEnum ).Numerous input filters are available which can be used individualy or combined to refine the data that are returned. For example:SALE transactions for August 15, 2022;RETURN transactions for the month of January, 2021;Transactions currently in a transactionStatus equal to FUNDS_ON_HOLD.Refer to the filter (#uri.filter ) field for additional information about each filter and its use.Pagination and sort query parameters are also provided that allow users to further control how monetary transactions are displayed in the response.If no monetary transactions match the input criteria, an http status code of 204 No Content is returned with no response payload.
#
# GET /transaction
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, total: int, transactions: table<amount: record, bookingEntry: string, buyer: record, eBayCollectedTaxAmount: record, feeJurisdiction: record, feeType: string, orderId: string, orderLineItems: list, paymentsEntity: string, payoutId: string, references: list, salesRecordReference: string, totalFeeAmount: record, totalFeeBasisAmount: record, transactionDate: string, transactionId: string, transactionMemo: string, transactionStatus: string, transactionType: string>>
# operationId: getTransactions
export def "get-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Numerous filters are available for the getTransactions method, and these filters are discussed below. One or more of these filter types can be used. If none of these filters are used, all monetary transactions from the last 90 days are returned:transactionDate: search for monetary transactions that occurred within a specific range of dates.Note: All dates must be input using UTC format (YYYY-MM-DDTHH:MM:SS.SSSZ) and should be adjusted accordingly for the local timezone of the user.Below is the proper syntax to use if filtering by a date range: https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionDate:[2018-10-23T00:00:01.000Z..2018-11-09T00:00:01.000Z]Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past. transactionType: search for a specific type of monetary transaction. The supported transactionType values are as follows:SALE: a sales order. REFUND: a refund to the buyer after an order cancellation or return.CREDIT: a credit issued by eBay to the seller's account.DISPUTE: a monetary transaction associated with a payment dispute between buyer and seller.NON_SALE_CHARGE: a monetary transaction involving a seller transferring money to eBay for the balance of a charge for NON_SALE_CHARGE transactions (transactions that contain non-transactional seller fees). These can include a one-time payment, monthly/yearly subscription fees charged monthly, NRC charges, and fee credits.SHIPPING_LABEL: a monetary transaction where eBay is billing the seller for an eBay shipping label. Note that the shipping label functionality will initially only be available to a select number of sellers.TRANSFER: A transfer is a monetary transaction where eBay is billing the seller for reimbursement of a charge. An example of a transfer is a seller reimbursing eBay for a buyer refund.ADJUSTMENT: An adjustment is a monetary transaction where eBay is crediting or debiting the seller's account.WITHDRAWAL: A withdrawal is a monetary transaction where the seller requests an on-demand payout from eBay.Note: On-demand payout is not available for sellers who are already on a daily payout schedule. In order to initiate an on-demand payout, a seller must be on a weekly, bi-weekly, or monthly payout schedule.LOAN_REPAYMENT: A monetary transaction related to the repayment of an outstanding loan balance for approved participants enrolled in the eBay Seller Capital financing program (https://pages.ebay.com/sellercapital/ ).Note: eBay Seller Capital financing is only available in select marketplaces. Refer to Marketplace availability for eBay Seller Capital funding program (/api-docs/sell/finances/overview.html#loans ) for current marketplace eligibility.Below is the proper syntax to use if filtering by a monetary transaction type: https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionType:{SALE}transactionStatus: this filter type is only applicable for sales orders, and allows the user to filter seller payouts in a particular state. The supported transactionStatus values are as follows:PAYOUT: this indicates that the proceeds from the corresponding sales order has been paid out to the seller's account.FUNDS_PROCESSING: this indicates that the funds for the corresponding monetary transaction are currently being processed.FUNDS_AVAILABLE_FOR_PAYOUT: this indicates that the proceeds from the corresponding sales order are available for a seller payout, but processing has not yet begun.FUNDS_ON_HOLD: this indicates that the proceeds from the corresponding sales order are currently being held by eBay, and are not yet available for a seller payout.COMPLETED: this indicates that the funds for the corresponding TRANSFER monetary transaction have transferred and the transaction has completed.FAILED: this indicates the process has failed for the corresponding TRANSFER monetary transaction. Below is the proper syntax to use if filtering by transaction status: https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionStatus:{PAYOUT}buyerUsername: the eBay user ID of the buyer involved in the monetary transaction. Only monetary transactions involving this buyer are returned. Below is the proper syntax to use if filtering by a specific eBay buyer: https://apiz.ebay.com/sell/finances/v1/transaction?filter=buyerUsername:{buyer1234} salesRecordReference: the unique Selling Manager identifier of the order involved in the monetary transaction. Only monetary transactions involving this Selling Manager Sales Record ID are returned. Below is the proper syntax to use if filtering by a specific Selling Manager Sales Record ID: https://apiz.ebay.com/sell/finances/v1/transaction?filter=salesRecordReference:{123}Note: For all orders originating after February 1, 2020, a value of 0 will be returned in the salesRecordReference field. So, this filter will only be useful to retrieve orders than occurred before this date. payoutId: the unique identifier of a seller payout. This value is auto-generated by eBay once the seller payout is set to be processed. Only monetary transactions involving this Payout ID are returned. Below is the proper syntax to use if filtering by a specific Payout ID: https://apiz.ebay.com/sell/finances/v1/transaction?filter=payoutId:{5********8} transactionId: the unique identifier of a monetary transaction. For a sales order, the orderId filter should be used instead. Only the monetary transaction defined by the identifier is returned.Note: This filter cannot be used alone; the transactionType must also be specified when filtering by transaction ID.Below is the proper syntax to use if filtering by a specific transaction ID: https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionId:{0*-0***0-3***3}&filter=transactionType:{SALE} orderId: the unique identifier of a sales order. Only monetary transaction(s) associated with this orderId value are returned.For any other monetary transaction, the transactionId filter should be used instead.Below is the proper syntax to use if filtering by a specific order ID:https://apiz.ebay.com/sell/finances/v1/transaction?filter=orderId:{0*-0***0-3***3} For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --limit: string # The number of monetary transactions to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the method retrieves monetary transactions 11 thru 20 from the result set. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0. Maximum: 1000 Default: 20
  --offset: string # This integer value indicates the actual position that the first monetary transaction returned on the current page has in the results set. So, if you wanted to view the 11th monetary transaction of the result set, you would set the offset value in the request to 10. In the request, you can use the offset parameter in conjunction with the limit parameter to control the pagination of the output. For example, if offset is set to 30 and limit is set to 10, the method retrieves transactions 31 thru 40 from the resulting collection of transactions. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.Default: 0 (zero)
  --sort: string # Sorting is not yet available for the getTransactions method. By default, monetary transactions that match the input criteria are sorted in descending order according to the transaction date. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:SortField
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transaction"
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    filter: $filter, limit: $limit, offset: $offset, sort: $sort, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.The getTransactionSummary method retrieves cumulative information for monetary transactions. If applicable, the number of payments with a transactionStatus equal to FUNDS_ON_HOLD and the total monetary amount of these on-hold payments are also returned.Note: For a complete list of transaction types, refer to TransactionTypeEnum (/api-docs/sell/finances/types/pay:TransactionTypeEnum ).Refer to the filter (#uri.filter ) field for additional information about each filter and its use.Note: Unless a transactionType filter is used to retrieve a specific type of transaction (e.g., SALE, REFUND, etc.,) the creditCount (#response.creditCount) and creditAmount (#response.creditAmount) response fields both include order sales and seller credits information. That is, the count and value fields do not distinguish between these two types monetary transactions.
#
# GET /transaction_summary
# Returns: record<adjustmentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, adjustmentBookingEntry: string, adjustmentCount: int, balanceTransferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, balanceTransferBookingEntry: string, balanceTransferCount: int, creditAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, creditBookingEntry: string, creditCount: int, disputeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, disputeBookingEntry: string, disputeCount: int, loanRepaymentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, loanRepaymentBookingEntry: string, loanRepaymentCount: int, nonSaleChargeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, nonSaleChargeBookingEntry: string, nonSaleChargeCount: int, onHoldAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, onHoldBookingEntry: string, onHoldCount: int, refundAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, refundBookingEntry: string, refundCount: int, shippingLabelAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, shippingLabelBookingEntry: string, shippingLabelCount: int, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferBookingEntry: string, transferCount: int, withdrawalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, withdrawalBookingEntry: string, withdrawalCount: int>
# operationId: getTransactionSummary
export def "get-transaction-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Numerous filters are available for the getTransactionSummary method, and these filters are discussed below. One or more of these filter types can be used. The transactionStatus filter must be used. All other filters are optional. transactionStatus: the data returned in the response pertains to the sales, payouts, and transfer status set. The supported transactionStatus values are as follows:PAYOUT: only consider monetary transactions where the proceeds from the sales order(s) have been paid out to the seller's bank account.FUNDS_PROCESSING: only consider monetary transactions where the proceeds from the sales order(s) are currently being processed.FUNDS_AVAILABLE_FOR_PAYOUT: only consider monetary transactions where the proceeds from the sales order(s) are available for a seller payout, but processing has not yet begun.FUNDS_ON_HOLD: only consider monetary transactions where the proceeds from the sales order(s) are currently being held by eBay, and are not yet available for a seller payout.COMPLETED: this indicates that the funds for the corresponding TRANSFER monetary transaction have transferred and the transaction has completed.FAILED: this indicates the process has failed for the corresponding TRANSFER monetary transaction. Below is the proper syntax to use when setting up the transactionStatus filter: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionStatus:&#123;PAYOUT&#125;transactionDate: only consider monetary transactions that occurred within a specific range of dates.Note: All dates must be input using UTC format (YYYY-MM-DDTHH:MM:SS.SSSZ) and should be adjusted accordingly for the local timezone of the user.Below is the proper syntax to use if filtering by a date range: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionDate:&#91;2018-10-23T00:00:01.000Z..2018-11-09T00:00:01.000Z&#93;Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past. transactionType: only consider a specific type of monetary transaction. The supported transactionType values are as follows:SALE: a sales order. REFUND: a refund to the buyer after an order cancellation or return.CREDIT: a credit issued by eBay to the seller's account.DISPUTE: a monetary transaction associated with a payment dispute between buyer and seller.NON_SALE_CHARGE: a monetary transaction involving a seller transferring money to eBay for the balance of a charge for NON_SALE_CHARGE transactions (transactions that contain non-transactional seller fees). These can include a one-time payment, monthly/yearly subscription fees charged monthly, NRC charges, and fee credits.SHIPPING_LABEL: a monetary transaction where eBay is billing the seller for an eBay shipping label. Note that the shipping label functionality will initially only be available to a select number of sellers.TRANSFER: A transfer is a monetary transaction where eBay is billing the seller for reimbursement of a charge. An example of a transfer is a seller reimbursing eBay for a buyer refund.ADJUSTMENT: An adjustment is a monetary transaction where eBay is crediting or debiting the seller's account.WITHDRAWAL: A withdrawal is a monetary transaction where the seller requests an on-demand payout from eBay.Note: On-demand payout is not available for sellers who are already on a daily payout schedule. In order to initiate an on-demand payout, a seller must be on a weekly, bi-weekly, or monthly payout schedule.LOAN_REPAYMENT: A monetary transaction related to the repayment of an outstanding loan balance for approved participants enrolled in the eBay Seller Capital financing program (https://pages.ebay.com/sellercapital/ ).Note: eBay Seller Capital financing is only available in select marketplaces. Refer to Marketplace availability for eBay Seller Capital funding program (/api-docs/sell/finances/overview.html#loans ) for current marketplace eligibility.Below is the proper syntax to use if filtering by a monetary transaction type: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionType:{SALE}buyerUsername: only consider monetary transactions involving a specific buyer (specified with the buyer's eBay user ID). Below is the proper syntax to use if filtering by a specific eBay buyer: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=buyerUsername:&#123;buyer1234&#125; salesRecordReference: only consider monetary transactions corresponding to a specific order (identified with a Selling Manager order identifier). Below is the proper syntax to use if filtering by a specific Selling Manager Sales Record ID: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=salesRecordReference:&#123;123&#125;Note: For all orders originating after February 1, 2020, a value of 0 will be returned in the salesRecordReference field. So, this filter will only be useful to retrieve orders than occurred before this date. payoutId: only consider monetary transactions related to a specific seller payout (identified with a Payout ID). This value is auto-generated by eBay once the seller payout is set to be processed. Below is the proper syntax to use if filtering by a specific Payout ID: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=payoutId:&#123;5********8&#125; transactionId: the unique identifier of a monetary transaction. For a sales order, the orderId filter should be used instead. Only the monetary transaction(s) associated with this transactionId value are returned.Note: This filter cannot be used alone; the transactionType must also be specified when filtering by transaction ID.Below is the proper syntax to use if filtering by a specific transaction ID: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionId:{0*-0***0-3***3}&filter=transactionType:{SALE} orderId: the unique identifier of a sales order. For any other monetary transaction, the transactionId filter should be used instead. Only the monetary transaction(s) associated with this orderId value are returned. Below is the proper syntax to use if filtering by a specific order ID: https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=orderId:{0*-0***0-3***3} For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transaction_summary"
    query: [{name: filter, var: filter}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Important! Due to EU & UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all Finances API methods. Please refer to Digital Signatures for APIs (/develop/guides/digital-signatures-for-apis ) to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.This method retrieves detailed information regarding a TRANSFER transaction type. A TRANSFER is a monetary transaction type that involves a seller transferring money to eBay for reimbursement of one or more charges. For example, when a seller reimburses eBay for a buyer refund.If an ID is passed into the URI that is an identifier for another transaction type, this call will return an http status code of 404 Not found.
#
# GET /transfer/{transfer_Id}
# Returns: record<fundingSource: record<brand: string, memo: string, type: string>, transactionDate: string, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferDetail: record<balanceAdjustment: record<adjustmentAmount: record, adjustmentType: string>, charges: list<record>, totalChargeNetAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>>, transferId: string>
# operationId: getTransfer
export def "get-transfer" [
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
  --x-ebay-c-marketplace-id: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See HTTP request headers (/api-docs/static/rest-request-components.html#marketpl ) for the marketplace ID values.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transfer/{transfer_Id}"
    path_params: [{name: transfer_Id, var: transfer_id}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transfer_id: $transfer_id, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
