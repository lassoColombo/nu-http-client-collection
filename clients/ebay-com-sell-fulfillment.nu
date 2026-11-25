# Auto-generated client for Fulfillment API v1.19.19
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json
# Auth: --token flag or $env.FULFILLMENT_API_TOKEN

const CLIENT = {
  base_url: "https://api.ebay.com/sell/fulfillment/v1"
  token_env_var: "FULFILLMENT_API_TOKEN"
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

def base-url-completer [] { ["https://api.ebay.com/sell/fulfillment/v1" "https://apiz.ebay.com/sell/fulfillment/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-orders: "record<href: string, limit: int, next: string, offset: int, orders: table<buyer: record, buyerCheckoutNotes: string, cancelStatus: record, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list, fulfillmentStartInstructions: list, lastModifiedDate: string, legacyOrderId: string, lineItems: list, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record, pricingSummary: record, program: record, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record, totalMarketplaceFee: record>, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-order: "record<buyer: record<taxAddress: record<city: string, countryCode: string, postalCode: string, stateOrProvince: string>, taxIdentifier: record<issuingCountry: string, taxIdentifierType: string, taxpayerId: string>, username: string>, buyerCheckoutNotes: string, cancelStatus: record<cancelRequests: list<record>, cancelState: string, cancelledDate: string>, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list<string>, fulfillmentStartInstructions: table<ebaySupportedFulfillment: bool, finalDestinationAddress: record, fulfillmentInstructionsType: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupStep: record, shippingStep: record>, lastModifiedDate: string, legacyOrderId: string, lineItems: table<appliedPromotions: list, deliveryCost: record, discountedLineItemCost: record, ebayCollectAndRemitTaxes: list, ebayCollectedCharges: record, giftDetails: record, itemLocation: record, legacyItemId: string, legacyVariationId: string, lineItemCost: record, lineItemFulfillmentInstructions: record, lineItemFulfillmentStatus: string, lineItemId: string, listingMarketplaceId: string, properties: record, purchaseMarketplaceId: string, quantity: int, refunds: list, sku: string, soldFormat: string, taxes: list, title: string, total: record, variationAspects: list>, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record<payments: list<record>, refunds: list<record>, totalDueSeller: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, pricingSummary: record<adjustment: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryCost: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, fee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceSubtotal: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, tax: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, total: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, program: record<authenticityVerification: record<outcomeReason: string, status: string>, ebayInternationalShipping: record<returnsManagedBy: string>, ebayShipping: record<shippingLabelProvidedBy: string>, ebayVault: record<fulfillmentType: string>, fulfillmentProgram: record<fulfilledBy: string>>, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, totalMarketplaceFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>"
    get-shipping-fulfillments: "record<fulfillments: table<fulfillmentId: string, lineItems: list, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    create-shipping-fulfillment: "record"
    get-shipping-fulfillment: "record<fulfillmentId: string, lineItems: table<lineItemId: string, quantity: int>, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>"
    issue-refund: "record<refundId: string, refundStatus: string>"
    get-payment-dispute: "record<amount: record<currency: string, value: string>, availableChoices: list<string>, buyerProvided: record<note: string, returnShipmentTracking: list<record>>, buyerUsername: string, closedDate: string, evidence: table<evidenceId: string, evidenceType: string, files: list, lineItems: list, providedDate: string, requestDate: string, respondByDate: string, shipmentTracking: list>, evidenceRequests: table<evidenceId: string, evidenceType: string, lineItems: list, requestDate: string, respondByDate: string>, lineItems: table<itemId: string, lineItemId: string>, monetaryTransactions: table<amount: record, date: string, reason: string, type: string>, note: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, resolution: record<fees: record<currency: string, value: string>, protectedAmount: record<currency: string, value: string>, protectionStatus: string, reasonForClosure: string, recoupAmount: record<currency: string, value: string>, totalFeeCredit: record<currency: string, value: string>>, respondByDate: string, returnAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, fullName: string, postalCode: string, primaryPhone: record<countryCode: string, number: string>, stateOrProvince: string>, revision: int, sellerResponse: string>"
    get-activities: "record<activity: table<activityDate: string, activityType: string, actor: string>>"
    add-evidence: "record<evidenceId: string>"
    fetch-evidence-content: "list<string>"
    upload-evidence-file: "record<fileId: string>"
    get-payment-dispute-summaries: "record<href: string, limit: int, next: string, offset: int, paymentDisputeSummaries: table<amount: record, buyerUsername: string, closedDate: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, respondByDate: string>, prev: string, total: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-orders" "get-order" "get-shipping-fulfillments" "create-shipping-fulfillment" "get-shipping-fulfillment" "issue-refund" "get-payment-dispute" "accept-payment-dispute" "get-activities" "add-evidence" "contest-payment-dispute" "fetch-evidence-content" "update-evidence" "upload-evidence-file" "get-payment-dispute-summaries" "commands"] | sort) } | get name | first)
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

