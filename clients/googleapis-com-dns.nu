# Auto-generated client for Cloud DNS API v2
# Source: https://api.apis.guru/v2/specs/googleapis.com/dns/v2/openapi.json
# Auth: --token flag or $env.CLOUD_DNS_API_TOKEN

const CLIENT = {
  base_url: "https://dns.googleapis.com"
  token_env_var: "CLOUD_DNS_API_TOKEN"
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

def base-url-completer [] { ["https://dns.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC"] }
def sort-by-completer [] { ["CHANGE_SEQUENCE"] }
def status-completer [] { ["DONE" "PENDING"] }
def sort-by-completer-1 [] { ["ID" "START_TIME"] }
def behavior-completer [] { ["BEHAVIOR_UNSPECIFIED" "BYPASS_RESPONSE_POLICY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    dns-projects-get: "record<id: string, kind: string, number: string, quota: record<dnsKeysPerManagedZone: int, gkeClustersPerManagedZone: int, gkeClustersPerPolicy: int, gkeClustersPerResponsePolicy: int, itemsPerRoutingPolicy: int, kind: string, managedZones: int, managedZonesPerGkeCluster: int, managedZonesPerNetwork: int, networksPerManagedZone: int, networksPerPolicy: int, networksPerResponsePolicy: int, peeringZonesPerTargetNetwork: int, policies: int, resourceRecordsPerRrset: int, responsePolicies: int, responsePolicyRulesPerResponsePolicy: int, rrsetAdditionsPerChange: int, rrsetDeletionsPerChange: int, rrsetsPerManagedZone: int, targetNameServersPerManagedZone: int, targetNameServersPerPolicy: int, totalRrdataSizePerChange: int, whitelistedKeySpecs: list<record>>>"
    dns-managed-zones-list: "record<header: record<operationId: string>, kind: string, managedZones: table<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, nextPageToken: string>"
    dns-managed-zones-create: "record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string>"
    dns-managed-zones-get: "record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string>"
    dns-managed-zones-patch: "record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>"
    dns-managed-zones-update: "record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>"
    dns-changes-list: "record<changes: table<additions: list, deletions: list, id: string, isServing: bool, kind: string, startTime: string, status: string>, header: record<operationId: string>, kind: string, nextPageToken: string>"
    dns-changes-create: "record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string>"
    dns-changes-get: "record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string>"
    dns-dns-keys-list: "record<dnsKeys: table<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, header: record<operationId: string>, kind: string, nextPageToken: string>"
    dns-dns-keys-get: "record<algorithm: string, creationTime: string, description: string, digests: table<digest: string, type: string>, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>"
    dns-managed-zone-operations-list: "record<header: record<operationId: string>, kind: string, nextPageToken: string, operations: table<dnsKeyContext: record, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record>>"
    dns-managed-zone-operations-get: "record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>"
    dns-resource-record-sets-list: "record<header: record<operationId: string>, kind: string, nextPageToken: string, rrsets: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>>"
    dns-resource-record-sets-create: "record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>"
    dns-resource-record-sets-get: "record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>"
    dns-resource-record-sets-patch: "record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>"
    dns-policies-list: "record<header: record<operationId: string>, kind: string, nextPageToken: string, policies: table<alternativeNameServerConfig: record, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list>>"
    dns-policies-create: "record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>>"
    dns-policies-get: "record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>>"
    dns-policies-patch: "record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>>"
    dns-policies-update: "record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>>"
    dns-response-policies-list: "record<header: record<operationId: string>, nextPageToken: string, responsePolicies: table<description: string, gkeClusters: list, id: string, kind: string, labels: record, networks: list, responsePolicyName: string>>"
    dns-response-policies-create: "record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string>"
    dns-response-policies-get: "record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string>"
    dns-response-policies-patch: "record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>>"
    dns-response-policies-update: "record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>>"
    dns-response-policy-rules-list: "record<header: record<operationId: string>, nextPageToken: string, responsePolicyRules: table<behavior: string, dnsName: string, kind: string, localData: record, ruleName: string>>"
    dns-response-policy-rules-create: "record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string>"
    dns-response-policy-rules-get: "record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string>"
    dns-response-policy-rules-patch: "record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>>"
    dns-response-policy-rules-update: "record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>>"
    dns-managed-zones-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dns-managed-zones-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dns-managed-zones-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["dns-projects-get" "dns-managed-zones-list" "dns-managed-zones-create" "dns-managed-zones-delete" "dns-managed-zones-get" "dns-managed-zones-patch" "dns-managed-zones-update" "dns-changes-list" "dns-changes-create" "dns-changes-get" "dns-dns-keys-list" "dns-dns-keys-get" "dns-managed-zone-operations-list" "dns-managed-zone-operations-get" "dns-resource-record-sets-list" "dns-resource-record-sets-create" "dns-resource-record-sets-delete" "dns-resource-record-sets-get" "dns-resource-record-sets-patch" "dns-policies-list" "dns-policies-create" "dns-policies-delete" "dns-policies-get" "dns-policies-patch" "dns-policies-update" "dns-response-policies-list" "dns-response-policies-create" "dns-response-policies-delete" "dns-response-policies-get" "dns-response-policies-patch" "dns-response-policies-update" "dns-response-policy-rules-list" "dns-response-policy-rules-create" "dns-response-policy-rules-delete" "dns-response-policy-rules-get" "dns-response-policy-rules-patch" "dns-response-policy-rules-update" "dns-managed-zones-get-iam-policy" "dns-managed-zones-set-iam-policy" "dns-managed-zones-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Fetches the representation of an existing Project.
#
# GET /dns/v2/projects/{project}/locations/{location}
# Returns: record<id: string, kind: string, number: string, quota: record<dnsKeysPerManagedZone: int, gkeClustersPerManagedZone: int, gkeClustersPerPolicy: int, gkeClustersPerResponsePolicy: int, itemsPerRoutingPolicy: int, kind: string, managedZones: int, managedZonesPerGkeCluster: int, managedZonesPerNetwork: int, networksPerManagedZone: int, networksPerPolicy: int, networksPerResponsePolicy: int, peeringZonesPerTargetNetwork: int, policies: int, resourceRecordsPerRrset: int, responsePolicies: int, responsePolicyRulesPerResponsePolicy: int, rrsetAdditionsPerChange: int, rrsetDeletionsPerChange: int, rrsetsPerManagedZone: int, targetNameServersPerManagedZone: int, targetNameServersPerPolicy: int, totalRrdataSizePerChange: int, whitelistedKeySpecs: list<record>>>
# operationId: dns.projects.get
export def "dns-projects-get" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates ManagedZones that have been created but not yet deleted.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones
# Returns: record<header: record<operationId: string>, kind: string, managedZones: table<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, nextPageToken: string>
# operationId: dns.managedZones.list
export def "dns-managed-zones-list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dns-name: string # Restricts the list to return only zones with this domain name.
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dnsName, var: dns_name}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dns_name: $dns_name, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ManagedZone.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones
# Returns: record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string>
# operationId: dns.managedZones.create
export def "dns-managed-zones-create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudLoggingConfig, var: cloud_logging_config}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: dnsName, var: dns_name}, {name: dnssecConfig, var: dnssec_config}, {name: forwardingConfig, var: forwarding_config}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: name, var: name}, {name: nameServerSet, var: name_server_set}, {name: nameServers, var: name_servers}, {name: peeringConfig, var: peering_config}, {name: privateVisibilityConfig, var: private_visibility_config}, {name: reverseLookupConfig, var: reverse_lookup_config}, {name: serviceDirectoryConfig, var: service_directory_config}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, cloud_logging_config: $cloud_logging_config, creation_time: $creation_time, description: $description, dns_name: $dns_name, dnssec_config: $dnssec_config, forwarding_config: $forwarding_config, id: $id, kind: $kind, labels: $labels, name: $name, name_server_set: $name_server_set, name_servers: $name_servers, peering_config: $peering_config, private_visibility_config: $private_visibility_config, reverse_lookup_config: $reverse_lookup_config, service_directory_config: $service_directory_config, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created ManagedZone.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# operationId: dns.managedZones.delete
export def "dns-managed-zones-delete" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing ManagedZone.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# Returns: record<cloudLoggingConfig: record<enableLogging: bool, kind: string>, creationTime: string, description: string, dnsName: string, dnssecConfig: record<defaultKeySpecs: list<record>, kind: string, nonExistence: string, state: string>, forwardingConfig: record<kind: string, targetNameServers: list<record>>, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list<string>, peeringConfig: record<kind: string, targetNetwork: record<deactivateTime: string, kind: string, networkUrl: string>>, privateVisibilityConfig: record<gkeClusters: list<record>, kind: string, networks: list<record>>, reverseLookupConfig: record<kind: string>, serviceDirectoryConfig: record<kind: string, namespace: record<deletionTime: string, kind: string, namespaceUrl: string>>, visibility: string>
# operationId: dns.managedZones.get
export def "dns-managed-zones-get" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a partial update to an existing ManagedZone.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# Returns: record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>
# operationId: dns.managedZones.patch
export def "dns-managed-zones-patch" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudLoggingConfig, var: cloud_logging_config}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: dnsName, var: dns_name}, {name: dnssecConfig, var: dnssec_config}, {name: forwardingConfig, var: forwarding_config}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: name, var: name}, {name: nameServerSet, var: name_server_set}, {name: nameServers, var: name_servers}, {name: peeringConfig, var: peering_config}, {name: privateVisibilityConfig, var: private_visibility_config}, {name: reverseLookupConfig, var: reverse_lookup_config}, {name: serviceDirectoryConfig, var: service_directory_config}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, cloud_logging_config: $cloud_logging_config, creation_time: $creation_time, description: $description, dns_name: $dns_name, dnssec_config: $dnssec_config, forwarding_config: $forwarding_config, id: $id, kind: $kind, labels: $labels, name: $name, name_server_set: $name_server_set, name_servers: $name_servers, peering_config: $peering_config, private_visibility_config: $private_visibility_config, reverse_lookup_config: $reverse_lookup_config, service_directory_config: $service_directory_config, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing ManagedZone.
#
# PUT /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}
# Returns: record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>
# operationId: dns.managedZones.update
export def "dns-managed-zones-update" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --cloud-logging-config: record # Cloud Logging configurations for publicly visible zones. — shape: {enableLogging?: bool, kind?: string}
  --creation-time: string # The time that this resource was created on the server. This is in RFC3339 text format. Output only.
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the managed zone's function.
  --dns-name: string # The DNS name of this managed zone, for instance "example.com.".
  --dnssec-config: record # shape: {defaultKeySpecs?: list, kind?: string, nonExistence?: "NSEC"|"NSEC3", state?: "OFF"|"ON"|"TRANSFER"}
  --forwarding-config: record # shape: {kind?: string, targetNameServers?: list}
  --id: string # Unique identifier for the resource; defined by the server (output only) (format: uint64)
  --kind: string # default: dns#managedZone
  --labels: record # User labels.
  --name: string # User assigned name for this resource. Must be unique within the project. The name must be 1-63 characters long, must begin with a letter, end with a letter or digit, and only contain lowercase letters, digits or dashes.
  --name-server-set: string # Optionally specifies the NameServerSet for this ManagedZone. A NameServerSet is a set of DNS name servers that all host the same ManagedZones. Most users leave this field unset. If you need to use this field, contact your account team.
  --name-servers: list<string> # Delegate your managed_zone to these virtual name servers; defined by the server (output only)
  --peering-config: record # shape: {kind?: string, targetNetwork?: record}
  --private-visibility-config: record # shape: {gkeClusters?: list, kind?: string, networks?: list}
  --reverse-lookup-config: record # shape: {kind?: string}
  --service-directory-config: record # Contains information about Service Directory-backed zones. — shape: {kind?: string, namespace?: record}
  --visibility: string@visibility-completer # The zone's visibility: public zones are exposed to the Internet, while private zones are visible only to Virtual Private Cloud resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudLoggingConfig, var: cloud_logging_config}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: dnsName, var: dns_name}, {name: dnssecConfig, var: dnssec_config}, {name: forwardingConfig, var: forwarding_config}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: name, var: name}, {name: nameServerSet, var: name_server_set}, {name: nameServers, var: name_servers}, {name: peeringConfig, var: peering_config}, {name: privateVisibilityConfig, var: private_visibility_config}, {name: reverseLookupConfig, var: reverse_lookup_config}, {name: serviceDirectoryConfig, var: service_directory_config}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, cloud_logging_config: $cloud_logging_config, creation_time: $creation_time, description: $description, dns_name: $dns_name, dnssec_config: $dnssec_config, forwarding_config: $forwarding_config, id: $id, kind: $kind, labels: $labels, name: $name, name_server_set: $name_server_set, name_servers: $name_servers, peering_config: $peering_config, private_visibility_config: $private_visibility_config, reverse_lookup_config: $reverse_lookup_config, service_directory_config: $service_directory_config, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates Changes to a ResourceRecordSet collection.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes
