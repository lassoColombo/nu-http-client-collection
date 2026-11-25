# Auto-generated client for NBA Stats API version
# Source: https://api.apis.guru/v2/specs/nba.com/version/swagger.json
# Auth: --token flag or $env.NBA_STATS_API_TOKEN

const CLIENT = {
  base_url: "https://stats.nba.com/stats"
  token_env_var: "NBA_STATS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://stats.nba.com/stats"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-allstarballotpredictor" "get-boxscore" "get-boxscoreadvanced" "get-boxscoreadvancedv2" "get-boxscorefourfactors" "get-boxscorefourfactorsv2" "get-boxscoremisc" "get-boxscoremiscv2" "get-boxscoreplayertrackv2" "get-boxscorescoring" "get-boxscorescoringv2" "get-boxscoresummaryv2" "get-boxscoretraditionalv2" "get-boxscoreusage" "get-boxscoreusagev2" "get-common-team-years" "get-commonallplayers" "get-commonplayerinfo" "get-commonplayoffseries" "get-commonteamroster" "get-draftcombinedrillresults" "get-draftcombinenonstationaryshooting" "get-draftcombineplayeranthro" "get-draftcombinespotshooting" "get-draftcombinestats" "get-drafthistory" "get-franchisehistory" "get-homepageleaders" "get-homepagev2" "get-leaderstiles" "get-leaguedashlineups" "get-leaguedashplayerbiostats" "get-leaguedashplayerclutch" "get-leaguedashplayerptshot" "get-leaguedashplayershotlocations" "get-leaguedashplayerstats" "get-leaguedashptdefend" "get-leaguedashptteamdefend" "get-leaguedashteamclutch" "get-leaguedashteamptshot" "get-leaguedashteamshotlocations" "get-leaguedashteamstats" "get-leagueleaders" "get-playbyplay" "get-playbyplayv2" "get-playercareerstats" "get-playercompare" "get-playerdashboardbyclutch" "get-playerdashboardbygamesplits" "get-playerdashboardbygeneralsplits" "get-playerdashboardbylastngames" "get-playerdashboardbyopponent" "get-playerdashboardbyshootingsplits" "get-playerdashboardbyteamperformance" "get-playerdashboardbyyearoveryear" "get-playerdashptpass" "get-playerdashptreb" "get-playerdashptreboundlogs" "get-playerdashptshotdefend" "get-playerdashptshotlog" "get-playerdashptshots" "get-playergamelog" "get-playerprofile" "get-playerprofilev2" "get-playersvsplayers" "get-playervsplayer" "get-playoffpicture" "get-scoreboard" "get-scoreboard-v2" "get-shotchartdetail" "get-shotchartlineupdetail" "get-teamdashboardbyclutch" "get-teamdashboardbygamesplits" "get-teamdashboardbygeneralsplits" "get-teamdashboardbylastngames" "get-teamdashboardbyopponent" "get-teamdashboardbyshootingsplits" "get-teamdashboardbyteamperformance" "get-teamdashboardbyyearoveryear" "get-teamdashlineups" "get-teamdashptpass" "get-teamdashptreb" "get-teamdashptshots" "get-teamgamelog" "get-teaminfocommon" "get-teamplayerdashboard" "get-teamplayeronoffdetails" "get-teamplayeronoffsummary" "get-teamvsplayer" "get-teamyearbyyearstats" "get-video-status" "commands"] | sort) } | get name | first)
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

# GET /allstarballotpredictor
export def "get-allstarballotpredictor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --point-cap: string
  --west-player1: string # required
  --west-player2: string # required
  --west-player3: string # required
  --west-player4: string # required
  --west-player5: string # required
  --east-player1: string # required
  --east-player2: string # required
  --east-player3: string # required
  --east-player4: string # required
  --east-player5: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/allstarballotpredictor"
    query: [{name: PointCap, var: point_cap}, {name: WestPlayer1, var: west_player1, required: true}, {name: WestPlayer2, var: west_player2, required: true}, {name: WestPlayer3, var: west_player3, required: true}, {name: WestPlayer4, var: west_player4, required: true}, {name: WestPlayer5, var: west_player5, required: true}, {name: EastPlayer1, var: east_player1, required: true}, {name: EastPlayer2, var: east_player2, required: true}, {name: EastPlayer3, var: east_player3, required: true}, {name: EastPlayer4, var: east_player4, required: true}, {name: EastPlayer5, var: east_player5, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    point_cap: $point_cap, west_player1: $west_player1, west_player2: $west_player2, west_player3: $west_player3, west_player4: $west_player4, west_player5: $west_player5, east_player1: $east_player1, east_player2: $east_player2, east_player3: $east_player3, east_player4: $east_player4, east_player5: $east_player5
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscore
#
# DEPRECATED
@deprecated
export def "get-boxscore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscore"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoreadvanced
#
# DEPRECATED
@deprecated
export def "get-boxscoreadvanced" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoreadvanced"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoreadvancedv2
export def "get-boxscoreadvancedv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoreadvancedv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscorefourfactors
#
# DEPRECATED
@deprecated
export def "get-boxscorefourfactors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscorefourfactors"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscorefourfactorsv2
export def "get-boxscorefourfactorsv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscorefourfactorsv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoremisc
#
# DEPRECATED
@deprecated
export def "get-boxscoremisc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoremisc"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoremiscv2
export def "get-boxscoremiscv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoremiscv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoreplayertrackv2
export def "get-boxscoreplayertrackv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoreplayertrackv2"
    query: [{name: GameID, var: game_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscorescoring
#
# DEPRECATED
@deprecated
export def "get-boxscorescoring" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscorescoring"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscorescoringv2
export def "get-boxscorescoringv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscorescoringv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoresummaryv2
export def "get-boxscoresummaryv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoresummaryv2"
    query: [{name: GameID, var: game_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoretraditionalv2
export def "get-boxscoretraditionalv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoretraditionalv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoreusage
#
# DEPRECATED
@deprecated
export def "get-boxscoreusage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoreusage"
    query: [{name: GameID, var: game_id}, {name: StartPeriod, var: start_period}, {name: EndPeriod, var: end_period}, {name: StartRange, var: start_range}, {name: EndRange, var: end_range}, {name: RangeType, var: range_type}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /boxscoreusagev2
export def "get-boxscoreusagev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/boxscoreusagev2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}, {name: StartRange, var: start_range, required: true}, {name: EndRange, var: end_range, required: true}, {name: RangeType, var: range_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period, start_range: $start_range, end_range: $end_range, range_type: $range_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /commonTeamYears
export def "get-common-team-years" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/commonTeamYears"
    query: [{name: LeagueID, var: league_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /commonallplayers
export def "get-commonallplayers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season: string # required
  --is-only-current-season: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/commonallplayers"
    query: [{name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: IsOnlyCurrentSeason, var: is_only_current_season, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season: $season, is_only_current_season: $is_only_current_season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /commonplayerinfo
export def "get-commonplayerinfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/commonplayerinfo"
    query: [{name: PlayerID, var: player_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /commonplayoffseries
export def "get-commonplayoffseries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/commonplayoffseries"
    query: [{name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /commonteamroster
export def "get-commonteamroster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string # required
  --team-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/commonteamroster"
    query: [{name: Season, var: season, required: true}, {name: TeamID, var: team_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season: $season, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /draftcombinedrillresults
export def "get-draftcombinedrillresults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/draftcombinedrillresults"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonYear, var: season_year, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_year: $season_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /draftcombinenonstationaryshooting
export def "get-draftcombinenonstationaryshooting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/draftcombinenonstationaryshooting"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonYear, var: season_year, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_year: $season_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /draftcombineplayeranthro
export def "get-draftcombineplayeranthro" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/draftcombineplayeranthro"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonYear, var: season_year, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_year: $season_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /draftcombinespotshooting
export def "get-draftcombinespotshooting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/draftcombinespotshooting"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonYear, var: season_year, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_year: $season_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /draftcombinestats
export def "get-draftcombinestats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/draftcombinestats"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonYear, var: season_year, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_year: $season_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /drafthistory
export def "get-drafthistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/drafthistory"
    query: [{name: LeagueID, var: league_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /franchisehistory
export def "get-franchisehistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/franchisehistory"
    query: [{name: LeagueID, var: league_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /homepageleaders
export def "get-homepageleaders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat-category: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/homepageleaders"
    query: [{name: StatCategory, var: stat_category, required: true}, {name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerOrTeam, var: player_or_team, required: true}, {name: Game, var: game}, {name: Player, var: player}, {name: PlayerScope, var: player_scope, required: true}, {name: GameScope, var: game_scope, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    stat_category: $stat_category, league_id: $league_id, season: $season, season_type: $season_type, player_or_team: $player_or_team, game: $game, player: $player, player_scope: $player_scope, game_scope: $game_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /homepagev2
export def "get-homepagev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat-type: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/homepagev2"
    query: [{name: StatType, var: stat_type, required: true}, {name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerOrTeam, var: player_or_team, required: true}, {name: Game, var: game}, {name: Player, var: player}, {name: PlayerScope, var: player_scope, required: true}, {name: GameScope, var: game_scope, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    stat_type: $stat_type, league_id: $league_id, season: $season, season_type: $season_type, player_or_team: $player_or_team, game: $game, player: $player, player_scope: $player_scope, game_scope: $game_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaderstiles
export def "get-leaderstiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaderstiles"
    query: [{name: Stat, var: stat, required: true}, {name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerOrTeam, var: player_or_team, required: true}, {name: Game, var: game}, {name: Player, var: player}, {name: PlayerScope, var: player_scope, required: true}, {name: GameScope, var: game_scope, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    stat: $stat, league_id: $league_id, season: $season, season_type: $season_type, player_or_team: $player_or_team, game: $game, player: $player, player_scope: $player_scope, game_scope: $game_scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashlineups
export def "get-leaguedashlineups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-quantity: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashlineups"
    query: [{name: GroupQuantity, var: group_quantity, required: true}, {name: SeasonType, var: season_type, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    group_quantity: $group_quantity, season_type: $season_type, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashplayerbiostats
export def "get-leaguedashplayerbiostats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashplayerbiostats"
    query: [{name: PerMode, var: per_mode, required: true}, {name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, league_id: $league_id, season: $season, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashplayerclutch
export def "get-leaguedashplayerclutch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clutch-time: string # required
  --ahead-behind: string # required
  --point-diff: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashplayerclutch"
    query: [{name: ClutchTime, var: clutch_time, required: true}, {name: AheadBehind, var: ahead_behind, required: true}, {name: PointDiff, var: point_diff, required: true}, {name: GameScope, var: game_scope, required: true}, {name: PlayerExperience, var: player_experience, required: true}, {name: PlayerPosition, var: player_position, required: true}, {name: StarterBench, var: starter_bench, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    clutch_time: $clutch_time, ahead_behind: $ahead_behind, point_diff: $point_diff, game_scope: $game_scope, player_experience: $player_experience, player_position: $player_position, starter_bench: $starter_bench, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashplayerptshot
export def "get-leaguedashplayerptshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashplayerptshot"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, per_mode: $per_mode, season: $season, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashplayershotlocations
export def "get-leaguedashplayershotlocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --distance-range: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashplayershotlocations"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}, {name: DistanceRange, var: distance_range, required: true}, {name: GameScope, var: game_scope, required: true}, {name: PlayerExperience, var: player_experience, required: true}, {name: PlayerPosition, var: player_position, required: true}, {name: StarterBench, var: starter_bench, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games, distance_range: $distance_range, game_scope: $game_scope, player_experience: $player_experience, player_position: $player_position, starter_bench: $starter_bench
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashplayerstats
export def "get-leaguedashplayerstats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashplayerstats"
    query: [{name: GameScope, var: game_scope, required: true}, {name: PlayerExperience, var: player_experience, required: true}, {name: PlayerPosition, var: player_position, required: true}, {name: StarterBench, var: starter_bench, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_scope: $game_scope, player_experience: $player_experience, player_position: $player_position, starter_bench: $starter_bench, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashptdefend
export def "get-leaguedashptdefend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --defense-category: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashptdefend"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: DefenseCategory, var: defense_category, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, per_mode: $per_mode, season: $season, season_type: $season_type, defense_category: $defense_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashptteamdefend
export def "get-leaguedashptteamdefend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --defense-category: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashptteamdefend"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: DefenseCategory, var: defense_category, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, per_mode: $per_mode, season: $season, season_type: $season_type, defense_category: $defense_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashteamclutch
export def "get-leaguedashteamclutch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clutch-time: string # required
  --ahead-behind: string # required
  --point-diff: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashteamclutch"
    query: [{name: ClutchTime, var: clutch_time, required: true}, {name: AheadBehind, var: ahead_behind, required: true}, {name: PointDiff, var: point_diff, required: true}, {name: GameScope, var: game_scope, required: true}, {name: PlayerExperience, var: player_experience, required: true}, {name: PlayerPosition, var: player_position, required: true}, {name: StarterBench, var: starter_bench, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    clutch_time: $clutch_time, ahead_behind: $ahead_behind, point_diff: $point_diff, game_scope: $game_scope, player_experience: $player_experience, player_position: $player_position, starter_bench: $starter_bench, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashteamptshot
export def "get-leaguedashteamptshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashteamptshot"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, per_mode: $per_mode, season: $season, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashteamshotlocations
export def "get-leaguedashteamshotlocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --distance-range: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashteamshotlocations"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}, {name: DistanceRange, var: distance_range, required: true}, {name: GameScope, var: game_scope, required: true}, {name: PlayerExperience, var: player_experience, required: true}, {name: PlayerPosition, var: player_position, required: true}, {name: StarterBench, var: starter_bench, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games, distance_range: $distance_range, game_scope: $game_scope, player_experience: $player_experience, player_position: $player_position, starter_bench: $starter_bench
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leaguedashteamstats
export def "get-leaguedashteamstats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leaguedashteamstats"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /leagueleaders
export def "get-leagueleaders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --per-mode: string # required
  --stat-category: string
  --season: string # required
  --season-type: string # required
  --scope: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/leagueleaders"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PerMode, var: per_mode, required: true}, {name: StatCategory, var: stat_category}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Scope, var: scope, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, per_mode: $per_mode, stat_category: $stat_category, season: $season, season_type: $season_type, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playbyplay
export def "get-playbyplay" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playbyplay"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playbyplayv2
export def "get-playbyplayv2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playbyplayv2"
    query: [{name: GameID, var: game_id, required: true}, {name: StartPeriod, var: start_period, required: true}, {name: EndPeriod, var: end_period, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, start_period: $start_period, end_period: $end_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playercareerstats
export def "get-playercareerstats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --player-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playercareerstats"
    query: [{name: PerMode, var: per_mode, required: true}, {name: PlayerID, var: player_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playercompare
export def "get-playercompare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id-list: string # required
  --vs-player-id-list: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playercompare"
    query: [{name: PlayerIDList, var: player_id_list, required: true}, {name: VsPlayerIDList, var: vs_player_id_list, required: true}, {name: SeasonType, var: season_type, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    player_id_list: $player_id_list, vs_player_id_list: $vs_player_id_list, season_type: $season_type, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbyclutch
export def "get-playerdashboardbyclutch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbyclutch"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbygamesplits
export def "get-playerdashboardbygamesplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbygamesplits"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbygeneralsplits
export def "get-playerdashboardbygeneralsplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbygeneralsplits"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbylastngames
export def "get-playerdashboardbylastngames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbylastngames"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbyopponent
export def "get-playerdashboardbyopponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbyopponent"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbyshootingsplits
export def "get-playerdashboardbyshootingsplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbyshootingsplits"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbyteamperformance
export def "get-playerdashboardbyteamperformance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbyteamperformance"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashboardbyyearoveryear
export def "get-playerdashboardbyyearoveryear" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashboardbyyearoveryear"
    query: [{name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, player_id: $player_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptpass
export def "get-playerdashptpass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptpass"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptreb
export def "get-playerdashptreb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptreb"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptreboundlogs
#
# DEPRECATED
@deprecated
export def "get-playerdashptreboundlogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptreboundlogs"
    query: [{name: Season, var: season}, {name: SeasonType, var: season_type}, {name: PlayerID, var: player_id}, {name: TeamID, var: team_id}, {name: Outcome, var: outcome}, {name: Location, var: location}, {name: Month, var: month}, {name: SeasonSegment, var: season_segment}, {name: DateFrom, var: date_from}, {name: DateTo, var: date_to}, {name: OpponentTeamID, var: opponent_team_id}, {name: VsConference, var: vs_conference}, {name: VsDivision, var: vs_division}, {name: GameSegment, var: game_segment}, {name: Period, var: period}, {name: LastNGames, var: last_n_games}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptshotdefend
export def "get-playerdashptshotdefend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptshotdefend"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptshotlog
#
# DEPRECATED
@deprecated
export def "get-playerdashptshotlog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptshotlog"
    query: [{name: LeagueID, var: league_id}, {name: Season, var: season}, {name: SeasonType, var: season_type}, {name: PlayerID, var: player_id}, {name: TeamID, var: team_id}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerdashptshots
export def "get-playerdashptshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerdashptshots"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PlayerID, var: player_id, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, player_id: $player_id, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playergamelog
export def "get-playergamelog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playergamelog"
    query: [{name: PlayerID, var: player_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    player_id: $player_id, season: $season, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerprofile
export def "get-playerprofile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --player-id: string # required
  --season: string # required
  --season-type: string # required
  --graph-start-season: string # required
  --graph-end-season: string # required
  --graph-stat: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerprofile"
    query: [{name: LeagueID, var: league_id, required: true}, {name: PlayerID, var: player_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: GraphStartSeason, var: graph_start_season, required: true}, {name: GraphEndSeason, var: graph_end_season, required: true}, {name: GraphStat, var: graph_stat, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, player_id: $player_id, season: $season, season_type: $season_type, graph_start_season: $graph_start_season, graph_end_season: $graph_end_season, graph_stat: $graph_stat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playerprofilev2
export def "get-playerprofilev2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --player-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playerprofilev2"
    query: [{name: PerMode, var: per_mode, required: true}, {name: PlayerID, var: player_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playersvsplayers
export def "get-playersvsplayers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-team-id: string # required
  --player-id1: string # required
  --player-id2: string # required
  --player-id3: string # required
  --player-id4: string # required
  --player-id5: string # required
  --vs-team-id: string # required
  --vs-player-id1: string # required
  --vs-player-id2: string # required
  --vs-player-id3: string # required
  --vs-player-id4: string # required
  --vs-player-id5: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playersvsplayers"
    query: [{name: PlayerTeamID, var: player_team_id, required: true}, {name: PlayerID1, var: player_id1, required: true}, {name: PlayerID2, var: player_id2, required: true}, {name: PlayerID3, var: player_id3, required: true}, {name: PlayerID4, var: player_id4, required: true}, {name: PlayerID5, var: player_id5, required: true}, {name: VsTeamID, var: vs_team_id, required: true}, {name: VsPlayerID1, var: vs_player_id1, required: true}, {name: VsPlayerID2, var: vs_player_id2, required: true}, {name: VsPlayerID3, var: vs_player_id3, required: true}, {name: VsPlayerID4, var: vs_player_id4, required: true}, {name: VsPlayerID5, var: vs_player_id5, required: true}, {name: SeasonType, var: season_type, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    player_team_id: $player_team_id, player_id1: $player_id1, player_id2: $player_id2, player_id3: $player_id3, player_id4: $player_id4, player_id5: $player_id5, vs_team_id: $vs_team_id, vs_player_id1: $vs_player_id1, vs_player_id2: $vs_player_id2, vs_player_id3: $vs_player_id3, vs_player_id4: $vs_player_id4, vs_player_id5: $vs_player_id5, season_type: $season_type, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playervsplayer
export def "get-playervsplayer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string # required
  --vs-player-id: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playervsplayer"
    query: [{name: PlayerID, var: player_id, required: true}, {name: VsPlayerID, var: vs_player_id, required: true}, {name: SeasonType, var: season_type, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    player_id: $player_id, vs_player_id: $vs_player_id, season_type: $season_type, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /playoffpicture
export def "get-playoffpicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/playoffpicture"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonID, var: season_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_id: $season_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /scoreboard
export def "get-scoreboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-date: string # required
  --league-id: string # required
  --day-offset: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/scoreboard"
    query: [{name: GameDate, var: game_date, required: true}, {name: LeagueID, var: league_id, required: true}, {name: DayOffset, var: day_offset, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_date: $game_date, league_id: $league_id, day_offset: $day_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /scoreboardV2
export def "get-scoreboard-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-date: string # required
  --league-id: string # required
  --day-offset: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/scoreboardV2"
    query: [{name: GameDate, var: game_date, required: true}, {name: LeagueID, var: league_id, required: true}, {name: DayOffset, var: day_offset, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    game_date: $game_date, league_id: $league_id, day_offset: $day_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /shotchartdetail
export def "get-shotchartdetail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string # required
  --team-id: string # required
  --player-id: string # required
  --game-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --position: string # required
  --rookie-year: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --context-measure: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/shotchartdetail"
    query: [{name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: PlayerID, var: player_id, required: true}, {name: GameID, var: game_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: Position, var: position, required: true}, {name: RookieYear, var: rookie_year, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}, {name: ContextMeasure, var: context_measure, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season_type: $season_type, team_id: $team_id, player_id: $player_id, game_id: $game_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, position: $position, rookie_year: $rookie_year, game_segment: $game_segment, period: $period, last_n_games: $last_n_games, context_measure: $context_measure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /shotchartlineupdetail
export def "get-shotchartlineupdetail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --game-id: string # required
  --group-id: string # required
  --context-measure: string # required
  --context-filter: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/shotchartlineupdetail"
    query: [{name: LeagueID, var: league_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}, {name: GameID, var: game_id, required: true}, {name: GROUP_ID, var: group_id, required: true}, {name: ContextMeasure, var: context_measure, required: true}, {name: ContextFilter, var: context_filter, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season: $season, season_type: $season_type, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games, game_id: $game_id, group_id: $group_id, context_measure: $context_measure, context_filter: $context_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbyclutch
export def "get-teamdashboardbyclutch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbyclutch"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbygamesplits
export def "get-teamdashboardbygamesplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbygamesplits"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbygeneralsplits
export def "get-teamdashboardbygeneralsplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbygeneralsplits"
    query: [{name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season_type: $season_type, team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbylastngames
export def "get-teamdashboardbylastngames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbylastngames"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbyopponent
export def "get-teamdashboardbyopponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbyopponent"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbyshootingsplits
export def "get-teamdashboardbyshootingsplits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbyshootingsplits"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbyteamperformance
export def "get-teamdashboardbyteamperformance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbyteamperformance"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashboardbyyearoveryear
export def "get-teamdashboardbyyearoveryear" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashboardbyyearoveryear"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashlineups
export def "get-teamdashlineups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-quantity: string # required
  --game-id: string # required
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashlineups"
    query: [{name: GroupQuantity, var: group_quantity, required: true}, {name: GameID, var: game_id, required: true}, {name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    group_quantity: $group_quantity, game_id: $game_id, season_type: $season_type, team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashptpass
export def "get-teamdashptpass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashptpass"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashptreb
export def "get-teamdashptreb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashptreb"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamdashptshots
export def "get-teamdashptshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamdashptshots"
    query: [{name: PerMode, var: per_mode, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    per_mode: $per_mode, season: $season, season_type: $season_type, team_id: $team_id, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamgamelog
export def "get-teamgamelog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamgamelog"
    query: [{name: TeamID, var: team_id, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, season: $season, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teaminfocommon
export def "get-teaminfocommon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string # required
  --team-id: string # required
  --league-id: string # required
  --season-type: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teaminfocommon"
    query: [{name: Season, var: season, required: true}, {name: TeamID, var: team_id, required: true}, {name: LeagueID, var: league_id, required: true}, {name: SeasonType, var: season_type, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season: $season, team_id: $team_id, league_id: $league_id, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamplayerdashboard
export def "get-teamplayerdashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamplayerdashboard"
    query: [{name: SeasonType, var: season_type, required: true}, {name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    season_type: $season_type, team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamplayeronoffdetails
export def "get-teamplayeronoffdetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamplayeronoffdetails"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamplayeronoffsummary
export def "get-teamplayeronoffsummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamplayeronoffsummary"
    query: [{name: TeamID, var: team_id, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: SeasonType, var: season_type, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, season_type: $season_type, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamvsplayer
export def "get-teamvsplayer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string # required
  --vs-player-id: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamvsplayer"
    query: [{name: TeamID, var: team_id, required: true}, {name: VsPlayerID, var: vs_player_id, required: true}, {name: SeasonType, var: season_type, required: true}, {name: MeasureType, var: measure_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: PlusMinus, var: plus_minus, required: true}, {name: PaceAdjust, var: pace_adjust, required: true}, {name: Rank, var: rank, required: true}, {name: Season, var: season, required: true}, {name: Outcome, var: outcome, required: true}, {name: Location, var: location, required: true}, {name: Month, var: month, required: true}, {name: SeasonSegment, var: season_segment, required: true}, {name: DateFrom, var: date_from, required: true}, {name: DateTo, var: date_to, required: true}, {name: OpponentTeamID, var: opponent_team_id, required: true}, {name: VsConference, var: vs_conference, required: true}, {name: VsDivision, var: vs_division, required: true}, {name: GameSegment, var: game_segment, required: true}, {name: Period, var: period, required: true}, {name: LastNGames, var: last_n_games, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, vs_player_id: $vs_player_id, season_type: $season_type, measure_type: $measure_type, per_mode: $per_mode, plus_minus: $plus_minus, pace_adjust: $pace_adjust, rank: $rank, season: $season, outcome: $outcome, location: $location, month: $month, season_segment: $season_segment, date_from: $date_from, date_to: $date_to, opponent_team_id: $opponent_team_id, vs_conference: $vs_conference, vs_division: $vs_division, game_segment: $game_segment, period: $period, last_n_games: $last_n_games
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /teamyearbyyearstats
export def "get-teamyearbyyearstats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --season-type: string # required
  --per-mode: string # required
  --team-id: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/teamyearbyyearstats"
    query: [{name: LeagueID, var: league_id, required: true}, {name: SeasonType, var: season_type, required: true}, {name: PerMode, var: per_mode, required: true}, {name: TeamID, var: team_id, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, season_type: $season_type, per_mode: $per_mode, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /videoStatus
export def "get-video-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string # required
  --game-date: string # required
]: nothing -> any {
  http-request {
    method: get
    path: "/videoStatus"
    query: [{name: LeagueID, var: league_id, required: true}, {name: GameDate, var: game_date, required: true}]
    accept: ["application/json", "text/html", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    league_id: $league_id, game_date: $game_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