# Use this call to search for and retrieve one or more orders based on their creation date, last modification date, or fulfillment status using the filter parameter. You can alternatively specify a list of orders using the orderIds parameter. Include the optional fieldGroups query parameter set to TAX_BREAKDOWN to return a breakdown of the taxes and fees. The returned Order objects contain information you can use to create and process fulfillments, including: Information about the buyer and seller Information about the order's line items The plans for packaging, addressing and shipping the order The status of payment, packaging, addressing, and shipping the order A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs A summary of applied taxes and fees, and optionally a breakdown of each Important: In this call, the cancelStatus.cancelRequests array is returned but is always empty. Use the getOrder call instead, which returns this array fully populated with information about any cancellation requests.
#
# GET /order
# Returns: record<href: string, limit: int, next: string, offset: int, orders: table<buyer: record, buyerCheckoutNotes: string, cancelStatus: record, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list, fulfillmentStartInstructions: list, lastModifiedDate: string, legacyOrderId: string, lineItems: list, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record, pricingSummary: record, program: record, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record, totalMarketplaceFee: record>, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getOrders
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
  --field-groups: string # The response type associated with the order. The only presently supported value is TAX_BREAKDOWN. This type returns a breakdown of tax and fee values associated with the order.
  --filter: string # One or more comma-separated criteria for narrowing down the collection of orders returned by this call. These criteria correspond to specific fields in the response payload. Multiple filter criteria combine to further restrict the results. Note: getOrders can return orders up to two years old. Do not set the creationdate filter to a date beyond two years in the past.Note: If the orderIds parameter is included in the request, the filter parameter will be ignored.The available criteria are as follows: creationdate The time period during which qualifying orders were created (the orders.creationDate field). In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: creationdate:[2016-02-21T08:25:43.511Z..] identifies orders created on or after the given timestamp. creationdate:[2016-02-21T08:25:43.511Z..2016-04-21T08:25:43.511Z] identifies orders created between the given timestamps, inclusive. lastmodifieddate The time period during which qualifying orders were last modified (the orders.modifiedDate field). In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: lastmodifieddate:[2016-05-15T08:25:43.511Z..] identifies orders modified on or after the given timestamp. lastmodifieddate:[2016-05-15T08:25:43.511Z..2016-05-31T08:25:43.511Z] identifies orders modified between the given timestamps, inclusive. Note: If creationdate and lastmodifieddate are both included, only creationdate is used. orderfulfillmentstatus The degree to which qualifying orders have been shipped (the orders.orderFulfillmentStatus field). In the URI, this is expressed as one of the following value combinations: orderfulfillmentstatus:{NOT_STARTED|IN_PROGRESS} specifies orders for which no shipping fulfillments have been started, plus orders for which at least one shipping fulfillment has been started but not completed. orderfulfillmentstatus:{FULFILLED|IN_PROGRESS} specifies orders for which all shipping fulfillments have been completed, plus orders for which at least one shipping fulfillment has been started but not completed. Note: The values NOT_STARTED, IN_PROGRESS, and FULFILLED can be used in various combinations, but only the combinations shown here are currently supported. Here is an example of a getOrders call using all of these filters: GET https://api.ebay.com/sell/v1/order?filter=creationdate:%5B2016-03-21T08:25:43.511Z..2016-04-21T08:25:43.511Z%5D,lastmodifieddate:%5B2016-05-15T08:25:43.511Z..%5D,orderfulfillmentstatus:%7BNOT_STARTED%7CIN_PROGRESS%7D Note: This call requires that certain special characters in the URI query string be percent-encoded: [ = %5B ] = %5D { = %7B | = %7C } = %7D This query filter example uses these codes. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/fulfillment/types/api:FilterField
  --limit: string # The number of orders to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves orders 11 thru 20 from the result set. If a limit is not set, the limit defaults to 50 and returns up to 50 orders. If a requested limit is more than 200, the call fails and returns an error. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0. If the orderIds parameter is included in the request, this parameter will be ignored. Maximum: 200 Default: 50
  --offset: string # Specifies the number of orders to skip in the result set before returning the first order in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --order-ids: string # A comma-separated list of the unique identifiers of the orders to retrieve (maximum 50). If one or more order ID values are specified through the orderIds query parameter, all other query parameters will be ignored.Note: getOrders can return orders up to two years old. Do not provide the orderId for an order created more than two years in the past.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order"
    query: [{name: fieldGroups, var: field_groups}, {name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: orderIds, var: order_ids}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_groups: $field_groups, filter: $filter, limit: $limit, offset: $offset, order_ids: $order_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this call to retrieve the contents of an order based on its unique identifier, orderId. This value was returned in the getOrders call's orders.orderId field when you searched for orders by creation date, modification date, or fulfillment status. Include the optional fieldGroups query parameter set to TAX_BREAKDOWN to return a breakdown of the taxes and fees. The returned Order object contains information you can use to create and process fulfillments, including: Information about the buyer and seller Information about the order's line items The plans for packaging, addressing and shipping the order The status of payment, packaging, addressing, and shipping the order A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs A summary of applied taxes and fees, and optionally a breakdown of each
#
# GET /order/{orderId}
# Returns: record<buyer: record<taxAddress: record<city: string, countryCode: string, postalCode: string, stateOrProvince: string>, taxIdentifier: record<issuingCountry: string, taxIdentifierType: string, taxpayerId: string>, username: string>, buyerCheckoutNotes: string, cancelStatus: record<cancelRequests: list<record>, cancelState: string, cancelledDate: string>, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list<string>, fulfillmentStartInstructions: table<ebaySupportedFulfillment: bool, finalDestinationAddress: record, fulfillmentInstructionsType: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupStep: record, shippingStep: record>, lastModifiedDate: string, legacyOrderId: string, lineItems: table<appliedPromotions: list, deliveryCost: record, discountedLineItemCost: record, ebayCollectAndRemitTaxes: list, ebayCollectedCharges: record, giftDetails: record, itemLocation: record, legacyItemId: string, legacyVariationId: string, lineItemCost: record, lineItemFulfillmentInstructions: record, lineItemFulfillmentStatus: string, lineItemId: string, listingMarketplaceId: string, properties: record, purchaseMarketplaceId: string, quantity: int, refunds: list, sku: string, soldFormat: string, taxes: list, title: string, total: record, variationAspects: list>, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record<payments: list<record>, refunds: list<record>, totalDueSeller: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, pricingSummary: record<adjustment: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryCost: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, fee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceSubtotal: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, tax: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, total: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, program: record<authenticityVerification: record<outcomeReason: string, status: string>, ebayInternationalShipping: record<returnsManagedBy: string>, ebayShipping: record<shippingLabelProvidedBy: string>, ebayVault: record<fulfillmentType: string>, fulfillmentProgram: record<fulfilledBy: string>>, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, totalMarketplaceFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>
# operationId: getOrder
export def "get-order" [
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
  --field-groups: string # The response type associated with the order. The only presently supported value is TAX_BREAKDOWN. This type returns a breakdown of tax and fee values associated with the order.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    query: [{name: fieldGroups, var: field_groups}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, field_groups: $field_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this call to retrieve the contents of all fulfillments currently defined for a specified order based on the order's unique identifier, orderId. This value is returned in the getOrders call's members.orderId field when you search for orders by creation date or shipment status.
#
# GET /order/{orderId}/shipping_fulfillment
# Returns: record<fulfillments: table<fulfillmentId: string, lineItems: list, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getShippingFulfillments
export def "get-shipping-fulfillments" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order/{orderId}/shipping_fulfillment"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# When you group an order's line items into one or more packages, each package requires a corresponding plan for handling, addressing, and shipping; this is a shipping fulfillment. For each package, execute this call once to generate a shipping fulfillment associated with that package. Note: A single line item in an order can consist of multiple units of a purchased item, and one unit can consist of multiple parts or components. Although these components might be provided by the manufacturer in separate packaging, the seller must include all components of a given line item in the same package. Before using this call for a given package, you must determine which line items are in the package. If the package has been shipped, you should provide the date of shipment in the request. If not provided, it will default to the current date and time.
#
# POST /order/{orderId}/shipping_fulfillment
# Returns: record
# operationId: createShippingFulfillment
export def "create-shipping-fulfillment" [
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
  --line-items: list # This array contains a list of or more line items and the quantity that will be shipped in the same package. — item shape: {lineItemId?: string, quantity?: int}
  --shipped-date: string # This is the actual date and time that the fulfillment package was shipped. This timestamp is in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock. The seller should use the actual date/time that the package was shipped, but if this field is omitted, it will default to the current date/time.Format: [YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z Example: 2015-08-04T19:09:02.768ZDefault: The current date and time.
  --shipping-carrier-code: string # The unique identifier of the shipping carrier being used to ship the line item(s). Technically, the shippingCarrierCode and trackingNumber fields are optional, but generally these fields will be provided if the shipping carrier and tracking number are known. Note: Use the Trading API's GeteBayDetails (https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html ) call to retrieve the latest shipping carrier enumeration values. When making the GeteBayDetails (https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html ) call, include the DetailName field in the request payload and set its value to ShippingCarrierDetails. Each valid shipping carrier enumeration value is returned in a ShippingCarrierDetails.ShippingCarrier field in the response payload.
  --tracking-number: string # The tracking number provided by the shipping carrier for this fulfillment. The seller should be careful that this tracking number is accurate since the buyer will use this tracking number to track shipment, and eBay has no way to verify the accuracy of this number.This field and the shippingCarrierCode field are mutually dependent. If you include one, you must also include the other.Note: If you include trackingNumber (and shippingCarrierCode) in the request, the resulting fulfillment's ID (returned in the HTTP location code) is the tracking number. If you do not include shipment tracking information, the resulting fulfillment ID will default to an arbitrary number such as 999.Note: Only alphanumeric characters are supported for shipment tracking numbers. Spaces, hyphens, and all other special characters are not supported. Do not include a space in the tracking number even if a space appears in the tracking number on the shipping label.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order/{orderId}/shipping_fulfillment"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: lineItems, var: line_items}, {name: shippedDate, var: shipped_date}, {name: shippingCarrierCode, var: shipping_carrier_code}, {name: trackingNumber, var: tracking_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    order_id: $order_id, line_items: $line_items, shipped_date: $shipped_date, shipping_carrier_code: $shipping_carrier_code, tracking_number: $tracking_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this call to retrieve the contents of a fulfillment based on its unique identifier, fulfillmentId (combined with the associated order's orderId). The fulfillmentId value was originally generated by the createShippingFulfillment call, and is returned by the getShippingFulfillments call in the members.fulfillmentId field.
#
# GET /order/{orderId}/shipping_fulfillment/{fulfillmentId}
# Returns: record<fulfillmentId: string, lineItems: table<lineItemId: string, quantity: int>, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>
# operationId: getShippingFulfillment
export def "get-shipping-fulfillment" [
  order_id: string
  fulfillment_id: string
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
    path: "/order/{orderId}/shipping_fulfillment/{fulfillmentId}"
    path_params: [{name: orderId, var: order_id}, {name: fulfillmentId, var: fulfillment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, fulfillment_id: $fulfillment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue Refund
#
# POST /order/{order_id}/issue_refund
# Returns: record<refundId: string, refundStatus: string>
# operationId: issueRefund
export def "issue-refund" [
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
  --comment: string # This free-text field allows the seller to clarify why the refund is being issued to the buyer.Max Length: 100
  --order-level-refund-amount: record # This type defines the monetary value of the payment dispute, and the currency used. — shape: {currency?: string, value?: string}
  --reason-for-refund: string # The enumeration value passed into this field indicates the reason for the refund. One of the defined enumeration values in the ReasonForRefundEnum type must be used.This field is required, and it is highly recommended that sellers use the correct refund reason, especially in the case of a buyer-requested cancellation or 'buyer remorse' return to indicate that there was nothing wrong with the item(s) or with the shipment of the order.Note: If issuing refunds for more than one order line item, keep in mind that the refund reason must be the same for each of the order line items. If the refund reason is different for one or more order line items in an order, the seller would need to make separate issueRefund calls, one for each refund reason. For implementation help, refer to eBay API documentation
  --refund-items: list # The refundItems array is only required if the seller is issuing a refund for one or more individual order line items in a multiple line item order. Otherwise, the seller just uses the orderLevelRefundAmount container to specify the amount of the refund for the entire order. — item shape: {legacyReference?: record, lineItemId?: string, refundAmount?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/order/{order_id}/issue_refund"
    path_params: [{name: order_id, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: orderLevelRefundAmount, var: order_level_refund_amount}, {name: reasonForRefund, var: reason_for_refund}, {name: refundItems, var: refund_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, comment: $comment, order_level_refund_amount: $order_level_refund_amount, reason_for_refund: $reason_for_refund, refund_items: $refund_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment Dispute Details
#
# GET /payment_dispute/{payment_dispute_id}
# Returns: record<amount: record<currency: string, value: string>, availableChoices: list<string>, buyerProvided: record<note: string, returnShipmentTracking: list<record>>, buyerUsername: string, closedDate: string, evidence: table<evidenceId: string, evidenceType: string, files: list, lineItems: list, providedDate: string, requestDate: string, respondByDate: string, shipmentTracking: list>, evidenceRequests: table<evidenceId: string, evidenceType: string, lineItems: list, requestDate: string, respondByDate: string>, lineItems: table<itemId: string, lineItemId: string>, monetaryTransactions: table<amount: record, date: string, reason: string, type: string>, note: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, resolution: record<fees: record<currency: string, value: string>, protectedAmount: record<currency: string, value: string>, protectionStatus: string, reasonForClosure: string, recoupAmount: record<currency: string, value: string>, totalFeeCredit: record<currency: string, value: string>>, respondByDate: string, returnAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, fullName: string, postalCode: string, primaryPhone: record<countryCode: string, number: string>, stateOrProvince: string>, revision: int, sellerResponse: string>
# operationId: getPaymentDispute
export def "get-payment-dispute" [
  payment_dispute_id: string
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
    path: "/payment_dispute/{payment_dispute_id}"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/accept
# operationId: acceptPaymentDispute
export def "accept-payment-dispute" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-address: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current revision number for a payment dispute can be retrieved with the getPaymentDispute method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/payment_dispute/{payment_dispute_id}/accept"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: returnAddress, var: return_address}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [204]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id, return_address: $return_address, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment Dispute Activity
#
# GET /payment_dispute/{payment_dispute_id}/activity
# Returns: record<activity: table<activityDate: string, activityType: string, actor: string>>
# operationId: getActivities
export def "get-activities" [
  payment_dispute_id: string
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
    path: "/payment_dispute/{payment_dispute_id}/activity"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/add_evidence
# Returns: record<evidenceId: string>
# operationId: addEvidence
export def "add-evidence" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-type: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the EvidenceTypeEnum type for the supported evidence types. For implementation help, refer to eBay API documentation
  --files: list # This array is used to specify one or more evidence files that will become part of a new evidence set associated with a payment dispute. At least one evidence file must be specified in the files array. The unique identifier of an evidence file is returned in the response payload of the uploadEvidence method. — item shape: {fileId?: string}
  --line-items: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the itemId and lineItemID fields are needed to identify each order line item, and both of these values are returned under the evidenceRequests.lineItems array in the getPaymentDispute response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payment_dispute/{payment_dispute_id}/add_evidence"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: evidenceType, var: evidence_type}, {name: files, var: files}, {name: lineItems, var: line_items}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id, evidence_type: $evidence_type, files: $files, line_items: $line_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contest Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/contest
# operationId: contestPaymentDispute
export def "contest-payment-dispute" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string # This field shows information that the seller provides about the dispute, such as the basis for the dispute, any relevant evidence, tracking numbers, and so forth.This field is limited to 1000 characters.
  --return-address: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current revision number for a payment dispute can be retrieved with the getPaymentDispute method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/payment_dispute/{payment_dispute_id}/contest"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: note, var: note}, {name: returnAddress, var: return_address}, {name: revision, var: revision}]}
    accept: ["application/json"]
    ok: [204]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id, note: $note, return_address: $return_address, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment Dispute Evidence File
#
# GET /payment_dispute/{payment_dispute_id}/fetch_evidence_content
# Returns: list<string>
# operationId: fetchEvidenceContent
export def "fetch-evidence-content" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-id: string # The identifier of the evidential file set. The identifier of an evidential file set for a payment dispute is returned under the evidence array in the getPaymentDispute response.Below is an example of the syntax to use for this query parameter:evidence_id=12345678 (required)
  --file-id: string # The identifier of an evidential file. This file must belong to the evidential file set identified through the evidence_id query parameter. The identifier of each evidential file is returned under the evidence.files array in the getPaymentDispute response. Below is an example of the syntax to use for this query parameter:file_id=12345678 (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/payment_dispute/{payment_dispute_id}/fetch_evidence_content"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    query: [{name: evidence_id, var: evidence_id, required: true}, {name: file_id, var: file_id, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id, evidence_id: $evidence_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update evidence
#
# POST /payment_dispute/{payment_dispute_id}/update_evidence
# operationId: updateEvidence
export def "update-evidence" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-id: string # The unique identifier of the evidence set that is being updated with new evidence files.
  --evidence-type: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the EvidenceTypeEnum type for the supported evidence types. For implementation help, refer to eBay API documentation
  --files: list # This array is used to specify one or more evidence files that will be added to the evidence set associated with a payment dispute. At least one evidence file must be specified in the files array. The unique identifier of an evidence file is returned in the response payload of the uploadEvidence method. — item shape: {fileId?: string}
  --line-items: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the itemId and lineItemID fields are needed to identify each order line item, and both of these values are returned under the evidenceRequests.lineItems array in the getPaymentDispute response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/payment_dispute/{payment_dispute_id}/update_evidence"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: evidenceId, var: evidence_id}, {name: evidenceType, var: evidence_type}, {name: files, var: files}, {name: lineItems, var: line_items}]}
    accept: ["application/json"]
    ok: [204]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id, evidence_id: $evidence_id, evidence_type: $evidence_type, files: $files, line_items: $line_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/upload_evidence_file
# Returns: record<fileId: string>
# operationId: uploadEvidenceFile
export def "upload-evidence-file" [
  payment_dispute_id: string
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
    path: "/payment_dispute/{payment_dispute_id}/upload_evidence_file"
    path_params: [{name: payment_dispute_id, var: payment_dispute_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    payment_dispute_id: $payment_dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Payment Dispute by Filters
#
# GET /payment_dispute_summary
# Returns: record<href: string, limit: int, next: string, offset: int, paymentDisputeSummaries: table<amount: record, buyerUsername: string, closedDate: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, respondByDate: string>, prev: string, total: int>
# operationId: getPaymentDisputeSummaries
export def "get-payment-dispute-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # This filter is used if the seller wishes to retrieve one or more payment disputes filed against a specific order. It is possible that there can be more than one dispute filed against an order if the order has multiple line items. If this filter is used, any other filters are ignored.
  --buyer-username: string # This filter is used if the seller wishes to retrieve one or more payment disputes opened by a specific seller. The string that is passed in to this query parameter is the eBay user ID of the buyer.
  --open-date-from: string # The open_date_from and/or open_date_to date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the open_date_from and/or open_date_to filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.The open_date_from field sets the beginning date of the date range, and can be set as far back as 18 months from the present time. If a open_date_from field is used, but a open_date_to field is not used, the open_date_to value will default to 90 days after the date specified in the open_date_from field, or to the present time if less than 90 days in the past.The ISO-8601 format looks like this: yyyy-MM-ddThh:mm.ss.sssZ. An example would be 2019-08-04T19:09:02.768Z.
  --open-date-to: string # The open_date_from and/or open_date_to date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the open_date_from and/or open_date_to filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and the time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.The open_date_to field sets the ending date of the date range, and can be set up to 90 days from the date set in the open_date_from field. The ISO-8601 format looks like this: yyyy-MM-ddThh:mm.ss.sssZ. An example would be 2019-08-04T19:09:02.768Z.
  --payment-dispute-status: string # This filter is used if the seller wishes to only retrieve payment disputes in a specific state. More than one value can be specified. If no payment_dispute_status filter is used, payment disputes in all states are returned in the response. See DisputeStateEnum type for supported values.
  --limit: string # The value passed in this query parameter sets the maximum number of payment disputes to return per page of data. The value passed in this field should be an integer from 1 to 200. If this query parameter is not set, up to 200 records will be returned on each page of results.Min: 1; Max: 200; Default: 200
  --offset: string # This field is used to specify the number of records to skip in the result set before returning the first payment dispute in the paginated response. A zero-based index is used, so if you set the offset value to 0 (default value), the first payment dispute in the result set appears at the top of the response. Combine offset with the limit parameter to control the payment disputes returned in the response. For example, if you supply an offset value of 0 and a limit value of 10, the response will contain the first 10 payment disputes from the result set that matches the input criteria. If you supply an offset value of 10 and a limit value of 20, the response will contain payment disputes 11-30 from the result set that matches the input criteria.Min: 0; Max: total number of payment disputes - 1; Default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payment_dispute_summary"
    query: [{name: order_id, var: order_id}, {name: buyer_username, var: buyer_username}, {name: open_date_from, var: open_date_from}, {name: open_date_to, var: open_date_to}, {name: payment_dispute_status, var: payment_dispute_status}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://apiz.ebay.com/sell/fulfillment/v1"
    auth: bearer
  } {
    order_id: $order_id, buyer_username: $buyer_username, open_date_from: $open_date_from, open_date_to: $open_date_to, payment_dispute_status: $payment_dispute_status, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
