# Auto-generated client for NBA v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/nba-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.NBA_V3_STATS_TOKEN

const CLIENT = {
  base_url: "http://azure-api.sportsdata.io/v3/nba/stats"
  token_env_var: "NBA_V3_STATS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: ocp-apim-subscription-key, in: header, header_name: Ocp-Apim-Subscription-Key, prefix: ""}
    {name: query-key, in: query, header_name: key, prefix: ""}
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/nba/stats" "https://azure-api.sportsdata.io/v3/nba/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }

# Completers for enum parameters
def format-completer [] { ["JSON" "XML"] }
def format-completer-1 [] { ["json" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    all-stars: "table<Name: string, PlayerID: int, Position: string, Team: string, TeamID: int>"
    teams-all: "table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string>"
    are-games-in-progress: "bool"
    box-score: "record<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayScore: int, GameID: int, HomeScore: int, Name: string, Number: int, QuarterID: int>, TeamGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>>"
    box-scores-by-date: "table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>>"
    box-scores-by-date-delta: "table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>>"
    current-season: "record<ApiSeason: string, Description: string, EndYear: int, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, SeasonType: string, StartYear: int>"
    dfs-slates-by-date: "table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>>"
    player-details-by-free-agent: "table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>"
    schedules: "table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>"
    games-by-date: "table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>"
    news: "table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>"
    news-by-date: "table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>"
    news-by-player: "table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>"
    player-details-by-player: "record<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>"
    player-game-stats-by-date: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>"
    player-game-stats-by-player: "record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>"
    player-game-logs-by-season: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>"
    player-season-stats: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>"
    player-season-stats-by-player: "record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>"
    player-season-stats-by-team: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>"
    player-details-by-active: "table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>"
    players-by-team: "table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>"
    stadiums: "table<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>"
    standings: "table<AwayLosses: int, AwayWins: int, City: string, Conference: string, ConferenceLosses: int, ConferenceRank: int, ConferenceWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionWins: int, GamesBack: float, GlobalTeamID: int, HomeLosses: int, HomeWins: int, Key: string, LastTenLosses: int, LastTenWins: int, Losses: int, Name: string, Percentage: float, PointsPerGameAgainst: float, PointsPerGameFor: float, Season: int, SeasonType: int, Streak: int, StreakDescription: string, TeamID: int, Wins: int>"
    team-game-stats-by-date: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>"
    team-game-logs-by-season: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>"
    team-season-stats: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>"
    team-stats-allowed-by-position: "table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>"
    teams-active: "table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["all-stars" "teams-all" "are-games-in-progress" "box-score" "box-scores-by-date" "box-scores-by-date-delta" "current-season" "dfs-slates-by-date" "player-details-by-free-agent" "schedules" "games-by-date" "news" "news-by-date" "news-by-player" "player-details-by-player" "player-game-stats-by-date" "player-game-stats-by-player" "player-game-logs-by-season" "player-season-stats" "player-season-stats-by-player" "player-season-stats-by-team" "player-details-by-active" "players-by-team" "stadiums" "standings" "team-game-stats-by-date" "team-game-logs-by-season" "team-season-stats" "team-stats-allowed-by-position" "teams-active" "commands"] | sort) } | get name | first)
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

# All-Stars
#
# GET /{format}/AllStars/{season}
# Returns: table<Name: string, PlayerID: int, Position: string, Team: string, TeamID: int>
# operationId: AllStars
export def "all-stars" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/AllStars/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Teams (All)
#
# GET /{format}/AllTeams
# Returns: table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string>
# operationId: TeamsAll
export def "teams-all" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/AllTeams"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Are Games In Progress
#
# GET /{format}/AreAnyGamesInProgress
# Returns: bool
# operationId: AreGamesInProgress
export def "are-games-in-progress" [
  format: string@format-completer
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
    path: "/{format}/AreAnyGamesInProgress"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Box Score
#
# GET /{format}/BoxScore/{gameid}
# Returns: record<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayScore: int, GameID: int, HomeScore: int, Name: string, Number: int, QuarterID: int>, TeamGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>>
# operationId: BoxScore
export def "box-score" [
  format: string@format-completer
  gameid: string
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
    path: "/{format}/BoxScore/{gameid}"
    path_params: [{name: format, var: format}, {name: gameid, var: gameid}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, gameid: $gameid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Box Scores by Date
#
# GET /{format}/BoxScores/{date}
# Returns: table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>>
# operationId: BoxScoresByDate
export def "box-scores-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/BoxScores/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Box Scores by Date Delta
#
# GET /{format}/BoxScoresDelta/{date}/{minutes}
# Returns: table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>>
# operationId: BoxScoresByDateDelta
export def "box-scores-by-date-delta" [
  format: string@format-completer
  date: string
  minutes: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/BoxScoresDelta/{date}/{minutes}"
    path_params: [{name: format, var: format}, {name: date, var: date}, {name: minutes, var: minutes}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date, minutes: $minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Current Season
#
# GET /{format}/CurrentSeason
# Returns: record<ApiSeason: string, Description: string, EndYear: int, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, SeasonType: string, StartYear: int>
# operationId: CurrentSeason
export def "current-season" [
  format: string@format-completer
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
    path: "/{format}/CurrentSeason"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DFS Slates by Date
#
# GET /{format}/DfsSlatesByDate/{date}
# Returns: table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>>
# operationId: DfsSlatesByDate
export def "dfs-slates-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/DfsSlatesByDate/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Details by Free Agent
#
# GET /{format}/FreeAgents
# Returns: table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>
# operationId: PlayerDetailsByFreeAgent
export def "player-details-by-free-agent" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/FreeAgents"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedules
#
# GET /{format}/Games/{season}
# Returns: table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>
# operationId: Schedules
export def "schedules" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/Games/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Games by Date
#
# GET /{format}/GamesByDate/{date}
# Returns: table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>
# operationId: GamesByDate
export def "games-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/GamesByDate/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News
#
# GET /{format}/News
# Returns: table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>
# operationId: News
export def "news" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/News"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News by Date
#
# GET /{format}/NewsByDate/{date}
# Returns: table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>
# operationId: NewsByDate
export def "news-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/NewsByDate/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# News by Player
#
# GET /{format}/NewsByPlayerID/{playerid}
# Returns: table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>
# operationId: NewsByPlayer
export def "news-by-player" [
  format: string@format-completer
  playerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/NewsByPlayerID/{playerid}"
    path_params: [{name: format, var: format}, {name: playerid, var: playerid}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, playerid: $playerid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Details by Player
#
# GET /{format}/Player/{playerid}
# Returns: record<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>
# operationId: PlayerDetailsByPlayer
export def "player-details-by-player" [
  format: string@format-completer
  playerid: string
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
    path: "/{format}/Player/{playerid}"
    path_params: [{name: format, var: format}, {name: playerid, var: playerid}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, playerid: $playerid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Game Stats by Date
#
# GET /{format}/PlayerGameStatsByDate/{date}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>
# operationId: PlayerGameStatsByDate
export def "player-game-stats-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/PlayerGameStatsByDate/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Game Stats by Player
#
# GET /{format}/PlayerGameStatsByPlayer/{date}/{playerid}
# Returns: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>
# operationId: PlayerGameStatsByPlayer
export def "player-game-stats-by-player" [
  format: string@format-completer
  date: string
  playerid: string
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
    path: "/{format}/PlayerGameStatsByPlayer/{date}/{playerid}"
    path_params: [{name: format, var: format}, {name: date, var: date}, {name: playerid, var: playerid}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date, playerid: $playerid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Game Logs By Season
#
# GET /{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>
# operationId: PlayerGameLogsBySeason
export def "player-game-logs-by-season" [
  format: string@format-completer
  season: string
  playerid: string
  numberofgames: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}"
    path_params: [{name: format, var: format}, {name: season, var: season}, {name: playerid, var: playerid}, {name: numberofgames, var: numberofgames}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season, playerid: $playerid, numberofgames: $numberofgames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Season Stats
#
# GET /{format}/PlayerSeasonStats/{season}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>
# operationId: PlayerSeasonStats
export def "player-season-stats" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/PlayerSeasonStats/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Season Stats By Player
#
# GET /{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}
# Returns: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player" [
  format: string@format-completer
  season: string
  playerid: string
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
    path: "/{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}"
    path_params: [{name: format, var: format}, {name: season, var: season}, {name: playerid, var: playerid}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season, playerid: $playerid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Season Stats by Team
#
# GET /{format}/PlayerSeasonStatsByTeam/{season}/{team}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float>
# operationId: PlayerSeasonStatsByTeam
export def "player-season-stats-by-team" [
  format: string@format-completer
  season: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/PlayerSeasonStatsByTeam/{season}/{team}"
    path_params: [{name: format, var: format}, {name: season, var: season}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Details by Active
#
# GET /{format}/Players
# Returns: table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>
# operationId: PlayerDetailsByActive
export def "player-details-by-active" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/Players"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Players by Team
#
# GET /{format}/Players/{team}
# Returns: table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int>
# operationId: PlayersByTeam
export def "players-by-team" [
  format: string@format-completer
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/Players/{team}"
    path_params: [{name: format, var: format}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stadiums
#
# GET /{format}/Stadiums
# Returns: table<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>
# operationId: Stadiums
export def "stadiums" [
  format: string@format-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/Stadiums"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Standings
#
# GET /{format}/Standings/{season}
# Returns: table<AwayLosses: int, AwayWins: int, City: string, Conference: string, ConferenceLosses: int, ConferenceRank: int, ConferenceWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionWins: int, GamesBack: float, GlobalTeamID: int, HomeLosses: int, HomeWins: int, Key: string, LastTenLosses: int, LastTenWins: int, Losses: int, Name: string, Percentage: float, PointsPerGameAgainst: float, PointsPerGameFor: float, Season: int, SeasonType: int, Streak: int, StreakDescription: string, TeamID: int, Wins: int>
# operationId: Standings
export def "standings" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/Standings/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team Game Stats by Date
#
# GET /{format}/TeamGameStatsByDate/{date}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>
# operationId: TeamGameStatsByDate
export def "team-game-stats-by-date" [
  format: string@format-completer
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/TeamGameStatsByDate/{date}"
    path_params: [{name: format, var: format}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team Game Logs By Season
#
# GET /{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>
# operationId: TeamGameLogsBySeason
export def "team-game-logs-by-season" [
  format: string@format-completer
  season: string
  teamid: string
  numberofgames: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}"
    path_params: [{name: format, var: format}, {name: season, var: season}, {name: teamid, var: teamid}, {name: numberofgames, var: numberofgames}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season, teamid: $teamid, numberofgames: $numberofgames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team Season Stats
#
# GET /{format}/TeamSeasonStats/{season}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>
# operationId: TeamSeasonStats
export def "team-season-stats" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/TeamSeasonStats/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team Stats Allowed by Position
#
# GET /{format}/TeamStatsAllowedByPosition/{season}
# Returns: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>
# operationId: TeamStatsAllowedByPosition
export def "team-stats-allowed-by-position" [
  format: string@format-completer
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/TeamStatsAllowedByPosition/{season}"
    path_params: [{name: format, var: format}, {name: season, var: season}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Teams (Active)
#
# GET /{format}/teams
# Returns: table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string>
# operationId: TeamsActive
export def "teams-active" [
  format: string@format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/{format}/teams"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: ocp-apim-subscription-key
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