# Returns: record<changes: table<additions: list, deletions: list, id: string, isServing: bool, kind: string, startTime: string, status: string>, header: record<operationId: string>, kind: string, nextPageToken: string>
# operationId: dns.changes.list
export def "dns-changes-list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --sort-by: string@sort-by-completer # Sorting criterion. The only supported value is change sequence.
  --sort-order: string # Sorting order direction: 'ascending' or 'descending'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token, sort_by: $sort_by, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Atomically updates the ResourceRecordSet collection.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes
# Returns: record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string>
# operationId: dns.changes.create
export def "dns-changes-create" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --additions: list # Which ResourceRecordSets to add? — item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
  --deletions: list # Which ResourceRecordSets to remove? Must match existing data exactly. — item shape: {kind?: string, name?: string, routingPolicy?: record, rrdatas?: list<string>, signatureRrdatas?: list<string>, ttl?: int, type?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only).
  --is-serving: oneof<nothing, bool> # If the DNS queries for the zone will be served.
  --kind: string # default: dns#change
  --start-time: string # The time that this operation was started by the server (output only). This is in RFC3339 text format.
  --status: string@status-completer # Status of the operation (output only). A status of "done" means that the request to update the authoritative servers has been sent, but the servers might not be updated yet.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: additions, var: additions}, {name: deletions, var: deletions}, {name: id, var: id}, {name: isServing, var: is_serving}, {name: kind, var: kind}, {name: startTime, var: start_time}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, additions: $additions, deletions: $deletions, id: $id, is_serving: $is_serving, kind: $kind, start_time: $start_time, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing Change.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes/{changeId}
