# Auto-generated client for Search Ads 360 Reporting API v0
# Source: https://api.apis.guru/v2/specs/googleapis.com/searchads360/v0/openapi.json
# Auth: --token flag or $env.SEARCH_ADS_360_REPORTING_API_TOKEN

const CLIENT = {
  base_url: "https://searchads360.googleapis.com"
  token_env_var: "SEARCH_ADS_360_REPORTING_API_TOKEN"
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

def base-url-completer [] { ["https://searchads360.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def summary-row-setting-completer [] { ["NO_SUMMARY_ROW" "SUMMARY_ROW_ONLY" "SUMMARY_ROW_WITH_RESULTS" "UNKNOWN" "UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    searchads360-customers-custom-columns-list: "record<customColumns: table<description: string, id: string, name: string, queryable: bool, referencedSystemColumns: list, referencesAttributes: bool, referencesMetrics: bool, resourceName: string, valueType: string>>"
    searchads360-customers-search-ads360-search: "record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, nextPageToken: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>, totalResultsCount: string>"
    searchads360-customers-search-ads360-search-stream: "record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, requestId: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>>"
    searchads360-search-ads360-fields-search: "record<nextPageToken: string, results: table<attributeResources: list, category: string, dataType: string, enumValues: list, filterable: bool, isRepeated: bool, metrics: list, name: string, resourceName: string, segments: list, selectable: bool, selectableWith: list, sortable: bool, typeUrl: string>, totalResultsCount: string>"
    searchads360-search-ads360-fields-get: "record<attributeResources: list<string>, category: string, dataType: string, enumValues: list<string>, filterable: bool, isRepeated: bool, metrics: list<string>, name: string, resourceName: string, segments: list<string>, selectable: bool, selectableWith: list<string>, sortable: bool, typeUrl: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["searchads360-customers-custom-columns-list" "searchads360-customers-search-ads360-search" "searchads360-customers-search-ads360-search-stream" "searchads360-search-ads360-fields-search" "searchads360-search-ads360-fields-get" "commands"] | sort) } | get name | first)
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

# Returns all the custom columns associated with the customer in full detail.
#
# GET /v0/customers/{customerId}/customColumns
# Returns: record<customColumns: table<description: string, id: string, name: string, queryable: bool, referencedSystemColumns: list, referencesAttributes: bool, referencesMetrics: bool, resourceName: string, valueType: string>>
# operationId: searchads360.customers.customColumns.list
export def "searchads360-customers-custom-columns-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0/customers/{customerId}/customColumns"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all rows that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:search
# Returns: record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, nextPageToken: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>, totalResultsCount: string>
# operationId: searchads360.customers.searchAds360.search
export def "searchads360-customers-search-ads360-search" [
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
  --page-size: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --page-token: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --query: string # Required. The query string.
  --return-total-results-count: oneof<nothing, bool> # If true, the total number of results that match the query ignoring the LIMIT clause will be included in the response. Default is false.
  --summary-row-setting: string@summary-row-setting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not executed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0/customers/{customerId}/searchAds360:search"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: query, var: query}, {name: returnTotalResultsCount, var: return_total_results_count}, {name: summaryRowSetting, var: summary_row_setting}, {name: validateOnly, var: validate_only}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, query: $query, return_total_results_count: $return_total_results_count, summary_row_setting: $summary_row_setting, validate_only: $validate_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all rows that match the search stream query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:searchStream
# Returns: record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, requestId: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>>
# operationId: searchads360.customers.searchAds360.searchStream
export def "searchads360-customers-search-ads360-search-stream" [
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
  --batch-size: int # The number of rows that are returned in each stream response batch. When too large batch is requested, the server may decide to further limit the number of returned rows. (format: int32)
  --query: string # Required. The query string.
  --summary-row-setting: string@summary-row-setting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0/customers/{customerId}/searchAds360:searchStream"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: batchSize, var: batch_size}, {name: query, var: query}, {name: summaryRowSetting, var: summary_row_setting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, batch_size: $batch_size, query: $query, summary_row_setting: $summary_row_setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all fields that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/searchAds360Fields:search
# Returns: record<nextPageToken: string, results: table<attributeResources: list, category: string, dataType: string, enumValues: list, filterable: bool, isRepeated: bool, metrics: list, name: string, resourceName: string, segments: list, selectable: bool, selectableWith: list, sortable: bool, typeUrl: string>, totalResultsCount: string>
# operationId: searchads360.searchAds360Fields.search
export def "searchads360-search-ads360-fields-search" [
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
  --page-size: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --page-token: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --query: string # Required. The query string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0/searchAds360Fields:search"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns just the requested field. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QuotaError]() [RequestError]()
#
# GET /v0/{resourceName}
# Returns: record<attributeResources: list<string>, category: string, dataType: string, enumValues: list<string>, filterable: bool, isRepeated: bool, metrics: list<string>, name: string, resourceName: string, segments: list<string>, selectable: bool, selectableWith: list<string>, sortable: bool, typeUrl: string>
# operationId: searchads360.searchAds360Fields.get
export def "searchads360-search-ads360-fields-get" [
  resource_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0/{resourceName}"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
