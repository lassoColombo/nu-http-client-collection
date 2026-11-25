# Auto-generated client for Feed API v1.3.1
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-feed/v1.3.1/openapi.json
# Auth: --token flag or $env.FEED_API_TOKEN

const CLIENT = {
  base_url: "https://api.ebay.com/sell/feed/v1"
  token_env_var: "FEED_API_TOKEN"
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

def base-url-completer [] { ["https://api.ebay.com/sell/feed/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-customer-service-metric-tasks: "record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string>, total: int>"
    get-customer-service-metric-task: "record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<customerServiceMetricType: string, evaluationMarketplaceId: string, listingCategories: list<string>, shippingRegions: list<string>>, schemaVersion: string, status: string, taskId: string>"
    get-inventory-tasks: "record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>"
    get-inventory-task: "record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<listingFormat: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>"
    get-order-tasks: "record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>"
    get-order-task: "record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<creationDateRange: record<from: string, to: string>, modifiedDateRange: record<from: string, to: string>, orderStatus: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>"
    get-schedules: "record<href: string, limit: int, next: string, offset: int, prev: string, schedules: table<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>, total: int>"
    create-schedule: "record"
    get-schedule: "record<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>"
    get-latest-result-file: "record"
    get-schedule-templates: "record<href: string, limit: int, next: string, offset: int, prev: string, scheduleTemplates: table<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: list>, total: int>"
    get-schedule-template: "record<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: table<defaultValue: string, property: string, usage: string>>"
    get-tasks: "record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>"
    get-task: "record<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>"
    get-input-file: "record"
    get-result-file: "record"
    upload-file: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-customer-service-metric-tasks" "create-customer-service-metric-task" "get-customer-service-metric-task" "get-inventory-tasks" "create-inventory-task" "get-inventory-task" "get-order-tasks" "create-order-task" "get-order-task" "get-schedules" "create-schedule" "delete-schedule" "get-schedule" "update-schedule" "get-latest-result-file" "get-schedule-templates" "get-schedule-template" "get-tasks" "create-task" "get-task" "get-input-file" "get-result-file" "upload-file" "commands"] | sort) } | get name | first)
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

# Use this method to return an array of customer service metric tasks. You can limit the tasks returned by specifying a date range. Note: You can pass in either the look_back_days or date_range, but not both.
#
# GET /customer_service_metric_task
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string>, total: int>
# operationId: getCustomerServiceMetricTasks
export def "get-customer-service-metric-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The task creation date range. The results are filtered to include only tasks with a creation date that is equal to the dates specified or is within the specified range. Do not use with the look_back_days parameter.Format: UTCFor example, tasks within a range: yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ Tasks created on March 8, 20202020-03-08T00:00.00.000Z..2020-03-09T00:00:00.000ZMaximum: 90 days
  --feed-type: string # The feed type associated with the task. The only presently supported value is CUSTOMER_SERVICE_METRICS_REPORT.
  --limit: string # The number of customer service metric tasks to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Note:This feature employs a zero-based list, where the first item in the list has an offset of 0.Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default value: 7Range: 1-90 (inclusive)
  --offset: string # The number of customer service metric tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer_service_metric_task"
    query: [{name: date_range, var: date_range}, {name: feed_type, var: feed_type}, {name: limit, var: limit}, {name: look_back_days, var: look_back_days}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_range: $date_range, feed_type: $feed_type, limit: $limit, look_back_days: $look_back_days, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to create a customer service metrics download task with filter criteria for the customer service metrics report. When using this method, specify the feedType and filterCriteria including both evaluationMarketplaceId and customerServiceMetricType for the report. The method returns the location response header containing the call URI to use with getCustomerServiceMetricTask to retrieve status and details on the task.Only CURRENT Customer Service Metrics reports can be generated with the Sell Feed API. PROJECTED reports are not supported at this time. See the getCustomerServiceMetric (/api-docs/sell/analytics/resources/customer_service_metric/methods/getCustomerServiceMetric) method document in the Analytics API for more information about these two types of reports.Note: Before calling this API, retrieve the summary of the seller's performance and rating for the customer service metric by calling getCustomerServiceMetric (part of the Analytics API (/api-docs/sell/analytics/resources/methods)). You can then populate the create task request fields with the values from the response. This technique eliminates failed tasks that request a report for a customerServiceMetricType and evaluationMarketplaceId that are without evaluation.
#
# POST /customer_service_metric_task
# operationId: createCustomerServiceMetricTask
export def "create-customer-service-metric-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Use this header to specify the natural language in which the authenticated user desires the response. (required)
  --feed-type: string # The feedType specified for the task. The report lists the transaction details that contribute to the service metrics evaluation. Supported types include:CUSTOMER_SERVICE_METRICS_REPORT
  --filter-criteria: record # A complex data type that filters data for report creation. See CustomerServiceMetricsFilterCriteria for fields and descriptions. — shape: {customerServiceMetricType?: string, evaluationMarketplaceId?: string, listingCategories?: list<string>, shippingRegions?: list<string>}
  --schema-version: string # The version number of the file format. Valid value: 1.0
]: any -> any {
  $in | http-request {
    method: post
    path: "/customer_service_metric_task"
    header: [{name: accept-language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: filterCriteria, var: filter_criteria}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    accept_language: $accept_language, feed_type: $feed_type, filter_criteria: $filter_criteria, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this method to retrieve customer service metric task details for the specified task. The input is task_id.
#
# GET /customer_service_metric_task/{task_id}
# Returns: record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<customerServiceMetricType: string, evaluationMarketplaceId: string, listingCategories: list<string>, shippingRegions: list<string>>, schemaVersion: string, status: string, taskId: string>
# operationId: getCustomerServiceMetricTask
export def "get-customer-service-metric-task" [
  task_id: string
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
    path: "/customer_service_metric_task/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method searches for multiple tasks of a specific feed type, and includes date filters and pagination.
#
# GET /inventory_task
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>
# operationId: getInventoryTasks
export def "get-inventory-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the inventory task. Either feed_type or schedule_id is required. Do not use with the schedule_id parameter. Presently, only one feed type is available:LMS_ACTIVE_INVENTORY_REPORT
  --schedule-id: string # The ID of the schedule for which to retrieve the latest result file. This ID is generated when the schedule was created by the createSchedule method. Schedules apply to downloaded reports (LMS_ACTIVE_INVENTORY_REPORT). Either schedule_id or feed_type is required. Do not use with the feed_type parameter.
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Note: Maximum date range window size is 90 days.Valid Format (UTC): yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZFor example: Tasks created on March 31, 2021 2021-03-31T00:00:00.000Z..2021-03-31T00:00:00.000Z
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. Default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inventory_task"
    query: [{name: feed_type, var: feed_type}, {name: schedule_id, var: schedule_id}, {name: look_back_days, var: look_back_days}, {name: date_range, var: date_range}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed_type: $feed_type, schedule_id: $schedule_id, look_back_days: $look_back_days, date_range: $date_range, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates an inventory-related download task for a specified feed type with optional filter criteria. When using this method, specify the feedType. This method returns the location response header containing the getInventoryTask call URI to retrieve the inventory task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the inventory task.To retrieve the status of the task, use the getInventoryTask method to retrieve a single task ID or the getInventoryTasks method to retrieve multiple task IDs. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.Presently, this method supports Active Inventory Report. The ActiveInventoryReport returns a report that contains price and quantity information for all of the active listings for a specific seller. A seller can use this information to maintain their inventory on eBay.
#
# POST /inventory_task
# operationId: createInventoryTask
export def "create-inventory-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the inventory task you are about to create. Use a feedType that is available for your API. Presently, only one feed type is available:LMS_ACTIVE_INVENTORY_REPORTSee Report download feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types) for more information.
  --filter-criteria: record # The container for the filter fields. This container is used to set the filter criteria for the order report. A seller can retrieve listings for a specified format. — shape: {listingFormat?: string}
  --schema-version: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):Version Details / Schema Version (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version)Seller Hub feed schema version (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema)
]: any -> any {
  $in | http-request {
    method: post
    path: "/inventory_task"
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: filterCriteria, var: filter_criteria}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    feed_type: $feed_type, filter_criteria: $filter_criteria, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the task details and status of the specified inventory-related task. The input is task_id.
#
# GET /inventory_task/{task_id}
# Returns: record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<listingFormat: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>
# operationId: getInventoryTask
export def "get-inventory-task" [
  task_id: string
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
    path: "/inventory_task/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method returns the details and status for an array of order tasks based on a specified feed_type or schedule_id. Specifying both feed_type and schedule_id results in an error. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.If specifying the feed_type, limit which order tasks are returned by specifying filters such as the creation date range or period of time using look_back_days. If specifying a schedule_id, the schedule template (that the schedule_id is based on) determines which order tasks are returned (see schedule_id for additional information). Each schedule_id applies to one feed_type.
#
# GET /order_task
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>
# operationId: getOrderTasks
export def "get-order-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The order tasks creation date range. This range is used to filter the results. The filtered results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only orders less than 90 days old can be retrieved. Do not use with the look_back_days parameter. Format: UTC For example: Tasks within a range yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ Tasks created on September 8, 2019 2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z
  --feed-type: string # The feed type associated with the task. The only presently supported value is LMS_ORDER_REPORT. Do not use with the schedule_id parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
  --limit: string # The maximum number of order tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves order tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used.Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --offset: string # The number of order tasks to skip in the result set before returning the first order in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
  --schedule-id: string # The schedule ID associated with the order task. A schedule periodically generates a report for the feed type specified by the schedule template (see scheduleTemplateId in createSchedule). Do not use with the feed_type parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/order_task"
    query: [{name: date_range, var: date_range}, {name: feed_type, var: feed_type}, {name: limit, var: limit}, {name: look_back_days, var: look_back_days}, {name: offset, var: offset}, {name: schedule_id, var: schedule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_range: $date_range, feed_type: $feed_type, limit: $limit, look_back_days: $look_back_days, offset: $offset, schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates an order download task with filter criteria for the order report. When using this method, specify the feedType, schemaVersion, and filterCriteria for the report. The method returns the location response header containing the getOrderTask call URI to retrieve the order task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the order task. To retrieve the status of the task, use the getOrderTask method to retrieve a single task ID or the getOrderTasks method to retrieve multiple order task IDs. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.The following list contains this method's authorization scope and its corresponding feed type:https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_REPORT For details about how this method is used, see General feed types (/api-docs/sell/static/feed/general-feed-tasks.html) in the Selling Integration Guide. Note: At this time, the createOrderTask method only supports order creation date filters and not modified order date filters. Do not include the modifiedDateRange filter in your request payload.
#
# POST /order_task
# operationId: createOrderTask
export def "create-order-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the task. The only presently supported value is LMS_ORDER_REPORT. See Report download feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types) for more information.
  --filter-criteria: record # The type that defines the fields for the order filters. — shape: {creationDateRange?: record, modifiedDateRange?: record, orderStatus?: string}
  --schema-version: string # The schema version of the LMS OrderReport. For the LMS_ORDER_REPORT feed type, see the OrderReport (/devzone/merchant-data/CallRef/OrderReport.html#OrderReport) reference page to see the present schema version. The schemaVersion value is the version number shown at the top of the OrderReport page. Restriction: This value must be 1113 or higher. The OrderReport schema version is updated about every two weeks. All version numbers are odd numbers (even numbers are skipped). For example, the next release version after '1113' is '1115'.
]: any -> any {
  $in | http-request {
    method: post
    path: "/order_task"
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: filterCriteria, var: filter_criteria}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    feed_type: $feed_type, filter_criteria: $filter_criteria, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the task details and status of the specified task. The input is task_id. For details about how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide.
#
# GET /order_task/{task_id}
# Returns: record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<creationDateRange: record<from: string, to: string>, modifiedDateRange: record<from: string, to: string>, orderStatus: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>
# operationId: getOrderTask
export def "get-order-task" [
  task_id: string
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
    path: "/order_task/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves an array containing the details and status of all schedules based on the specified feed_type. Use this method to find a schedule if you do not know the schedule_id.
#
# GET /schedule
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, schedules: table<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>, total: int>
# operationId: getSchedules
export def "get-schedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feedType associated with the schedule. (required)
  --limit: string # The maximum number of schedules that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves schedules 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of schedules to skip in the result set before returning the first schedule in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/schedule"
    query: [{name: feed_type, var: feed_type, required: true}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed_type: $feed_type, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates a schedule, which is a subscription to the specified schedule template. A schedule periodically generates a report for the feedType specified by the template. Specify the same feedType as the feedType of the associated schedule template. When creating the schedule, if available from the template, you can specify a preferred trigger hour, day of the week, or day of the month. These and other fields are conditionally available as specified by the template. Note: Make sure to include all fields required by the schedule template (scheduleTemplateId). Call the getScheduleTemplate method (or the getScheduleTemplates method), to find out which fields are required or optional. If a field is optional and a default value is provided by the template, the default value will be used if omitted from the payload.A successful call returns the location response header containing the getSchedule call URI to retrieve the schedule you just created. The URL includes the eBay-assigned schedule ID, which you can use to reference the schedule task. To retrieve the details of the create schedule task, use the getSchedule method for a single schedule ID or the getSchedules method to retrieve all schedule details for the specified feed_type. The number of schedules for each feedType is limited. Error code 160031 is returned when you have reached this maximum. Note: Except for schedules with a HALF-HOUR frequency, all schedules will ideally run at the start of each hour ('00' minutes). Actual start time may vary time may vary due to load and other factors.
#
# POST /schedule
# Returns: record
# operationId: createSchedule
export def "create-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The name of the feed type for the created schedule. Match the feed_type from the schedule template associated with this schedule.
  --preferred-trigger-day-of-month: int # The preferred day of the month to trigger the schedule. This field can be used with preferredTriggerHour for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Minimum: 1Maximum: 31 (format: int32)
  --preferred-trigger-day-of-week: string # The preferred day of the week to trigger the schedule. This field can be used with preferredTriggerHour for weekly schedules. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to eBay API documentation
  --preferred-trigger-hour: string # The preferred two-digit hour of the day to trigger the schedule. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC hhZFor example, the following represents 11:00 am UTC: 11Z
  --schedule-end-date: string # The timestamp on which the report generation (subscription) ends. After this date, the schedule status becomes INACTIVE. Use this field, if available, to end the schedule in the future. This value must be later than scheduleStartDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents UTC October 10, 2021 at 10:00 AM:2021-10-10T10Z
  --schedule-name: string # The schedule name assigned by the user for the created schedule.
  --schedule-start-date: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the scheduleEndDate occurs or the scheduleTemplateId becomes inactive. Use this field, if available, to start the schedule in the future but before the scheduleEndDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM: 2020-01-01T12Z
  --schedule-template-id: string # The ID of the template associated with the schedule ID. You can get this ID from the documentation or by calling the getScheduleTemplates method. This method requires a schedule template ID that is ACTIVE.
  --schema-version: string # The schema version of the schedule feedType. This field is required if the feedType has a schema version.This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/schedule"
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: preferredTriggerDayOfMonth, var: preferred_trigger_day_of_month}, {name: preferredTriggerDayOfWeek, var: preferred_trigger_day_of_week}, {name: preferredTriggerHour, var: preferred_trigger_hour}, {name: scheduleEndDate, var: schedule_end_date}, {name: scheduleName, var: schedule_name}, {name: scheduleStartDate, var: schedule_start_date}, {name: scheduleTemplateId, var: schedule_template_id}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    feed_type: $feed_type, preferred_trigger_day_of_month: $preferred_trigger_day_of_month, preferred_trigger_day_of_week: $preferred_trigger_day_of_week, preferred_trigger_hour: $preferred_trigger_hour, schedule_end_date: $schedule_end_date, schedule_name: $schedule_name, schedule_start_date: $schedule_start_date, schedule_template_id: $schedule_template_id, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method deletes an existing schedule. Specify the schedule to delete using the schedule_id path parameter.
#
# DELETE /schedule/{schedule_id}
# operationId: deleteSchedule
export def "delete-schedule" [
  schedule_id: string
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
    path: "/schedule/{schedule_id}"
    path_params: [{name: schedule_id, var: schedule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves schedule details and status of the specified schedule. Specify the schedule to retrieve using the schedule_id. Use the getSchedules method to find a schedule if you do not know the schedule_id.
#
# GET /schedule/{schedule_id}
# Returns: record<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>
# operationId: getSchedule
export def "get-schedule" [
  schedule_id: string
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
    path: "/schedule/{schedule_id}"
    path_params: [{name: schedule_id, var: schedule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method updates an existing schedule. Specify the schedule to update using the schedule_id path parameter. If the schedule template has changed after the schedule was created or updated, the input will be validated using the changed template. Note: Make sure to include all fields required by the schedule template (scheduleTemplateId). Call the getScheduleTemplate method (or the getScheduleTemplates method), to find out which fields are required or optional. If you do not know the scheduleTemplateId, call the getSchedule method to find out.
#
# PUT /schedule/{schedule_id}
# operationId: updateSchedule
export def "update-schedule" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferred-trigger-day-of-month: int # The preferred day of the month to trigger the schedule. This field can be used with preferredTriggerHour for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. Minimum: 1Maximum: 31 (format: int32)
  --preferred-trigger-day-of-week: string # The preferred day of the week to trigger the schedule. This field can be used with preferredTriggerHour for weekly schedules. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to eBay API documentation
  --preferred-trigger-hour: string # The preferred two-digit hour of the day to trigger the schedule. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. Format: UTC hhZFor example, the following represents 11:00 am UTC: 11ZMinimum: 00ZMaximum: 23Z
  --schedule-end-date: string # The timestamp on which the schedule (report generation) ends. After this date, the schedule status becomes INACTIVE. Use this field, if available, to end the schedule in the future. This value must be later than scheduleStartDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents UTC October 10, 2021 at 10:00 AM: 2021-10-10T10Z
  --schedule-name: string # The schedule name assigned by the user for the created schedule.
  --schedule-start-date: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the scheduleEndDate occurs or the scheduleTemplateId becomes inactive. Use this field, if available, to start the schedule in the future but before the scheduleEndDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM: 2020-01-01T12Z
  --schema-version: string # The schema version of the feedType for the schedule. This field is required if the feedType has a schema version. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> any {
  $in | http-request {
    method: put
    path: "/schedule/{schedule_id}"
    path_params: [{name: schedule_id, var: schedule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: preferredTriggerDayOfMonth, var: preferred_trigger_day_of_month}, {name: preferredTriggerDayOfWeek, var: preferred_trigger_day_of_week}, {name: preferredTriggerHour, var: preferred_trigger_hour}, {name: scheduleEndDate, var: schedule_end_date}, {name: scheduleName, var: schedule_name}, {name: scheduleStartDate, var: schedule_start_date}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    schedule_id: $schedule_id, preferred_trigger_day_of_month: $preferred_trigger_day_of_month, preferred_trigger_day_of_week: $preferred_trigger_day_of_week, preferred_trigger_hour: $preferred_trigger_hour, schedule_end_date: $schedule_end_date, schedule_name: $schedule_name, schedule_start_date: $schedule_start_date, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method downloads the latest result file generated by the schedule. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). Specify the schedule_id path parameter to download its last generated file.
#
# GET /schedule/{schedule_id}/download_result_file
# Returns: record
# operationId: getLatestResultFile
export def "get-latest-result-file" [
  schedule_id: string
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
    path: "/schedule/{schedule_id}/download_result_file"
    path_params: [{name: schedule_id, var: schedule_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves an array containing the details and status of all schedule templates based on the specified feed_type. Use this method to find a schedule template if you do not know the schedule_template_id.
#
# GET /schedule_template
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, scheduleTemplates: table<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: list>, total: int>
# operationId: getScheduleTemplates
export def "get-schedule-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type of the schedule templates to retrieve. (required)
  --limit: string # The maximum number of schedule templates that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves schedule templates 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of schedule templates to skip in the result set before returning the first template in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/schedule_template"
    query: [{name: feed_type, var: feed_type, required: true}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed_type: $feed_type, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details of the specified template. Specify the template to retrieve using the schedule_template_id path parameter. Use the getScheduleTemplates method to find a schedule template if you do not know the schedule_template_id.
#
# GET /schedule_template/{schedule_template_id}
# Returns: record<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: table<defaultValue: string, property: string, usage: string>>
# operationId: getScheduleTemplate
export def "get-schedule-template" [
  schedule_template_id: string
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
    path: "/schedule_template/{schedule_template_id}"
    path_params: [{name: schedule_template_id, var: schedule_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    schedule_template_id: $schedule_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method returns the details and status for an array of tasks based on a specified feed_type or scheduledId. Specifying both feed_type and scheduledId results in an error. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.If specifying the feed_type, limit which tasks are returned by specifying filters, such as the creation date range or period of time using look_back_days. Also, by specifying the feed_type, both on-demand and scheduled reports are returned.If specifying a scheduledId, the schedule template (that the schedule ID is based on) determines which tasks are returned (see schedule_id for additional information). Each scheduledId applies to one feed_type.
#
# GET /task
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int>
# operationId: getTasks
export def "get-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only tasks that are less than 90 days can be retrieved. Note: Maximum date range window size is 90 days. Valid Format (UTC):yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ For example: Tasks created on September 8, 2019 2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z
  --feed-type: string # The feed type associated with the tasks to be returned. Only use a feedType that is available for your API: Order Feeds: LMS_ORDER_ACK, LMS_ORDER_REPORTLarge Merchant Services (LMS) Feeds: See Available FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)Do not use with the schedule_id parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. Default: 0
  --schedule-id: string # The schedule ID associated with the task. A schedule periodically generates a report for the feed type specified by the schedule template (see scheduleTemplateId in createSchedule). Do not use with the feed_type parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/task"
    query: [{name: date_range, var: date_range}, {name: feed_type, var: feed_type}, {name: limit, var: limit}, {name: look_back_days, var: look_back_days}, {name: offset, var: offset}, {name: schedule_id, var: schedule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_range: $date_range, feed_type: $feed_type, limit: $limit, look_back_days: $look_back_days, offset: $offset, schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates an upload task or a download task without filter criteria. When using this method, specify the feedType and the feed file schemaVersion. The feed type specified sets the task as a download or an upload task. For details about the upload and download flows, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.The following list contains this method's authorization scopes and their corresponding feed types:https://api.ebay.com/oauth/api_scope/sell.inventory: See LMS FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_ACK (specify for upload tasks). Also see LMS FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)https://api.ebay.com/oauth/api_scope/sell.marketing: None*https://api.ebay.com/oauth/api_scope/commerce.catalog.readonly: None** Reserved for future release
#
# POST /task
# operationId: createTask
export def "create-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example:X-EBAY-C-MARKETPLACE-ID:EBAY_USThis identifies the eBay marketplace that applies to this task. See MarketplaceIdEnum (/api-docs/sell/feed/types/bas:MarketplaceIdEnum).
  --feed-type: string # The feed type associated with the task. Only use a feedType that is available for your API. Available feed types:Inventory upload feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#trading-upload-feed-types)Fulfillment upload feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-upload-feed-types)Seller Hub feed types (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl)
  --schema-version: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):Version Details / Schema Version (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version)Seller Hub feed schema version (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema)
]: any -> any {
  $in | http-request {
    method: post
    path: "/task"
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: feedType, var: feed_type}, {name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, feed_type: $feed_type, schema_version: $schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details and status of the specified task. The input is task_id. For details of how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide.
#
# GET /task/{task_id}
# Returns: record<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>>
# operationId: getTask
export def "get-task" [
  task_id: string
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
    path: "/task/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method downloads the file previously uploaded using uploadFile. Specify the task_id from the uploadFile call. Note: With respect to LMS, this method applies to all feed types except LMS_ORDER_REPORT and LMS_ACTIVE_INVENTORY_REPORT. See LMS API Feeds (/api-docs/sell/static/feed/lms-feeds.html) in the Selling Integration Guide.
#
# GET /task/{task_id}/download_input_file
# Returns: record
# operationId: getInputFile
export def "get-input-file" [
  task_id: string
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
    path: "/task/{task_id}/download_input_file"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the generated file that is associated with the specified task ID. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). For details about how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: The status of the task to retrieve must be in the COMPLETED or COMPLETED_WITH_ERROR state before this method can retrieve the file. You can use the getTask or getTasks method to retrieve the status of the task.
#
# GET /task/{task_id}/download_result_file
# Returns: record
# operationId: getResultFile
export def "get-result-file" [
  task_id: string
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
    path: "/task/{task_id}/download_result_file"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method associates the specified file with the specified task ID and uploads the input file. After the file has been uploaded, the processing of the file begins. Reports often take time to generate and it's common for this method to return an HTTP status of 202, which indicates the report is being generated. Use the getTask with the task ID or getTasks to determine the status of a report. The status flow is QUEUED > IN_PROCESS > COMPLETED or COMPLETED_WITH_ERROR. When the status is COMPLETED or COMPLETED_WITH_ERROR, this indicates the file has been processed and the order report can be downloaded. If there are errors, they will be indicated in the report file. For details of how this method is used in the upload flow, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: This method applies to all Seller Hub feed types and LMS feed types except LMS_ORDER_REPORT and LMS_ACTIVE_INVENTORY_REPORT. See LMS feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl) and Seller Hub feed types (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl). Note: You must use a Content-Type header with its value set to "multipart/form-data". See Samples (/api-docs/sell/feed/resources/task/methods/uploadFile#h2-samples) for information.
#
# POST /task/{task_id}/upload_file
# Returns: record
# operationId: uploadFile
export def "upload-file" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creation-date: string # The file creation date. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 8, 20192019-09-08T00:00:00.000Z
  --file-name: string # The name of the file including its extension (for example, xml or csv) to be uploaded.
  --modification-date: string # The file modified date. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 9, 20192019-09-09T00:00:00.000Z
  --name: string # A content identifier. The only presently supported name is file.
  --parameters: record # The parameters you want associated with the file.
  --read-date: string # The date you read the file. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 10, 20192019-09-10T00:00:00.000Z
  --size: int # The size of the file. (format: int32)
  --type: string # The file type. The only presently supported type is form-data.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/task/{task_id}/upload_file"
    path_params: [{name: task_id, var: task_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: creationDate, var: creation_date}, {name: fileName, var: file_name}, {name: modificationDate, var: modification_date}, {name: name, var: name}, {name: parameters, var: parameters}, {name: readDate, var: read_date}, {name: size, var: size}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, creation_date: $creation_date, file_name: $file_name, modification_date: $modification_date, name: $name, parameters: $parameters, read_date: $read_date, size: $size, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