# Returns: record<additions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, deletions: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>, id: string, isServing: bool, kind: string, startTime: string, status: string>
# operationId: dns.changes.get
export def "dns-changes-get" [
  project: string
  location: string
  managed_zone: string
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/changes/{changeId}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: changeId, var: change_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, change_id: $change_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates DnsKeys to a ResourceRecordSet collection.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys
# Returns: record<dnsKeys: table<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, header: record<operationId: string>, kind: string, nextPageToken: string>
# operationId: dns.dnsKeys.list
export def "dns-dns-keys-list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --digest-type: string # An optional comma-separated list of digest types to compute and display for key signing keys. If omitted, the recommended digest type is computed and displayed.
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: digestType, var: digest_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, digest_type: $digest_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing DnsKey.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys/{dnsKeyId}
# Returns: record<algorithm: string, creationTime: string, description: string, digests: table<digest: string, type: string>, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>
# operationId: dns.dnsKeys.get
export def "dns-dns-keys-get" [
  project: string
  location: string
  managed_zone: string
  dns_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --digest-type: string # An optional comma-separated list of digest types to compute and display for key signing keys. If omitted, the recommended digest type is computed and displayed.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/dnsKeys/{dnsKeyId}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: dnsKeyId, var: dns_key_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}, {name: digestType, var: digest_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, dns_key_id: $dns_key_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, digest_type: $digest_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates Operations for the given ManagedZone.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations
# Returns: record<header: record<operationId: string>, kind: string, nextPageToken: string, operations: table<dnsKeyContext: record, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record>>
# operationId: dns.managedZoneOperations.list
export def "dns-managed-zone-operations-list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --sort-by: string@sort-by-completer-1 # Sorting criterion. The only supported values are START_TIME and ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: sortBy, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing Operation.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations/{operation}
# Returns: record<dnsKeyContext: record<newValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>, oldValue: record<algorithm: string, creationTime: string, description: string, digests: list, id: string, isActive: bool, keyLength: int, keyTag: int, kind: string, publicKey: string, type: string>>, id: string, kind: string, startTime: string, status: string, type: string, user: string, zoneContext: record<newValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>, oldValue: record<cloudLoggingConfig: record, creationTime: string, description: string, dnsName: string, dnssecConfig: record, forwardingConfig: record, id: string, kind: string, labels: record, name: string, nameServerSet: string, nameServers: list, peeringConfig: record, privateVisibilityConfig: record, reverseLookupConfig: record, serviceDirectoryConfig: record, visibility: string>>>
# operationId: dns.managedZoneOperations.get
export def "dns-managed-zone-operations-get" [
  project: string
  location: string
  managed_zone: string
  operation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/operations/{operation}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: operation, var: operation}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, operation: $operation, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates ResourceRecordSets that you have created but not yet deleted.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets
# Returns: record<header: record<operationId: string>, kind: string, nextPageToken: string, rrsets: table<kind: string, name: string, routingPolicy: record, rrdatas: list, signatureRrdatas: list, ttl: int, type: string>>
# operationId: dns.resourceRecordSets.list
export def "dns-resource-record-sets-list" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --name: string # Restricts the list to return only records with this fully qualified domain name.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
  --type: string # Restricts the list to return only records of this type. If present, the "name" parameter must also be present.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: name, var: name}, {name: pageToken, var: page_token}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, name: $name, page_token: $page_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ResourceRecordSet.
#
# POST /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets
# Returns: record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>
# operationId: dns.resourceRecordSets.create
export def "dns-resource-record-sets-create" [
  project: string
  location: string
  managed_zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --kind: string # default: dns#resourceRecordSet
  --name: string # For example, www.example.com.
  --routing-policy: record # A RRSetRoutingPolicy represents ResourceRecordSet data that is returned dynamically with the response varying based on configured properties such as geolocation or by weighted random selection. — shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
  --rrdatas: list<string> # As defined in RFC 1035 (section 5) and RFC 1034 (section 3.6.1) -- see examples.
  --signature-rrdatas: list<string> # As defined in RFC 4034 (section 3.2).
  --ttl: int # Number of seconds that this ResourceRecordSet can be cached by resolvers. (format: int32)
  --type: string # The identifier of a supported record type. See the list of Supported DNS record types.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: name, var: name}, {name: routingPolicy, var: routing_policy}, {name: rrdatas, var: rrdatas}, {name: signatureRrdatas, var: signature_rrdatas}, {name: ttl, var: ttl}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, kind: $kind, name: $name, routing_policy: $routing_policy, rrdatas: $rrdatas, signature_rrdatas: $signature_rrdatas, ttl: $ttl, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created ResourceRecordSet.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# operationId: dns.resourceRecordSets.delete
export def "dns-resource-record-sets-delete" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: name, var: name}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, name: $name, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing ResourceRecordSet.
#
# GET /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# Returns: record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>
# operationId: dns.resourceRecordSets.get
export def "dns-resource-record-sets-get" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: name, var: name}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, name: $name, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a partial update to an existing ResourceRecordSet.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}
# Returns: record<kind: string, name: string, routingPolicy: record<geo: record<enableFencing: bool, items: list, kind: string>, kind: string, primaryBackup: record<backupGeoTargets: record, kind: string, primaryTargets: record, trickleTraffic: float>, wrr: record<items: list, kind: string>>, rrdatas: list<string>, signatureRrdatas: list<string>, ttl: int, type: string>
# operationId: dns.resourceRecordSets.patch
export def "dns-resource-record-sets-patch" [
  project: string
  location: string
  managed_zone: string
  name: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --kind: string # default: dns#resourceRecordSet
  --body-name: string # For example, www.example.com. (spec name: name)
  --routing-policy: record # A RRSetRoutingPolicy represents ResourceRecordSet data that is returned dynamically with the response varying based on configured properties such as geolocation or by weighted random selection. — shape: {geo?: record, kind?: string, primaryBackup?: record, wrr?: record}
  --rrdatas: list<string> # As defined in RFC 1035 (section 5) and RFC 1034 (section 3.6.1) -- see examples.
  --signature-rrdatas: list<string> # As defined in RFC 4034 (section 3.2).
  --ttl: int # Number of seconds that this ResourceRecordSet can be cached by resolvers. (format: int32)
  --body-type: string # The identifier of a supported record type. See the list of Supported DNS record types. (spec name: type)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dns/v2/projects/{project}/locations/{location}/managedZones/{managedZone}/rrsets/{name}/{type}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: managedZone, var: managed_zone}, {name: name, var: name}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: name, var: body_name}, {name: routingPolicy, var: routing_policy}, {name: rrdatas, var: rrdatas}, {name: signatureRrdatas, var: signature_rrdatas}, {name: ttl, var: ttl}, {name: type, var: body_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, managed_zone: $managed_zone, name: $name, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, kind: $kind, body_name: $body_name, routing_policy: $routing_policy, rrdatas: $rrdatas, signature_rrdatas: $signature_rrdatas, ttl: $ttl, body_type: $body_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates all Policies associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/policies
# Returns: record<header: record<operationId: string>, kind: string, nextPageToken: string, policies: table<alternativeNameServerConfig: record, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list>>
# operationId: dns.policies.list
export def "dns-policies-list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/policies"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Policy.
#
# POST /dns/v2/projects/{project}/locations/{location}/policies
# Returns: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>>
# operationId: dns.policies.create
export def "dns-policies-create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/policies"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternativeNameServerConfig, var: alternative_name_server_config}, {name: description, var: description}, {name: enableInboundForwarding, var: enable_inbound_forwarding}, {name: enableLogging, var: enable_logging}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: networks, var: networks}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, alternative_name_server_config: $alternative_name_server_config, description: $description, enable_inbound_forwarding: $enable_inbound_forwarding, enable_logging: $enable_logging, id: $id, kind: $kind, name: $name, networks: $networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created Policy. Fails if the policy is still being referenced by a network.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# operationId: dns.policies.delete
export def "dns-policies-delete" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/v2/projects/{project}/locations/{location}/policies/{policy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: policy, var: policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, policy: $policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing Policy.
#
# GET /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# Returns: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list<record>>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: table<kind: string, networkUrl: string>>
# operationId: dns.policies.get
export def "dns-policies-get" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/policies/{policy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: policy, var: policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, policy: $policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a partial update to an existing Policy.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# Returns: record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>>
# operationId: dns.policies.patch
export def "dns-policies-patch" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dns/v2/projects/{project}/locations/{location}/policies/{policy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: policy, var: policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternativeNameServerConfig, var: alternative_name_server_config}, {name: description, var: description}, {name: enableInboundForwarding, var: enable_inbound_forwarding}, {name: enableLogging, var: enable_logging}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: networks, var: networks}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, policy: $policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, alternative_name_server_config: $alternative_name_server_config, description: $description, enable_inbound_forwarding: $enable_inbound_forwarding, enable_logging: $enable_logging, id: $id, kind: $kind, name: $name, networks: $networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Policy.
#
# PUT /dns/v2/projects/{project}/locations/{location}/policies/{policy}
# Returns: record<header: record<operationId: string>, policy: record<alternativeNameServerConfig: record<kind: string, targetNameServers: list>, description: string, enableInboundForwarding: bool, enableLogging: bool, id: string, kind: string, name: string, networks: list<record>>>
# operationId: dns.policies.update
export def "dns-policies-update" [
  project: string
  location: string
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --alternative-name-server-config: record # shape: {kind?: string, targetNameServers?: list}
  --description: string # A mutable string of at most 1024 characters associated with this resource for the user's convenience. Has no effect on the policy's function.
  --enable-inbound-forwarding: oneof<nothing, bool> # Allows networks bound to this policy to receive DNS queries sent by VMs or applications over VPN connections. When enabled, a virtual IP address is allocated from each of the subnetworks that are bound to this policy.
  --enable-logging: oneof<nothing, bool> # Controls whether logging is enabled for the networks bound to this policy. Defaults to no logging if not set.
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: uint64)
  --kind: string # default: dns#policy
  --name: string # User-assigned name for this policy.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dns/v2/projects/{project}/locations/{location}/policies/{policy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: policy, var: policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternativeNameServerConfig, var: alternative_name_server_config}, {name: description, var: description}, {name: enableInboundForwarding, var: enable_inbound_forwarding}, {name: enableLogging, var: enable_logging}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: networks, var: networks}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, policy: $policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, alternative_name_server_config: $alternative_name_server_config, description: $description, enable_inbound_forwarding: $enable_inbound_forwarding, enable_logging: $enable_logging, id: $id, kind: $kind, name: $name, networks: $networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates all Response Policies associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies
# Returns: record<header: record<operationId: string>, nextPageToken: string, responsePolicies: table<description: string, gkeClusters: list, id: string, kind: string, labels: record, networks: list, responsePolicyName: string>>
# operationId: dns.responsePolicies.list
export def "dns-response-policies-list" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Response Policy
#
# POST /dns/v2/projects/{project}/locations/{location}/responsePolicies
# Returns: record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string>
# operationId: dns.responsePolicies.create
export def "dns-response-policies-create" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: gkeClusters, var: gke_clusters}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: networks, var: networks}, {name: responsePolicyName, var: response_policy_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, description: $description, gke_clusters: $gke_clusters, id: $id, kind: $kind, labels: $labels, networks: $networks, response_policy_name: $response_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created Response Policy. Fails if the response policy is non-empty or still being referenced by a network.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# operationId: dns.responsePolicies.delete
export def "dns-response-policies-delete" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing Response Policy.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# Returns: record<description: string, gkeClusters: table<gkeClusterName: string, kind: string>, id: string, kind: string, labels: record, networks: table<kind: string, networkUrl: string>, responsePolicyName: string>
# operationId: dns.responsePolicies.get
export def "dns-response-policies-get" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a partial update to an existing Response Policy.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# Returns: record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>>
# operationId: dns.responsePolicies.patch
export def "dns-response-policies-patch" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: gkeClusters, var: gke_clusters}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: networks, var: networks}, {name: responsePolicyName, var: response_policy_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, description: $description, gke_clusters: $gke_clusters, id: $id, kind: $kind, labels: $labels, networks: $networks, response_policy_name: $response_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Response Policy.
#
# PUT /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}
# Returns: record<header: record<operationId: string>, responsePolicy: record<description: string, gkeClusters: list<record>, id: string, kind: string, labels: record, networks: list<record>, responsePolicyName: string>>
# operationId: dns.responsePolicies.update
export def "dns-response-policies-update" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --description: string # User-provided description for this Response Policy.
  --gke-clusters: list # The list of Google Kubernetes Engine clusters to which this response policy is applied. — item shape: {gkeClusterName?: string, kind?: string}
  --id: string # Unique identifier for the resource; defined by the server (output only). (format: int64)
  --kind: string # default: dns#responsePolicy
  --labels: record # User labels.
  --networks: list # List of network names specifying networks to which this policy is applied. — item shape: {kind?: string, networkUrl?: string}
  --response-policy-name: string # User assigned name for this Response Policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: gkeClusters, var: gke_clusters}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: networks, var: networks}, {name: responsePolicyName, var: response_policy_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, description: $description, gke_clusters: $gke_clusters, id: $id, kind: $kind, labels: $labels, networks: $networks, response_policy_name: $response_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates all Response Policy Rules associated with a project.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules
# Returns: record<header: record<operationId: string>, nextPageToken: string, responsePolicyRules: table<behavior: string, dnsName: string, kind: string, localData: record, ruleName: string>>
# operationId: dns.responsePolicyRules.list
export def "dns-response-policy-rules-list" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-results: int # Optional. Maximum number of results to be returned. If unspecified, the server decides how many results to return.
  --page-token: string # Optional. A tag returned by a previous list request that was truncated. Use this parameter to continue a previous list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Response Policy Rule.
#
# POST /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules
# Returns: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string>
# operationId: dns.responsePolicyRules.create
export def "dns-response-policy-rules-create" [
  project: string
  location: string
  response_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: behavior, var: behavior}, {name: dnsName, var: dns_name}, {name: kind, var: kind}, {name: localData, var: local_data}, {name: ruleName, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, behavior: $behavior, dns_name: $dns_name, kind: $kind, local_data: $local_data, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a previously created Response Policy Rule.
#
# DELETE /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# operationId: dns.responsePolicyRules.delete
export def "dns-response-policy-rules-delete" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}, {name: responsePolicyRule, var: response_policy_rule}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, response_policy_rule: $response_policy_rule, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the representation of an existing Response Policy Rule.
#
# GET /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# Returns: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list<record>>, ruleName: string>
# operationId: dns.responsePolicyRules.get
export def "dns-response-policy-rules-get" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}, {name: responsePolicyRule, var: response_policy_rule}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, response_policy_rule: $response_policy_rule, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a partial update to an existing Response Policy Rule.
#
# PATCH /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# Returns: record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>>
# operationId: dns.responsePolicyRules.patch
export def "dns-response-policy-rules-patch" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}, {name: responsePolicyRule, var: response_policy_rule}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: behavior, var: behavior}, {name: dnsName, var: dns_name}, {name: kind, var: kind}, {name: localData, var: local_data}, {name: ruleName, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, response_policy_rule: $response_policy_rule, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, behavior: $behavior, dns_name: $dns_name, kind: $kind, local_data: $local_data, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Response Policy Rule.
#
# PUT /dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}
# Returns: record<header: record<operationId: string>, responsePolicyRule: record<behavior: string, dnsName: string, kind: string, localData: record<localDatas: list>, ruleName: string>>
# operationId: dns.responsePolicyRules.update
export def "dns-response-policy-rules-update" [
  project: string
  location: string
  response_policy: string
  response_policy_rule: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-operation-id: string # For mutating operation requests only. An optional identifier specified by the client. Must be unique for operation resources in the Operations collection.
  --behavior: string@behavior-completer # Answer this query with a behavior rather than DNS data.
  --dns-name: string # The DNS name (wildcard or exact) to apply this rule to. Must be unique within the Response Policy Rule.
  --kind: string # default: dns#responsePolicyRule
  --local-data: record # shape: {localDatas?: list}
  --rule-name: string # An identifier for this rule. Must be unique with the ResponsePolicy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/dns/v2/projects/{project}/locations/{location}/responsePolicies/{responsePolicy}/rules/{responsePolicyRule}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: responsePolicy, var: response_policy}, {name: responsePolicyRule, var: response_policy_rule}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientOperationId, var: client_operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: behavior, var: behavior}, {name: dnsName, var: dns_name}, {name: kind, var: kind}, {name: localData, var: local_data}, {name: ruleName, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, response_policy: $response_policy, response_policy_rule: $response_policy_rule, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_operation_id: $client_operation_id, behavior: $behavior, dns_name: $dns_name, kind: $kind, local_data: $local_data, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /dns/v2/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dns.managedZones.getIamPolicy
export def "dns-managed-zones-get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /dns/v2/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dns.managedZones.setIamPolicy
export def "dns-managed-zones-set-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, policy: $policy, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this returns an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /dns/v2/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: dns.managedZones.testIamPermissions
export def "dns-managed-zones-test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dns/v2/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
