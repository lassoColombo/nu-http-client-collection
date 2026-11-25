# Auto-generated client for YouTube Data API v3 v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/youtube/v3/openapi.json
# Auth: --token flag or $env.YOUTUBE_DATA_API_V3_TOKEN

const CLIENT = {
  base_url: "https://youtube.googleapis.com"
  token_env_var: "YOUTUBE_DATA_API_V3_TOKEN"
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

def base-url-completer [] { ["https://youtube.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def moderation-status-completer [] { ["heldForReview" "likelySpam" "published" "rejected"] }
def order-completer [] { ["orderUnspecified" "relevance" "time"] }
def text-format-completer [] { ["html" "plainText" "textFormatUnspecified"] }
def broadcast-status-completer [] { ["active" "all" "broadcastStatusFilterUnspecified" "completed" "upcoming"] }
def broadcast-type-completer [] { ["all" "broadcastTypeFilterUnspecified" "event" "persistent"] }
def cue-type-completer [] { ["cueTypeAd" "cueTypeUnspecified"] }
def broadcast-status-completer-1 [] { ["complete" "live" "statusUnspecified" "testing"] }
def mode-completer [] { ["all_current" "listMembersModeUnknown" "updates"] }
def channel-type-completer [] { ["any" "channelTypeUnspecified" "show"] }
def event-type-completer [] { ["completed" "live" "none" "upcoming"] }
def order-completer-1 [] { ["date" "rating" "relevance" "searchSortUnspecified" "title" "videoCount" "viewCount"] }
def safe-search-completer [] { ["moderate" "none" "safeSearchSettingUnspecified" "strict"] }
def video-caption-completer [] { ["any" "closedCaption" "none" "videoCaptionUnspecified"] }
def video-definition-completer [] { ["any" "high" "standard"] }
def video-dimension-completer [] { ["2d" "3d" "any"] }
def video-duration-completer [] { ["any" "long" "medium" "short" "videoDurationUnspecified"] }
def video-embeddable-completer [] { ["any" "true" "videoEmbeddableUnspecified"] }
def video-license-completer [] { ["any" "creativeCommon" "youtube"] }
def video-syndicated-completer [] { ["any" "true" "videoSyndicatedUnspecified"] }
def video-type-completer [] { ["any" "episode" "movie" "videoTypeUnspecified"] }
def order-completer-2 [] { ["alphabetical" "relevance" "subscriptionOrderUnspecified" "unread"] }
def type-completer [] { ["channelToStoreLink" "linkUnspecified"] }
def chart-completer [] { ["chartUnspecified" "mostPopular"] }
def my-rating-completer [] { ["dislike" "like" "none"] }
def rating-completer [] { ["dislike" "like" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    youtube-abuse-reports-insert: "record<abuseTypes: table<id: string>, description: string, relatedEntities: table<entity: record>, subject: record<id: string, typeId: string, url: string>>"
    youtube-activities-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-captions-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>"
    youtube-captions-insert: "record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>>"
    youtube-captions-update: "record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>>"
    youtube-channel-banners-insert: "record<etag: string, kind: string, url: string>"
    youtube-channel-sections-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, snippet: record, targeting: record>, kind: string, visitorId: string>"
    youtube-channel-sections-insert: "record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>>"
    youtube-channel-sections-update: "record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>>"
    youtube-channels-list: "record<etag: string, eventId: string, items: table<auditDetails: record, brandingSettings: record, contentDetails: record, contentOwnerDetails: record, conversionPings: record, etag: string, id: string, kind: string, localizations: record, snippet: record, statistics: record, status: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-channels-update: "record<auditDetails: record<communityGuidelinesGoodStanding: bool, contentIdClaimsGoodStanding: bool, copyrightStrikesGoodStanding: bool>, brandingSettings: record<channel: record<country: string, defaultLanguage: string, defaultTab: string, description: string, featuredChannelsTitle: string, featuredChannelsUrls: list, keywords: string, moderateComments: bool, profileColor: string, showBrowseView: bool, showRelatedChannels: bool, title: string, trackingAnalyticsAccountId: string, unsubscribedTrailer: string>, hints: list<record>, image: record<backgroundImageUrl: record, bannerExternalUrl: string, bannerImageUrl: string, bannerMobileExtraHdImageUrl: string, bannerMobileHdImageUrl: string, bannerMobileImageUrl: string, bannerMobileLowImageUrl: string, bannerMobileMediumHdImageUrl: string, bannerTabletExtraHdImageUrl: string, bannerTabletHdImageUrl: string, bannerTabletImageUrl: string, bannerTabletLowImageUrl: string, bannerTvHighImageUrl: string, bannerTvImageUrl: string, bannerTvLowImageUrl: string, bannerTvMediumImageUrl: string, largeBrandedBannerImageImapScript: record, largeBrandedBannerImageUrl: record, smallBrandedBannerImageImapScript: record, smallBrandedBannerImageUrl: record, trackingImageUrl: string, watchIconImageUrl: string>, watch: record<backgroundColor: string, featuredPlaylistId: string, textColor: string>>, contentDetails: record<relatedPlaylists: record<favorites: string, likes: string, uploads: string, watchHistory: string, watchLater: string>>, contentOwnerDetails: record<contentOwner: string, timeLinked: string>, conversionPings: record<pings: list<record>>, etag: string, id: string, kind: string, localizations: record, snippet: record<country: string, customUrl: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, hiddenSubscriberCount: bool, subscriberCount: string, videoCount: string, viewCount: string>, status: record<isLinked: bool, longUploadsStatus: string, madeForKids: bool, privacyStatus: string, selfDeclaredMadeForKids: bool>, topicDetails: record<topicCategories: list<string>, topicIds: list<string>>>"
    youtube-comment-threads-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, replies: record, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>"
    youtube-comment-threads-insert: "record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>>"
    youtube-youtube-v3-update-comment-threads: "record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>>"
    youtube-comments-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>"
    youtube-comments-insert: "record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>>"
    youtube-comments-update: "record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>>"
    youtube-i18n-languages-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>"
    youtube-i18n-regions-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>"
    youtube-live-broadcasts-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, statistics: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-live-broadcasts-insert: "record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>"
    youtube-live-broadcasts-update: "record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>"
    youtube-live-broadcasts-bind: "record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>"
    youtube-live-broadcasts-insert-cuepoint: "record<cueType: string, durationSecs: int, etag: string, id: string, insertionOffsetTimeMs: string, walltimeMs: string>"
    youtube-live-broadcasts-transition: "record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>"
    youtube-live-chat-bans-insert: "record<etag: string, id: string, kind: string, snippet: record<banDurationSeconds: string, bannedUserDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>, liveChatId: string, type: string>>"
    youtube-live-chat-messages-list: "record<etag: string, eventId: string, items: table<authorDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, offlineAt: string, pageInfo: record<resultsPerPage: int, totalResults: int>, pollingIntervalMillis: int, tokenPagination: record, visitorId: string>"
    youtube-live-chat-messages-insert: "record<authorDetails: record<channelId: string, channelUrl: string, displayName: string, isChatModerator: bool, isChatOwner: bool, isChatSponsor: bool, isVerified: bool, profileImageUrl: string>, etag: string, id: string, kind: string, snippet: record<authorChannelId: string, displayMessage: string, fanFundingEventDetails: record<amountDisplayString: string, amountMicros: string, currency: string, userComment: string>, giftMembershipReceivedDetails: record<associatedMembershipGiftingMessageId: string, gifterChannelId: string, memberLevelName: string>, hasDisplayContent: bool, liveChatId: string, memberMilestoneChatDetails: record<memberLevelName: string, memberMonth: int, userComment: string>, membershipGiftingDetails: record<giftMembershipsCount: int, giftMembershipsLevelName: string>, messageDeletedDetails: record<deletedMessageId: string>, messageRetractedDetails: record<retractedMessageId: string>, newSponsorDetails: record<isUpgrade: bool, memberLevelName: string>, publishedAt: string, superChatDetails: record<amountDisplayString: string, amountMicros: string, currency: string, tier: int, userComment: string>, superStickerDetails: record<amountDisplayString: string, amountMicros: string, currency: string, superStickerMetadata: record, tier: int>, textMessageDetails: record<messageText: string>, type: string, userBannedDetails: record<banDurationSeconds: string, banType: string, bannedUserDetails: record>>>"
    youtube-live-chat-moderators-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-live-chat-moderators-insert: "record<etag: string, id: string, kind: string, snippet: record<liveChatId: string, moderatorDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>>>"
    youtube-live-streams-list: "record<etag: string, eventId: string, items: table<cdn: record, contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-live-streams-insert: "record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>>"
    youtube-live-streams-update: "record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>>"
    youtube-members-list: "record<etag: string, eventId: string, items: table<etag: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>"
    youtube-memberships-levels-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>"
    youtube-playlist-items-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-playlist-items-insert: "record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>>"
    youtube-playlist-items-update: "record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>>"
    youtube-playlists-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, player: record, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-playlists-insert: "record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>>"
    youtube-playlists-update: "record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>>"
    youtube-search-list: "record<etag: string, eventId: string, items: table<etag: string, id: record, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, regionCode: string, tokenPagination: record, visitorId: string>"
    youtube-subscriptions-list: "record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, subscriberSnippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-subscriptions-insert: "record<contentDetails: record<activityType: string, newItemCount: int, totalItemCount: int>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, subscriberSnippet: record<channelId: string, description: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>>"
    youtube-super-chat-events-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>"
    youtube-tests-insert: "record<featuredPart: bool, gaia: string, id: string, snippet: record>"
    youtube-third-party-links-list: "record<etag: string, items: table<etag: string, kind: string, linkingToken: string, snippet: record, status: record>, kind: string>"
    youtube-third-party-links-insert: "record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>>"
    youtube-third-party-links-update: "record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>>"
    youtube-thumbnails-set: "record<etag: string, eventId: string, items: table<high: record, maxres: record, medium: record, standard: record>, kind: string, visitorId: string>"
    youtube-video-abuse-report-reasons-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>"
    youtube-video-categories-list: "record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-videos-list: "record<etag: string, eventId: string, items: table<ageGating: record, contentDetails: record, etag: string, fileDetails: record, id: string, kind: string, liveStreamingDetails: record, localizations: record, monetizationDetails: record, player: record, processingDetails: record, projectDetails: record, recordingDetails: record, snippet: record, statistics: record, status: record, suggestions: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>"
    youtube-videos-insert: "record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>>"
    youtube-videos-update: "record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>>"
    youtube-videos-get-rating: "record<etag: string, eventId: string, items: table<rating: string, videoId: string>, kind: string, visitorId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["youtube-abuse-reports-insert" "youtube-activities-list" "youtube-captions-delete" "youtube-captions-list" "youtube-captions-insert" "youtube-captions-update" "youtube-captions-download" "youtube-channel-banners-insert" "youtube-channel-sections-delete" "youtube-channel-sections-list" "youtube-channel-sections-insert" "youtube-channel-sections-update" "youtube-channels-list" "youtube-channels-update" "youtube-comment-threads-list" "youtube-comment-threads-insert" "youtube-youtube-v3-update-comment-threads" "youtube-comments-delete" "youtube-comments-list" "youtube-comments-insert" "youtube-comments-update" "youtube-comments-mark-as-spam" "youtube-comments-set-moderation-status" "youtube-i18n-languages-list" "youtube-i18n-regions-list" "youtube-live-broadcasts-delete" "youtube-live-broadcasts-list" "youtube-live-broadcasts-insert" "youtube-live-broadcasts-update" "youtube-live-broadcasts-bind" "youtube-live-broadcasts-insert-cuepoint" "youtube-live-broadcasts-transition" "youtube-live-chat-bans-delete" "youtube-live-chat-bans-insert" "youtube-live-chat-messages-delete" "youtube-live-chat-messages-list" "youtube-live-chat-messages-insert" "youtube-live-chat-moderators-delete" "youtube-live-chat-moderators-list" "youtube-live-chat-moderators-insert" "youtube-live-streams-delete" "youtube-live-streams-list" "youtube-live-streams-insert" "youtube-live-streams-update" "youtube-members-list" "youtube-memberships-levels-list" "youtube-playlist-items-delete" "youtube-playlist-items-list" "youtube-playlist-items-insert" "youtube-playlist-items-update" "youtube-playlists-delete" "youtube-playlists-list" "youtube-playlists-insert" "youtube-playlists-update" "youtube-search-list" "youtube-subscriptions-delete" "youtube-subscriptions-list" "youtube-subscriptions-insert" "youtube-super-chat-events-list" "youtube-tests-insert" "youtube-third-party-links-delete" "youtube-third-party-links-list" "youtube-third-party-links-insert" "youtube-third-party-links-update" "youtube-thumbnails-set" "youtube-video-abuse-report-reasons-list" "youtube-video-categories-list" "youtube-videos-delete" "youtube-videos-list" "youtube-videos-insert" "youtube-videos-update" "youtube-videos-get-rating" "youtube-videos-rate" "youtube-videos-report-abuse" "youtube-watermarks-set" "youtube-watermarks-unset" "commands"] | sort) } | get name | first)
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

# Inserts a new resource into this collection.
#
# POST /youtube/v3/abuseReports
# Returns: record<abuseTypes: table<id: string>, description: string, relatedEntities: table<entity: record>, subject: record<id: string, typeId: string, url: string>>
# operationId: youtube.abuseReports.insert
export def "youtube-abuse-reports-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. (required)
  --abuse-types: list # item shape: {id?: string}
  --description: string
  --related-entities: list # item shape: {entity?: record}
  --subject: record # shape: {id?: string, typeId?: string, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/abuseReports"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: abuseTypes, var: abuse_types}, {name: description, var: description}, {name: relatedEntities, var: related_entities}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, abuse_types: $abuse_types, description: $description, related_entities: $related_entities, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/activities
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.activities.list
export def "youtube-activities-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more activity resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in an activity resource, the snippet property contains other properties that identify the type of activity, a display title for the activity, and so forth. If you set *part=snippet*, the API response will also contain all of those nested properties. (required)
  --channel-id: string
  --home: oneof<nothing, bool>
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --published-after: string
  --published-before: string
  --region-code: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/activities"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: channelId, var: channel_id}, {name: home, var: home}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: pageToken, var: page_token}, {name: publishedAfter, var: published_after}, {name: publishedBefore, var: published_before}, {name: regionCode, var: region_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, channel_id: $channel_id, home: $home, max_results: $max_results, mine: $mine, page_token: $page_token, published_after: $published_after, published_before: $published_before, region_code: $region_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/captions
# operationId: youtube.captions.delete
export def "youtube-captions-delete" [
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
  --id: string # required
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/captions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOf, var: on_behalf_of}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of: $on_behalf_of, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/captions
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>
# operationId: youtube.captions.list
export def "youtube-captions-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more caption resource parts that the API response will include. The part names that you can include in the parameter value are id and snippet. (required)
  --video-id: string # Returns the captions for the specified video. (required)
  --id: list<string> # Returns the captions with the given IDs for Stubby or Apiary.
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is on behalf of.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/captions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: videoId, var: video_id, required: true}, {name: id, var: id, style: multi}, {name: onBehalfOf, var: on_behalf_of}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, video_id: $video_id, id: $id, on_behalf_of: $on_behalf_of, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/captions
# Returns: record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>>
# operationId: youtube.captions.insert
export def "youtube-captions-insert" [
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
  --part: list<string> # The *part* parameter specifies the caption resource parts that the API response will include. Set the parameter value to snippet. (required)
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --sync: oneof<nothing, bool> # Extra parameter to allow automatically syncing the uploaded caption/transcript with the audio.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/captions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOf, var: on_behalf_of}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: sync, var: sync}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of: $on_behalf_of, on_behalf_of_content_owner: $on_behalf_of_content_owner, sync: $sync, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/captions
# Returns: record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>>
# operationId: youtube.captions.update
export def "youtube-captions-update" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more caption resource parts that the API response will include. The part names that you can include in the parameter value are id and snippet. (required)
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is on behalf of.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --sync: oneof<nothing, bool> # Extra parameter to allow automatically syncing the uploaded caption/transcript with the audio.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/captions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOf, var: on_behalf_of}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: sync, var: sync}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of: $on_behalf_of, on_behalf_of_content_owner: $on_behalf_of_content_owner, sync: $sync, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads a caption track.
#
# GET /youtube/v3/captions/{id}
# operationId: youtube.captions.download
export def "youtube-captions-download" [
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
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --tfmt: string # Convert the captions into this format. Supported options are sbv, srt, and vtt.
  --tlang: string # tlang is the language code; machine translate the captions into this language.
]: nothing -> any {
  http-request {
    method: get
    path: "/youtube/v3/captions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: onBehalfOf, var: on_behalf_of}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: tfmt, var: tfmt}, {name: tlang, var: tlang}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, on_behalf_of: $on_behalf_of, on_behalf_of_content_owner: $on_behalf_of_content_owner, tfmt: $tfmt, tlang: $tlang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/channelBanners/insert
# Returns: record<etag: string, kind: string, url: string>
# operationId: youtube.channelBanners.insert
export def "youtube-channel-banners-insert" [
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
  --channel-id: string # Unused, channel_id is currently derived from the security context of the requestor.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/channelBanners/insert"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: channelId, var: channel_id}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, channel_id: $channel_id, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/channelSections
# operationId: youtube.channelSections.delete
export def "youtube-channel-sections-delete" [
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
  --id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/channelSections"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/channelSections
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, snippet: record, targeting: record>, kind: string, visitorId: string>
# operationId: youtube.channelSections.list
export def "youtube-channel-sections-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more channelSection resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, and contentDetails. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a channelSection resource, the snippet property contains other properties, such as a display title for the channelSection. If you set *part=snippet*, the API response will also contain all of those nested properties. (required)
  --channel-id: string # Return the ChannelSections owned by the specified channel ID.
  --hl: string # Return content in specified language
  --id: list<string> # Return the ChannelSections with the given IDs for Stubby or Apiary.
  --mine: oneof<nothing, bool> # Return the ChannelSections owned by the authenticated user.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/channelSections"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: channelId, var: channel_id}, {name: hl, var: hl}, {name: id, var: id, style: multi}, {name: mine, var: mine}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, channel_id: $channel_id, hl: $hl, id: $id, mine: $mine, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/channelSections
# Returns: record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>>
# operationId: youtube.channelSections.insert
export def "youtube-channel-sections-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part names that you can include in the parameter value are snippet and contentDetails. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Details about a channelsection, including playlists and channels. — shape: {channels?: list<string>, playlists?: list<string>}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel section.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channelSection". (default: youtube#channelSection)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel section, including title, style and position. — shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
  --targeting: record # ChannelSection targeting setting. — shape: {countries?: list<string>, languages?: list<string>, regions?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/channelSections"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: localizations, var: localizations}, {name: snippet, var: snippet}, {name: targeting, var: targeting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, content_details: $content_details, etag: $etag, id: $id, kind: $kind, localizations: $localizations, snippet: $snippet, targeting: $targeting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/channelSections
# Returns: record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>>
# operationId: youtube.channelSections.update
export def "youtube-channel-sections-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part names that you can include in the parameter value are snippet and contentDetails. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # Details about a channelsection, including playlists and channels. — shape: {channels?: list<string>, playlists?: list<string>}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel section.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channelSection". (default: youtube#channelSection)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel section, including title, style and position. — shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
  --targeting: record # ChannelSection targeting setting. — shape: {countries?: list<string>, languages?: list<string>, regions?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/channelSections"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: localizations, var: localizations}, {name: snippet, var: snippet}, {name: targeting, var: targeting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, content_details: $content_details, etag: $etag, id: $id, kind: $kind, localizations: $localizations, snippet: $snippet, targeting: $targeting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/channels
# Returns: record<etag: string, eventId: string, items: table<auditDetails: record, brandingSettings: record, contentDetails: record, contentOwnerDetails: record, conversionPings: record, etag: string, id: string, kind: string, localizations: record, snippet: record, statistics: record, status: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.channels.list
export def "youtube-channels-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more channel resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a channel resource, the contentDetails property contains other properties, such as the uploads properties. As such, if you set *part=contentDetails*, the API response will also contain all of those nested properties. (required)
  --category-id: string # Return the channels within the specified guide category ID.
  --for-username: string # Return the channel associated with a YouTube username.
  --hl: string # Stands for "host language". Specifies the localization language of the metadata to be filled into snippet.localized. The field is filled with the default metadata if there is no localization in the specified language. The parameter value must be a language code included in the list returned by the i18nLanguages.list method (e.g. en_US, es_MX).
  --id: list<string> # Return the channels with the specified IDs.
  --managed-by-me: oneof<nothing, bool> # Return the channels managed by the authenticated user.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Return the ids of channels owned by the authenticated user.
  --my-subscribers: oneof<nothing, bool> # Return the channels subscribed to the authenticated user
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/channels"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: categoryId, var: category_id}, {name: forUsername, var: for_username}, {name: hl, var: hl}, {name: id, var: id, style: multi}, {name: managedByMe, var: managed_by_me}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: mySubscribers, var: my_subscribers}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, category_id: $category_id, for_username: $for_username, hl: $hl, id: $id, managed_by_me: $managed_by_me, max_results: $max_results, mine: $mine, my_subscribers: $my_subscribers, on_behalf_of_content_owner: $on_behalf_of_content_owner, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/channels
# Returns: record<auditDetails: record<communityGuidelinesGoodStanding: bool, contentIdClaimsGoodStanding: bool, copyrightStrikesGoodStanding: bool>, brandingSettings: record<channel: record<country: string, defaultLanguage: string, defaultTab: string, description: string, featuredChannelsTitle: string, featuredChannelsUrls: list, keywords: string, moderateComments: bool, profileColor: string, showBrowseView: bool, showRelatedChannels: bool, title: string, trackingAnalyticsAccountId: string, unsubscribedTrailer: string>, hints: list<record>, image: record<backgroundImageUrl: record, bannerExternalUrl: string, bannerImageUrl: string, bannerMobileExtraHdImageUrl: string, bannerMobileHdImageUrl: string, bannerMobileImageUrl: string, bannerMobileLowImageUrl: string, bannerMobileMediumHdImageUrl: string, bannerTabletExtraHdImageUrl: string, bannerTabletHdImageUrl: string, bannerTabletImageUrl: string, bannerTabletLowImageUrl: string, bannerTvHighImageUrl: string, bannerTvImageUrl: string, bannerTvLowImageUrl: string, bannerTvMediumImageUrl: string, largeBrandedBannerImageImapScript: record, largeBrandedBannerImageUrl: record, smallBrandedBannerImageImapScript: record, smallBrandedBannerImageUrl: record, trackingImageUrl: string, watchIconImageUrl: string>, watch: record<backgroundColor: string, featuredPlaylistId: string, textColor: string>>, contentDetails: record<relatedPlaylists: record<favorites: string, likes: string, uploads: string, watchHistory: string, watchLater: string>>, contentOwnerDetails: record<contentOwner: string, timeLinked: string>, conversionPings: record<pings: list<record>>, etag: string, id: string, kind: string, localizations: record, snippet: record<country: string, customUrl: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, hiddenSubscriberCount: bool, subscriberCount: string, videoCount: string, viewCount: string>, status: record<isLinked: bool, longUploadsStatus: string, madeForKids: bool, privacyStatus: string, selfDeclaredMadeForKids: bool>, topicDetails: record<topicCategories: list<string>, topicIds: list<string>>>
# operationId: youtube.channels.update
export def "youtube-channels-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The API currently only allows the parameter value to be set to either brandingSettings or invideoPromotion. (You cannot update both of those parts with a single request.) Note that this method overrides the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. (required)
  --on-behalf-of-content-owner: string # The *onBehalfOfContentOwner* parameter indicates that the authenticated user is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with needs to be linked to the specified YouTube content owner.
  --audit-details: record # The auditDetails object encapsulates channel data that is relevant for YouTube Partners during the audit process. — shape: {communityGuidelinesGoodStanding?: bool, contentIdClaimsGoodStanding?: bool, copyrightStrikesGoodStanding?: bool}
  --branding-settings: record # Branding properties of a YouTube channel. — shape: {channel?: record, hints?: list, image?: record, watch?: record}
  --content-details: record # Details about the content of a channel. — shape: {relatedPlaylists?: record}
  --content-owner-details: record # The contentOwnerDetails object encapsulates channel data that is relevant for YouTube Partners linked with the channel. — shape: {contentOwner?: string, timeLinked?: string}
  --conversion-pings: record # The conversionPings object encapsulates information about conversion pings that need to be respected by the channel. — shape: {pings?: list}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channel". (default: youtube#channel)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel, including title, description and thumbnails. — shape: {country?: string, customUrl?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about a channel: number of subscribers, number of videos in the channel, etc. — shape: {commentCount?: string, hiddenSubscriberCount?: bool, subscriberCount?: string, videoCount?: string, viewCount?: string}
  --status: record # JSON template for the status part of a channel. — shape: {isLinked?: bool, longUploadsStatus?: "longUploadsUnspecified"|"allowed"|"eligible"|"disallowed", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", selfDeclaredMadeForKids?: bool}
  --topic-details: record # Freebase topic information related to the channel. — shape: {topicCategories?: list<string>, topicIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/channels"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: auditDetails, var: audit_details}, {name: brandingSettings, var: branding_settings}, {name: contentDetails, var: content_details}, {name: contentOwnerDetails, var: content_owner_details}, {name: conversionPings, var: conversion_pings}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: localizations, var: localizations}, {name: snippet, var: snippet}, {name: statistics, var: statistics}, {name: status, var: status}, {name: topicDetails, var: topic_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, audit_details: $audit_details, branding_settings: $branding_settings, content_details: $content_details, content_owner_details: $content_owner_details, conversion_pings: $conversion_pings, etag: $etag, id: $id, kind: $kind, localizations: $localizations, snippet: $snippet, statistics: $statistics, status: $status, topic_details: $topic_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/commentThreads
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, replies: record, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>
# operationId: youtube.commentThreads.list
export def "youtube-comment-threads-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more commentThread resource properties that the API response will include. (required)
  --all-threads-related-to-channel-id: string # Returns the comment threads of all videos of the channel and the channel comments as well.
  --channel-id: string # Returns the comment threads for all the channel comments (ie does not include comments left on videos).
  --id: list<string> # Returns the comment threads with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --moderation-status: string@moderation-status-completer # Limits the returned comment threads to those with the specified moderation status. Not compatible with the 'id' filter. Valid values: published, heldForReview, likelySpam.
  --order: string@order-completer
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --search-terms: string # Limits the returned comment threads to those matching the specified key words. Not compatible with the 'id' filter.
  --text-format: string@text-format-completer # The requested text format for the returned comments.
  --video-id: string # Returns the comment threads of the specified video.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/commentThreads"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: allThreadsRelatedToChannelId, var: all_threads_related_to_channel_id}, {name: channelId, var: channel_id}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: moderationStatus, var: moderation_status}, {name: order, var: order}, {name: pageToken, var: page_token}, {name: searchTerms, var: search_terms}, {name: textFormat, var: text_format}, {name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, all_threads_related_to_channel_id: $all_threads_related_to_channel_id, channel_id: $channel_id, id: $id, max_results: $max_results, moderation_status: $moderation_status, order: $order, page_token: $page_token, search_terms: $search_terms, text_format: $text_format, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/commentThreads
# Returns: record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>>
# operationId: youtube.commentThreads.insert
export def "youtube-comment-threads-insert" [
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
  --part: list<string> # The *part* parameter identifies the properties that the API response will include. Set the parameter value to snippet. The snippet part has a quota cost of 2 units. (required)
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment thread.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#commentThread". (default: youtube#commentThread)
  --replies: record # Comments written in (direct or indirect) reply to the top level comment. — shape: {comments?: list}
  --snippet: record # Basic details about a comment thread. — shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/commentThreads"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: replies, var: replies}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, replies: $replies, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/commentThreads
# Returns: record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>>
# operationId: youtube.youtube.v3.updateCommentThreads
export def "youtube-youtube-v3-update-comment-threads" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of commentThread resource properties that the API response will include. You must at least include the snippet part in the parameter value since that part contains all of the properties that the API request can update.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment thread.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#commentThread". (default: youtube#commentThread)
  --replies: record # Comments written in (direct or indirect) reply to the top level comment. — shape: {comments?: list}
  --snippet: record # Basic details about a comment thread. — shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/commentThreads"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: replies, var: replies}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, replies: $replies, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/comments
# operationId: youtube.comments.delete
export def "youtube-comments-delete" [
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
  --id: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/comments"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/comments
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>
# operationId: youtube.comments.list
export def "youtube-comments-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more comment resource properties that the API response will include. (required)
  --id: list<string> # Returns the comments with the given IDs for One Platform.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --parent-id: string # Returns replies to the specified comment. Note, currently YouTube features only one level of replies (ie replies to top level comments). However replies to replies may be supported in the future.
  --text-format: string@text-format-completer # The requested text format for the returned comments.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/comments"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: parentId, var: parent_id}, {name: textFormat, var: text_format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, id: $id, max_results: $max_results, page_token: $page_token, parent_id: $parent_id, text_format: $text_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/comments
# Returns: record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>>
# operationId: youtube.comments.insert
export def "youtube-comments-insert" [
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
  --part: list<string> # The *part* parameter identifies the properties that the API response will include. Set the parameter value to snippet. The snippet part has a quota cost of 2 units. (required)
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#comment". (default: youtube#comment)
  --snippet: record # Basic details about a comment, such as its author and text. — shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/comments"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/comments
# Returns: record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>>
# operationId: youtube.comments.update
export def "youtube-comments-update" [
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
  --part: list<string> # The *part* parameter identifies the properties that the API response will include. You must at least include the snippet part in the parameter value since that part contains all of the properties that the API request can update. (required)
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#comment". (default: youtube#comment)
  --snippet: record # Basic details about a comment, such as its author and text. — shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/comments"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expresses the caller's opinion that one or more comments should be flagged as spam.
#
# POST /youtube/v3/comments/markAsSpam
# operationId: youtube.comments.markAsSpam
export def "youtube-comments-mark-as-spam" [
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
  --id: list<string> # Flags the comments with the given IDs as spam in the caller's opinion. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/youtube/v3/comments/markAsSpam"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the moderation status of one or more comments.
#
# POST /youtube/v3/comments/setModerationStatus
# operationId: youtube.comments.setModerationStatus
export def "youtube-comments-set-moderation-status" [
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
  --id: list<string> # Modifies the moderation status of the comments with the given IDs (required)
  --moderation-status: string@moderation-status-completer # Specifies the requested moderation status. Note, comments can be in statuses, which are not available through this call. For example, this call does not allow to mark a comment as 'likely spam'. Valid values: MODERATION_STATUS_PUBLISHED, MODERATION_STATUS_HELD_FOR_REVIEW, MODERATION_STATUS_REJECTED. (required)
  --ban-author: oneof<nothing, bool> # If set to true the author of the comment gets added to the ban list. This means all future comments of the author will autmomatically be rejected. Only valid in combination with STATUS_REJECTED.
]: nothing -> any {
  http-request {
    method: post
    path: "/youtube/v3/comments/setModerationStatus"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, style: multi, required: true}, {name: moderationStatus, var: moderation_status, required: true}, {name: banAuthor, var: ban_author}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, moderation_status: $moderation_status, ban_author: $ban_author
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/i18nLanguages
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>
# operationId: youtube.i18nLanguages.list
export def "youtube-i18n-languages-list" [
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
  --part: list<string> # The *part* parameter specifies the i18nLanguage resource properties that the API response will include. Set the parameter value to snippet. (required)
  --hl: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/i18nLanguages"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, hl: $hl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/i18nRegions
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>
# operationId: youtube.i18nRegions.list
export def "youtube-i18n-regions-list" [
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
  --part: list<string> # The *part* parameter specifies the i18nRegion resource properties that the API response will include. Set the parameter value to snippet. (required)
  --hl: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/i18nRegions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, hl: $hl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a given broadcast.
#
# DELETE /youtube/v3/liveBroadcasts
# operationId: youtube.liveBroadcasts.delete
export def "youtube-live-broadcasts-delete" [
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
  --id: string # Broadcast to delete. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/liveBroadcasts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the list of broadcasts associated with the given channel.
#
# GET /youtube/v3/liveBroadcasts
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, statistics: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.liveBroadcasts.list
export def "youtube-live-broadcasts-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, status and statistics. (required)
  --broadcast-status: string@broadcast-status-completer # Return broadcasts with a certain status, e.g. active broadcasts.
  --broadcast-type: string@broadcast-type-completer # Return only broadcasts with the selected type.
  --id: list<string> # Return broadcasts with the given ids from Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/liveBroadcasts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: broadcastStatus, var: broadcast_status}, {name: broadcastType, var: broadcast_type}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, broadcast_status: $broadcast_status, broadcast_type: $broadcast_type, id: $id, max_results: $max_results, mine: $mine, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new stream for the authenticated user.
#
# POST /youtube/v3/liveBroadcasts
# Returns: record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>
# operationId: youtube.liveBroadcasts.insert
export def "youtube-live-broadcasts-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, contentDetails, and status. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Detailed settings of a broadcast. — shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, ... (4 more fields)}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the broadcast.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveBroadcast". (default: youtube#liveBroadcast)
  --snippet: record # Basic broadcast information. — shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the live broadcast. These represent a snapshot of the values at the time of the request. Statistics are only returned for live broadcasts. — shape: {concurrentViewers?: string}
  --status: record # Live broadcast state. — shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveBroadcasts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: statistics, var: statistics}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, statistics: $statistics, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing broadcast for the authenticated user.
#
# PUT /youtube/v3/liveBroadcasts
# Returns: record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>
# operationId: youtube.liveBroadcasts.update
export def "youtube-live-broadcasts-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, contentDetails, and status. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a broadcast's privacy status is defined in the status part. As such, if your request is updating a private or unlisted broadcast, and the request's part parameter value includes the status part, the broadcast's privacy setting will be updated to whatever value the request body specifies. If the request body does not specify a value, the existing privacy setting will be removed and the broadcast will revert to the default privacy setting. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Detailed settings of a broadcast. — shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, ... (4 more fields)}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the broadcast.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveBroadcast". (default: youtube#liveBroadcast)
  --snippet: record # Basic broadcast information. — shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the live broadcast. These represent a snapshot of the values at the time of the request. Statistics are only returned for live broadcasts. — shape: {concurrentViewers?: string}
  --status: record # Live broadcast state. — shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/liveBroadcasts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: statistics, var: statistics}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, statistics: $statistics, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bind a broadcast to a stream.
#
# POST /youtube/v3/liveBroadcasts/bind
# Returns: record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>
# operationId: youtube.liveBroadcasts.bind
export def "youtube-live-broadcasts-bind" [
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
  --id: string # Broadcast to bind to the stream (required)
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --stream-id: string # Stream to bind, if not set unbind the current one.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/youtube/v3/liveBroadcasts/bind"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: streamId, var: stream_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, stream_id: $stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert cuepoints in a broadcast
#
# POST /youtube/v3/liveBroadcasts/cuepoint
# Returns: record<cueType: string, durationSecs: int, etag: string, id: string, insertionOffsetTimeMs: string, walltimeMs: string>
# operationId: youtube.liveBroadcasts.insertCuepoint
export def "youtube-live-broadcasts-insert-cuepoint" [
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
  --id: string # Broadcast to insert ads to, or equivalently `external_video_id` for internal use.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status.
  --cue-type: string@cue-type-completer
  --duration-secs: int # The duration of this cuepoint. (format: uint32)
  --etag: string
  --body-id: string # The identifier for cuepoint resource. (spec name: id)
  --insertion-offset-time-ms: string # The time when the cuepoint should be inserted by offset to the broadcast actual start time. (format: int64)
  --walltime-ms: string # The wall clock time at which the cuepoint should be inserted. Only one of insertion_offset_time_ms and walltime_ms may be set at a time. (format: uint64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveBroadcasts/cuepoint"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: part, var: part, style: multi}]
    body: {content_type: "application/json", kind: json, fields: [{name: cueType, var: cue_type}, {name: durationSecs, var: duration_secs}, {name: etag, var: etag}, {name: id, var: body_id}, {name: insertionOffsetTimeMs, var: insertion_offset_time_ms}, {name: walltimeMs, var: walltime_ms}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, part: $part, cue_type: $cue_type, duration_secs: $duration_secs, etag: $etag, body_id: $body_id, insertion_offset_time_ms: $insertion_offset_time_ms, walltime_ms: $walltime_ms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transition a broadcast to a given status.
#
# POST /youtube/v3/liveBroadcasts/transition
# Returns: record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>>
# operationId: youtube.liveBroadcasts.transition
export def "youtube-live-broadcasts-transition" [
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
  --broadcast-status: string@broadcast-status-completer-1 # The status to which the broadcast is going to transition. (required)
  --id: string # Broadcast to transition. (required)
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/youtube/v3/liveBroadcasts/transition"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: broadcastStatus, var: broadcast_status, required: true}, {name: id, var: id, required: true}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, broadcast_status: $broadcast_status, id: $id, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a chat ban.
#
# DELETE /youtube/v3/liveChat/bans
# operationId: youtube.liveChatBans.delete
export def "youtube-live-chat-bans-delete" [
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
  --id: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/liveChat/bans"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/bans
# Returns: record<etag: string, id: string, kind: string, snippet: record<banDurationSeconds: string, bannedUserDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>, liveChatId: string, type: string>>
# operationId: youtube.liveChatBans.insert
export def "youtube-live-chat-bans-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response returns. Set the parameter value to snippet. (required)
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the ban.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string `"youtube#liveChatBan"`. (default: youtube#liveChatBan)
  --snippet: record # shape: {banDurationSeconds?: string, bannedUserDetails?: record, liveChatId?: string, type?: "liveChatBanTypeUnspecified"|"permanent"|"temporary"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveChat/bans"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a chat message.
#
# DELETE /youtube/v3/liveChat/messages
# operationId: youtube.liveChatMessages.delete
export def "youtube-live-chat-messages-delete" [
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
  --id: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/liveChat/messages"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/liveChat/messages
# Returns: record<etag: string, eventId: string, items: table<authorDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, offlineAt: string, pageInfo: record<resultsPerPage: int, totalResults: int>, pollingIntervalMillis: int, tokenPagination: record, visitorId: string>
# operationId: youtube.liveChatMessages.list
export def "youtube-live-chat-messages-list" [
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
  --live-chat-id: string # The id of the live chat for which comments should be returned. (required)
  --part: list<string> # The *part* parameter specifies the liveChatComment resource parts that the API response will include. Supported values are id and snippet. (required)
  --hl: string # Specifies the localization language in which the system messages should be returned.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken property identify other pages that could be retrieved.
  --profile-image-size: int # Specifies the size of the profile image that should be returned for each user.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/liveChat/messages"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: liveChatId, var: live_chat_id, required: true}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: profileImageSize, var: profile_image_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, live_chat_id: $live_chat_id, part: $part, hl: $hl, max_results: $max_results, page_token: $page_token, profile_image_size: $profile_image_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/messages
# Returns: record<authorDetails: record<channelId: string, channelUrl: string, displayName: string, isChatModerator: bool, isChatOwner: bool, isChatSponsor: bool, isVerified: bool, profileImageUrl: string>, etag: string, id: string, kind: string, snippet: record<authorChannelId: string, displayMessage: string, fanFundingEventDetails: record<amountDisplayString: string, amountMicros: string, currency: string, userComment: string>, giftMembershipReceivedDetails: record<associatedMembershipGiftingMessageId: string, gifterChannelId: string, memberLevelName: string>, hasDisplayContent: bool, liveChatId: string, memberMilestoneChatDetails: record<memberLevelName: string, memberMonth: int, userComment: string>, membershipGiftingDetails: record<giftMembershipsCount: int, giftMembershipsLevelName: string>, messageDeletedDetails: record<deletedMessageId: string>, messageRetractedDetails: record<retractedMessageId: string>, newSponsorDetails: record<isUpgrade: bool, memberLevelName: string>, publishedAt: string, superChatDetails: record<amountDisplayString: string, amountMicros: string, currency: string, tier: int, userComment: string>, superStickerDetails: record<amountDisplayString: string, amountMicros: string, currency: string, superStickerMetadata: record, tier: int>, textMessageDetails: record<messageText: string>, type: string, userBannedDetails: record<banDurationSeconds: string, banType: string, bannedUserDetails: record>>>
# operationId: youtube.liveChatMessages.insert
export def "youtube-live-chat-messages-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes. It identifies the properties that the write operation will set as well as the properties that the API response will include. Set the parameter value to snippet. (required)
  --author-details: record # shape: {channelId?: string, channelUrl?: string, displayName?: string, isChatModerator?: bool, isChatOwner?: bool, isChatSponsor?: bool, isVerified?: bool, profileImageUrl?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the message.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveChatMessage". (default: youtube#liveChatMessage)
  --snippet: record # Next ID: 33 — shape: {authorChannelId?: string, displayMessage?: string, fanFundingEventDetails?: record, giftMembershipReceivedDetails?: record, hasDisplayContent?: bool, liveChatId?: string, memberMilestoneChatDetails?: record, membershipGiftingDetails?: record, messageDeletedDetails?: record, messageRetractedDetails?: record, newSponsorDetails?: record, publishedAt?: string, superChatDetails?: record, superStickerDetails?: record, textMessageDetails?: record, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveChat/messages"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorDetails, var: author_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, author_details: $author_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a chat moderator.
#
# DELETE /youtube/v3/liveChat/moderators
# operationId: youtube.liveChatModerators.delete
export def "youtube-live-chat-moderators-delete" [
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
  --id: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/liveChat/moderators"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/liveChat/moderators
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.liveChatModerators.list
export def "youtube-live-chat-moderators-list" [
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
  --live-chat-id: string # The id of the live chat for which moderators should be returned. (required)
  --part: list<string> # The *part* parameter specifies the liveChatModerator resource parts that the API response will include. Supported values are id and snippet. (required)
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/liveChat/moderators"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: liveChatId, var: live_chat_id, required: true}, {name: part, var: part, style: multi, required: true}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, live_chat_id: $live_chat_id, part: $part, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/moderators
# Returns: record<etag: string, id: string, kind: string, snippet: record<liveChatId: string, moderatorDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>>>
# operationId: youtube.liveChatModerators.insert
export def "youtube-live-chat-moderators-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response returns. Set the parameter value to snippet. (required)
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the moderator.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveChatModerator". (default: youtube#liveChatModerator)
  --snippet: record # shape: {liveChatId?: string, moderatorDetails?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveChat/moderators"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, etag: $etag, id: $id, kind: $kind, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing stream for the authenticated user.
#
# DELETE /youtube/v3/liveStreams
# operationId: youtube.liveStreams.delete
export def "youtube-live-streams-delete" [
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
  --id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/liveStreams"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the list of streams associated with the given channel. --
#
# GET /youtube/v3/liveStreams
# Returns: record<etag: string, eventId: string, items: table<cdn: record, contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.liveStreams.list
export def "youtube-live-streams-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more liveStream resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, cdn, and status. (required)
  --id: list<string> # Return LiveStreams with the given ids from Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/liveStreams"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, id: $id, max_results: $max_results, mine: $mine, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new stream for the authenticated user.
#
# POST /youtube/v3/liveStreams
# Returns: record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>>
# operationId: youtube.liveStreams.insert
export def "youtube-live-streams-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, cdn, content_details, and status. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --cdn: record # Brief description of the live stream cdn settings. — shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
  --content-details: record # Detailed settings of a stream. — shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the stream.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveStream". (default: youtube#liveStream)
  --snippet: record # shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
  --status: record # Brief description of the live stream status. — shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/liveStreams"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: cdn, var: cdn}, {name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, cdn: $cdn, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing stream for the authenticated user.
#
# PUT /youtube/v3/liveStreams
# Returns: record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>>
# operationId: youtube.liveStreams.update
export def "youtube-live-streams-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, cdn, and status. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. If the request body does not specify a value for a mutable property, the existing value for that property will be removed. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --cdn: record # Brief description of the live stream cdn settings. — shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
  --content-details: record # Detailed settings of a stream. — shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the stream.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveStream". (default: youtube#liveStream)
  --snippet: record # shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
  --status: record # Brief description of the live stream status. — shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/liveStreams"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: cdn, var: cdn}, {name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, cdn: $cdn, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of members that match the request criteria for a channel.
#
# GET /youtube/v3/members
# Returns: record<etag: string, eventId: string, items: table<etag: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>
# operationId: youtube.members.list
export def "youtube-members-list" [
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
  --part: list<string> # The *part* parameter specifies the member resource parts that the API response will include. Set the parameter value to snippet. (required)
  --filter-by-member-channel-id: string # Comma separated list of channel IDs. Only data about members that are part of this list will be included in the response.
  --has-access-to-level: string # Filter members in the results set to the ones that have access to a level.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mode: string@mode-completer # Parameter that specifies which channel members to return.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/members"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: filterByMemberChannelId, var: filter_by_member_channel_id}, {name: hasAccessToLevel, var: has_access_to_level}, {name: maxResults, var: max_results}, {name: mode, var: mode}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, filter_by_member_channel_id: $filter_by_member_channel_id, has_access_to_level: $has_access_to_level, max_results: $max_results, mode: $mode, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of all pricing levels offered by a creator to the fans.
#
# GET /youtube/v3/membershipsLevels
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>
# operationId: youtube.membershipsLevels.list
export def "youtube-memberships-levels-list" [
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
  --part: list<string> # The *part* parameter specifies the membershipsLevel resource parts that the API response will include. Supported values are id and snippet. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/membershipsLevels"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/playlistItems
# operationId: youtube.playlistItems.delete
export def "youtube-playlist-items-delete" [
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
  --id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/playlistItems"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/playlistItems
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.playlistItems.list
export def "youtube-playlist-items-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more playlistItem resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a playlistItem resource, the snippet property contains numerous fields, including the title, description, position, and resourceId properties. As such, if you set *part=snippet*, the API response will contain all of those properties. (required)
  --id: list<string>
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --playlist-id: string # Return the playlist items within the given playlist.
  --video-id: string # Return the playlist items associated with the given video ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/playlistItems"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: pageToken, var: page_token}, {name: playlistId, var: playlist_id}, {name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, id: $id, max_results: $max_results, on_behalf_of_content_owner: $on_behalf_of_content_owner, page_token: $page_token, playlist_id: $playlist_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/playlistItems
# Returns: record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>>
# operationId: youtube.playlistItems.insert
export def "youtube-playlist-items-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist item.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlistItem". (default: youtube#playlistItem)
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. Basic details of a YouTube Playlist item provided by the author. Next ID: 15 — shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
  --status: record # Information about the playlist item's privacy status. — shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/playlistItems"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/playlistItems
# Returns: record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>>
# operationId: youtube.playlistItems.update
export def "youtube-playlist-items-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a playlist item can specify a start time and end time, which identify the times portion of the video that should play when users watch the video in the playlist. If your request is updating a playlist item that sets these values, and the request's part parameter value includes the contentDetails part, the playlist item's start and end times will be updated to whatever value the request body specifies. If the request body does not specify values, the existing start and end times will be removed and replaced with the default settings. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist item.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlistItem". (default: youtube#playlistItem)
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. Basic details of a YouTube Playlist item provided by the author. Next ID: 15 — shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
  --status: record # Information about the playlist item's privacy status. — shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/playlistItems"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/playlists
# operationId: youtube.playlists.delete
export def "youtube-playlists-delete" [
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
  --id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/playlists"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/playlists
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, player: record, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.playlists.list
export def "youtube-playlists-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more playlist resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a playlist resource, the snippet property contains properties like author, title, description, tags, and timeCreated. As such, if you set *part=snippet*, the API response will contain all of those properties. (required)
  --channel-id: string # Return the playlists owned by the specified channel ID.
  --hl: string # Return content in specified language
  --id: list<string> # Return the playlists with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Return the playlists owned by the authenticated user.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/playlists"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: channelId, var: channel_id}, {name: hl, var: hl}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, channel_id: $channel_id, hl: $hl, id: $id, max_results: $max_results, mine: $mine, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/playlists
# Returns: record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>>
# operationId: youtube.playlists.insert
export def "youtube-playlists-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # shape: {itemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlist". (default: youtube#playlist)
  --localizations: record # Localizations for different languages
  --player: record # shape: {embedHtml?: string}
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. — shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list<string>, thumbnailVideoId?: string, thumbnails?: record, title?: string}
  --status: record # shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/playlists"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: localizations, var: localizations}, {name: player, var: player}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, content_details: $content_details, etag: $etag, id: $id, kind: $kind, localizations: $localizations, player: $player, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/playlists
# Returns: record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>>
# operationId: youtube.playlists.update
export def "youtube-playlists-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for mutable properties that are contained in any parts that the request body specifies. For example, a playlist's description is contained in the snippet part, which must be included in the request body. If the request does not specify a value for the snippet.description property, the playlist's existing description will be deleted. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {itemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlist". (default: youtube#playlist)
  --localizations: record # Localizations for different languages
  --player: record # shape: {embedHtml?: string}
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. — shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list<string>, thumbnailVideoId?: string, thumbnails?: record, title?: string}
  --status: record # shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/playlists"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: localizations, var: localizations}, {name: player, var: player}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, content_details: $content_details, etag: $etag, id: $id, kind: $kind, localizations: $localizations, player: $player, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of search resources
#
# GET /youtube/v3/search
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: record, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, regionCode: string, tokenPagination: record, visitorId: string>
# operationId: youtube.search.list
export def "youtube-search-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more search resource properties that the API response will include. Set the parameter value to snippet. (required)
  --channel-id: string # Filter on resources belonging to this channelId.
  --channel-type: string@channel-type-completer # Add a filter on the channel search.
  --event-type: string@event-type-completer # Filter on the livestream status of the videos.
  --for-content-owner: oneof<nothing, bool> # Search owned by a content owner.
  --for-developer: oneof<nothing, bool> # Restrict the search to only retrieve videos uploaded using the project id of the authenticated user.
  --for-mine: oneof<nothing, bool> # Search for the private videos of the authenticated user.
  --location: string # Filter on location of the video
  --location-radius: string # Filter on distance from the location (specified above).
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --order: string@order-completer-1 # Sort order of the results.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --published-after: string # Filter on resources published after this date.
  --published-before: string # Filter on resources published before this date.
  --q: string # Textual search terms to match.
  --region-code: string # Display the content as seen by viewers in this country.
  --related-to-video-id: string # Search related to a resource.
  --relevance-language: string # Return results relevant to this language.
  --safe-search: string@safe-search-completer # Indicates whether the search results should include restricted content as well as standard content.
  --topic-id: string # Restrict results to a particular topic.
  --type: list<string> # Restrict results to a particular set of resource types from One Platform.
  --video-caption: string@video-caption-completer # Filter on the presence of captions on the videos.
  --video-category-id: string # Filter on videos in a specific category.
  --video-definition: string@video-definition-completer # Filter on the definition of the videos.
  --video-dimension: string@video-dimension-completer # Filter on 3d videos.
  --video-duration: string@video-duration-completer # Filter on the duration of the videos.
  --video-embeddable: string@video-embeddable-completer # Filter on embeddable videos.
  --video-license: string@video-license-completer # Filter on the license of the videos.
  --video-syndicated: string@video-syndicated-completer # Filter on syndicated videos.
  --video-type: string@video-type-completer # Filter on videos of a specific type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/search"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: channelId, var: channel_id}, {name: channelType, var: channel_type}, {name: eventType, var: event_type}, {name: forContentOwner, var: for_content_owner}, {name: forDeveloper, var: for_developer}, {name: forMine, var: for_mine}, {name: location, var: location}, {name: locationRadius, var: location_radius}, {name: maxResults, var: max_results}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: order, var: order}, {name: pageToken, var: page_token}, {name: publishedAfter, var: published_after}, {name: publishedBefore, var: published_before}, {name: q, var: q}, {name: regionCode, var: region_code}, {name: relatedToVideoId, var: related_to_video_id}, {name: relevanceLanguage, var: relevance_language}, {name: safeSearch, var: safe_search}, {name: topicId, var: topic_id}, {name: type, var: type, style: multi}, {name: videoCaption, var: video_caption}, {name: videoCategoryId, var: video_category_id}, {name: videoDefinition, var: video_definition}, {name: videoDimension, var: video_dimension}, {name: videoDuration, var: video_duration}, {name: videoEmbeddable, var: video_embeddable}, {name: videoLicense, var: video_license}, {name: videoSyndicated, var: video_syndicated}, {name: videoType, var: video_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, channel_id: $channel_id, channel_type: $channel_type, event_type: $event_type, for_content_owner: $for_content_owner, for_developer: $for_developer, for_mine: $for_mine, location: $location, location_radius: $location_radius, max_results: $max_results, on_behalf_of_content_owner: $on_behalf_of_content_owner, order: $order, page_token: $page_token, published_after: $published_after, published_before: $published_before, q: $q, region_code: $region_code, related_to_video_id: $related_to_video_id, relevance_language: $relevance_language, safe_search: $safe_search, topic_id: $topic_id, type: $type, video_caption: $video_caption, video_category_id: $video_category_id, video_definition: $video_definition, video_dimension: $video_dimension, video_duration: $video_duration, video_embeddable: $video_embeddable, video_license: $video_license, video_syndicated: $video_syndicated, video_type: $video_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/subscriptions
# operationId: youtube.subscriptions.delete
export def "youtube-subscriptions-delete" [
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
  --id: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/subscriptions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/subscriptions
# Returns: record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, subscriberSnippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.subscriptions.list
export def "youtube-subscriptions-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more subscription resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a subscription resource, the snippet property contains other properties, such as a display title for the subscription. If you set *part=snippet*, the API response will also contain all of those nested properties. (required)
  --channel-id: string # Return the subscriptions of the given channel owner.
  --for-channel-id: string # Return the subscriptions to the subset of these channels that the authenticated user is subscribed to.
  --id: list<string> # Return the subscriptions with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Flag for returning the subscriptions of the authenticated user.
  --my-recent-subscribers: oneof<nothing, bool>
  --my-subscribers: oneof<nothing, bool> # Return the subscribers of the given channel owner.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --order: string@order-completer-2 # The order of the returned subscriptions
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/subscriptions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: channelId, var: channel_id}, {name: forChannelId, var: for_channel_id}, {name: id, var: id, style: multi}, {name: maxResults, var: max_results}, {name: mine, var: mine}, {name: myRecentSubscribers, var: my_recent_subscribers}, {name: mySubscribers, var: my_subscribers}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: order, var: order}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, channel_id: $channel_id, for_channel_id: $for_channel_id, id: $id, max_results: $max_results, mine: $mine, my_recent_subscribers: $my_recent_subscribers, my_subscribers: $my_subscribers, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, order: $order, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/subscriptions
# Returns: record<contentDetails: record<activityType: string, newItemCount: int, totalItemCount: int>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, subscriberSnippet: record<channelId: string, description: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>>
# operationId: youtube.subscriptions.insert
export def "youtube-subscriptions-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. (required)
  --content-details: record # Details about the content to witch a subscription refers. — shape: {activityType?: "subscriptionActivityTypeUnspecified"|"all"|"uploads", newItemCount?: int, totalItemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the subscription.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#subscription". (default: youtube#subscription)
  --snippet: record # Basic details about a subscription, including title, description and thumbnails of the subscribed item. — shape: {channelId?: string, channelTitle?: string, description?: string, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string}
  --subscriber-snippet: record # Basic details about a subscription's subscriber including title, description, channel ID and thumbnails. — shape: {channelId?: string, description?: string, thumbnails?: record, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/subscriptions"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: snippet, var: snippet}, {name: subscriberSnippet, var: subscriber_snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, content_details: $content_details, etag: $etag, id: $id, kind: $kind, snippet: $snippet, subscriber_snippet: $subscriber_snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/superChatEvents
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string>
# operationId: youtube.superChatEvents.list
export def "youtube-super-chat-events-list" [
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
  --part: list<string> # The *part* parameter specifies the superChatEvent resource parts that the API response will include. This parameter is currently not supported. (required)
  --hl: string # Return rendered funding amounts in specified language.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/superChatEvents"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, hl: $hl, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST method.
#
# POST /youtube/v3/tests
# Returns: record<featuredPart: bool, gaia: string, id: string, snippet: record>
# operationId: youtube.tests.insert
export def "youtube-tests-insert" [
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
  --part: list<string> # required
  --external-channel-id: string
  --featured-part: oneof<nothing, bool>
  --gaia: string # format: int64
  --id: string
  --snippet: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/tests"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: externalChannelId, var: external_channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: featuredPart, var: featured_part}, {name: gaia, var: gaia}, {name: id, var: id}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, external_channel_id: $external_channel_id, featured_part: $featured_part, gaia: $gaia, id: $id, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/thirdPartyLinks
# operationId: youtube.thirdPartyLinks.delete
export def "youtube-third-party-links-delete" [
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
  --linking-token: string # Delete the partner links with the given linking token. (required)
  --type: string@type-completer # Type of the link to be deleted. (required)
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --part: list<string> # Do not use. Required for compatibility.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/thirdPartyLinks"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: linkingToken, var: linking_token, required: true}, {name: type, var: type, required: true}, {name: externalChannelId, var: external_channel_id}, {name: part, var: part, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, linking_token: $linking_token, type: $type, external_channel_id: $external_channel_id, part: $part
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/thirdPartyLinks
# Returns: record<etag: string, items: table<etag: string, kind: string, linkingToken: string, snippet: record, status: record>, kind: string>
# operationId: youtube.thirdPartyLinks.list
export def "youtube-third-party-links-list" [
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
  --part: list<string> # The *part* parameter specifies the thirdPartyLink resource parts that the API response will include. Supported values are linkingToken, status, and snippet. (required)
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --linking-token: string # Get a third party link with the given linking token.
  --type: string@type-completer # Get a third party link of the given type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/thirdPartyLinks"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: externalChannelId, var: external_channel_id}, {name: linkingToken, var: linking_token}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, external_channel_id: $external_channel_id, linking_token: $linking_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/thirdPartyLinks
# Returns: record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>>
# operationId: youtube.thirdPartyLinks.insert
export def "youtube-third-party-links-insert" [
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
  --part: list<string> # The *part* parameter specifies the thirdPartyLink resource parts that the API request and response will include. Supported values are linkingToken, status, and snippet. (required)
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --etag: string # Etag of this resource
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#thirdPartyLink". (default: youtube#thirdPartyLink)
  --linking-token: string # The linking_token identifies a YouTube account and channel with which the third party account is linked.
  --snippet: record # Basic information about a third party account link, including its type and type-specific information. — shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
  --status: record # The third-party link status object contains information about the status of the link. — shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/thirdPartyLinks"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: externalChannelId, var: external_channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: kind, var: kind}, {name: linkingToken, var: linking_token}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, external_channel_id: $external_channel_id, etag: $etag, kind: $kind, linking_token: $linking_token, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/thirdPartyLinks
# Returns: record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>>
# operationId: youtube.thirdPartyLinks.update
export def "youtube-third-party-links-update" [
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
  --part: list<string> # The *part* parameter specifies the thirdPartyLink resource parts that the API request and response will include. Supported values are linkingToken, status, and snippet. (required)
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --etag: string # Etag of this resource
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#thirdPartyLink". (default: youtube#thirdPartyLink)
  --linking-token: string # The linking_token identifies a YouTube account and channel with which the third party account is linked.
  --snippet: record # Basic information about a third party account link, including its type and type-specific information. — shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
  --status: record # The third-party link status object contains information about the status of the link. — shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/thirdPartyLinks"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: externalChannelId, var: external_channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: kind, var: kind}, {name: linkingToken, var: linking_token}, {name: snippet, var: snippet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, external_channel_id: $external_channel_id, etag: $etag, kind: $kind, linking_token: $linking_token, snippet: $snippet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# As this is not an insert in a strict sense (it supports uploading/setting of a thumbnail for multiple videos, which doesn't result in creation of a single resource), I use a custom verb here.
#
# POST /youtube/v3/thumbnails/set
# Returns: record<etag: string, eventId: string, items: table<high: record, maxres: record, medium: record, standard: record>, kind: string, visitorId: string>
# operationId: youtube.thumbnails.set
export def "youtube-thumbnails-set" [
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
  --video-id: string # Returns the Thumbnail with the given video IDs for Stubby or Apiary. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/youtube/v3/thumbnails/set"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: videoId, var: video_id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, video_id: $video_id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videoAbuseReportReasons
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string>
# operationId: youtube.videoAbuseReportReasons.list
export def "youtube-video-abuse-report-reasons-list" [
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
  --part: list<string> # The *part* parameter specifies the videoCategory resource parts that the API response will include. Supported values are id and snippet. (required)
  --hl: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/videoAbuseReportReasons"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, hl: $hl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videoCategories
# Returns: record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.videoCategories.list
export def "youtube-video-categories-list" [
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
  --part: list<string> # The *part* parameter specifies the videoCategory resource properties that the API response will include. Set the parameter value to snippet. (required)
  --hl: string
  --id: list<string> # Returns the video categories with the given IDs for Stubby or Apiary.
  --region-code: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/videoCategories"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: hl, var: hl}, {name: id, var: id, style: multi}, {name: regionCode, var: region_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, hl: $hl, id: $id, region_code: $region_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource.
#
# DELETE /youtube/v3/videos
# operationId: youtube.videos.delete
export def "youtube-videos-delete" [
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
  --id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: delete
    path: "/youtube/v3/videos"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videos
# Returns: record<etag: string, eventId: string, items: table<ageGating: record, contentDetails: record, etag: string, fileDetails: record, id: string, kind: string, liveStreamingDetails: record, localizations: record, monetizationDetails: record, player: record, processingDetails: record, projectDetails: record, recordingDetails: record, snippet: record, statistics: record, status: record, suggestions: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string>
# operationId: youtube.videos.list
export def "youtube-videos-list" [
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
  --part: list<string> # The *part* parameter specifies a comma-separated list of one or more video resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a video resource, the snippet property contains the channelId, title, description, tags, and categoryId properties. As such, if you set *part=snippet*, the API response will contain all of those properties. (required)
  --chart: string@chart-completer # Return the videos that are in the specified chart.
  --hl: string # Stands for "host language". Specifies the localization language of the metadata to be filled into snippet.localized. The field is filled with the default metadata if there is no localization in the specified language. The parameter value must be a language code included in the list returned by the i18nLanguages.list method (e.g. en_US, es_MX).
  --id: list<string> # Return videos with the given ids.
  --locale: string
  --max-height: int
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set. *Note:* This parameter is supported for use in conjunction with the myRating and chart parameters, but it is not supported for use in conjunction with the id parameter.
  --max-width: int # Return the player with maximum height specified in
  --my-rating: string@my-rating-completer # Return videos liked/disliked by the authenticated user. Does not support RateType.RATED_TYPE_NONE.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved. *Note:* This parameter is supported for use in conjunction with the myRating and chart parameters, but it is not supported for use in conjunction with the id parameter.
  --region-code: string # Use a chart that is specific to the specified region
  --video-category-id: string # Use chart that is specific to the specified video category
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/videos"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: chart, var: chart}, {name: hl, var: hl}, {name: id, var: id, style: multi}, {name: locale, var: locale}, {name: maxHeight, var: max_height}, {name: maxResults, var: max_results}, {name: maxWidth, var: max_width}, {name: myRating, var: my_rating}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: pageToken, var: page_token}, {name: regionCode, var: region_code}, {name: videoCategoryId, var: video_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, chart: $chart, hl: $hl, id: $id, locale: $locale, max_height: $max_height, max_results: $max_results, max_width: $max_width, my_rating: $my_rating, on_behalf_of_content_owner: $on_behalf_of_content_owner, page_token: $page_token, region_code: $region_code, video_category_id: $video_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/videos
# Returns: record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>>
# operationId: youtube.videos.insert
export def "youtube-videos-insert" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that not all parts contain properties that can be set when inserting or updating a video. For example, the statistics object encapsulates statistics that YouTube calculates for a video and does not contain values that you can set or modify. If the parameter value specifies a part that does not contain mutable values, that part will still be included in the API response. (required)
  --auto-levels: oneof<nothing, bool> # Should auto-levels be applied to the upload.
  --notify-subscribers: oneof<nothing, bool> # Notify the channel subscribers about the new video. As default, the notification is enabled.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --stabilize: oneof<nothing, bool> # Should stabilize be applied to the upload.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/youtube/v3/videos"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: autoLevels, var: auto_levels}, {name: notifySubscribers, var: notify_subscribers}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}, {name: onBehalfOfContentOwnerChannel, var: on_behalf_of_content_owner_channel}, {name: stabilize, var: stabilize}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, auto_levels: $auto_levels, notify_subscribers: $notify_subscribers, on_behalf_of_content_owner: $on_behalf_of_content_owner, on_behalf_of_content_owner_channel: $on_behalf_of_content_owner_channel, stabilize: $stabilize, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing resource.
#
# PUT /youtube/v3/videos
# Returns: record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>>
# operationId: youtube.videos.update
export def "youtube-videos-update" [
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
  --part: list<string> # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a video's privacy setting is contained in the status part. As such, if your request is updating a private video, and the request's part parameter value includes the status part, the video's privacy setting will be updated to whatever value the request body specifies. If the request body does not specify a value, the existing privacy setting will be removed and the video will revert to the default privacy setting. In addition, not all parts contain properties that can be set when inserting or updating a video. For example, the statistics object encapsulates statistics that YouTube calculates for a video and does not contain values that you can set or modify. If the parameter value specifies a part that does not contain mutable values, that part will still be included in the API response. (required)
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --age-gating: record # shape: {alcoholContent?: bool, restricted?: bool, videoGameRating?: "anyone"|"m15Plus"|"m16Plus"|"m17Plus"}
  --content-details: record # Details about the content of a YouTube Video. — shape: {caption?: "true"|"false", contentRating?: record, countryRestriction?: record, definition?: "sd"|"hd", dimension?: string, duration?: string, hasCustomThumbnail?: bool, licensedContent?: bool, projection?: "rectangular"|"360", regionRestriction?: record}
  --etag: string # Etag of this resource.
  --file-details: record # Describes original video file properties, including technical details about audio and video streams, but also metadata information like content length, digitization time, or geotagging information. — shape: {audioStreams?: list, bitrateBps?: string, container?: string, creationTime?: string, durationMs?: string, fileName?: string, fileSize?: string, fileType?: "video"|"audio"|"image"|"archive"|"document"|"project"|"other", videoStreams?: list}
  --id: string # The ID that YouTube uses to uniquely identify the video.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#video". (default: youtube#video)
  --live-streaming-details: record # Details about the live streaming metadata. — shape: {activeLiveChatId?: string, actualEndTime?: string, actualStartTime?: string, concurrentViewers?: string, scheduledEndTime?: string, scheduledStartTime?: string}
  --localizations: record # The localizations object contains localized versions of the basic details about the video, such as its title and description.
  --monetization-details: record # Details about monetization of a YouTube Video. — shape: {access?: record}
  --player: record # Player to be used for a video playback. — shape: {embedHeight?: string, embedHtml?: string, embedWidth?: string}
  --processing-details: record # Describes processing status and progress and availability of some other Video resource parts. — shape: {editorSuggestionsAvailability?: string, fileDetailsAvailability?: string, processingFailureReason?: "uploadFailed"|"transcodeFailed"|"streamingFailed"|"other", processingIssuesAvailability?: string, processingProgress?: record, processingStatus?: "processing"|"succeeded"|"failed"|"terminated", tagSuggestionsAvailability?: string, thumbnailsAvailability?: string}
  --project-details: record # DEPRECATED. b/157517979: This part was never populated after it was added. However, it sees non-zero traffic because there is generated client code in the wild that refers to it [1]. We keep this field and do NOT remove it because otherwise V3 would return an error when this part gets requested [2]. [1] https://developers.google.com/resources/api-libraries/documentation/youtube/v3/csharp/latest/classGoogle_1_1Apis_1_1YouTube_1_1v3_1_1Data_1_1VideoProjectDetails.html [2] http://google3/video/youtube/src/python/servers/data_api/common.py?l=1565-1569&rcl=344141677
  --recording-details: record # Recording information associated with the video. — shape: {location?: record, locationDescription?: string, recordingDate?: string}
  --snippet: record # Basic details about a video, including title, description, uploader, thumbnails and category. — shape: {categoryId?: string, channelId?: string, channelTitle?: string, defaultAudioLanguage?: string, defaultLanguage?: string, description?: string, liveBroadcastContent?: "none"|"upcoming"|"live"|"completed", localized?: record, publishedAt?: string, tags?: list<string>, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the video, such as the number of times the video was viewed or liked. — shape: {commentCount?: string, dislikeCount?: string, favoriteCount?: string, likeCount?: string, viewCount?: string}
  --status: record # Basic details about a video category, such as its localized title. Next Id: 18 — shape: {embeddable?: bool, failureReason?: "conversion"|"invalidFile"|"emptyFile"|"tooSmall"|"codec"|"uploadAborted", license?: "youtube"|"creativeCommon", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", publicStatsViewable?: bool, publishAt?: string, rejectionReason?: "copyright"|"inappropriate"|"duplicate"|"termsOfUse"|"uploaderAccountSuspended"|"length"|"claim"|"uploaderAccountClosed"|"trademark"|"legal", selfDeclaredMadeForKids?: bool, ... (1 more fields)}
  --suggestions: record # Specifies suggestions on how to improve video content, including encoding hints, tag suggestions, and editor suggestions. — shape: {editorSuggestions?: list<string>, processingErrors?: list<string>, processingHints?: list<string>, processingWarnings?: list<string>, tagSuggestions?: list}
  --topic-details: record # Freebase topic information related to the video. — shape: {relevantTopicIds?: list<string>, topicCategories?: list<string>, topicIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/youtube/v3/videos"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: part, var: part, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: ageGating, var: age_gating}, {name: contentDetails, var: content_details}, {name: etag, var: etag}, {name: fileDetails, var: file_details}, {name: id, var: id}, {name: kind, var: kind}, {name: liveStreamingDetails, var: live_streaming_details}, {name: localizations, var: localizations}, {name: monetizationDetails, var: monetization_details}, {name: player, var: player}, {name: processingDetails, var: processing_details}, {name: projectDetails, var: project_details}, {name: recordingDetails, var: recording_details}, {name: snippet, var: snippet}, {name: statistics, var: statistics}, {name: status, var: status}, {name: suggestions, var: suggestions}, {name: topicDetails, var: topic_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, part: $part, on_behalf_of_content_owner: $on_behalf_of_content_owner, age_gating: $age_gating, content_details: $content_details, etag: $etag, file_details: $file_details, id: $id, kind: $kind, live_streaming_details: $live_streaming_details, localizations: $localizations, monetization_details: $monetization_details, player: $player, processing_details: $processing_details, project_details: $project_details, recording_details: $recording_details, snippet: $snippet, statistics: $statistics, status: $status, suggestions: $suggestions, topic_details: $topic_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the ratings that the authorized user gave to a list of specified videos.
#
# GET /youtube/v3/videos/getRating
# Returns: record<etag: string, eventId: string, items: table<rating: string, videoId: string>, kind: string, visitorId: string>
# operationId: youtube.videos.getRating
export def "youtube-videos-get-rating" [
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
  --id: list<string> # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/youtube/v3/videos/getRating"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, style: multi, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a like or dislike rating to a video or removes a rating from a video.
#
# POST /youtube/v3/videos/rate
# operationId: youtube.videos.rate
export def "youtube-videos-rate" [
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
  --id: string # required
  --rating: string@rating-completer # required
]: nothing -> any {
  http-request {
    method: post
    path: "/youtube/v3/videos/rate"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: id, var: id, required: true}, {name: rating, var: rating, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, rating: $rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report abuse for a video.
#
# POST /youtube/v3/videos/reportAbuse
# operationId: youtube.videos.reportAbuse
export def "youtube-videos-report-abuse" [
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
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --comments: string # Additional comments regarding the abuse report.
  --language: string # The language that the content was viewed in.
  --reason-id: string # The high-level, or primary, reason that the content is abusive. The value is an abuse report reason ID.
  --secondary-reason-id: string # The specific, or secondary, reason that this content is abusive (if available). The value is an abuse report reason ID that is a valid secondary reason for the primary reason.
  --video-id: string # The ID that YouTube uses to uniquely identify the video.
]: any -> any {
  $in | http-request {
    method: post
    path: "/youtube/v3/videos/reportAbuse"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}, {name: language, var: language}, {name: reasonId, var: reason_id}, {name: secondaryReasonId, var: secondary_reason_id}, {name: videoId, var: video_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, on_behalf_of_content_owner: $on_behalf_of_content_owner, comments: $comments, language: $language, reason_id: $reason_id, secondary_reason_id: $secondary_reason_id, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows upload of watermark image and setting it for a channel.
#
# POST /youtube/v3/watermarks/set
# operationId: youtube.watermarks.set
export def "youtube-watermarks-set" [
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
  --channel-id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/youtube/v3/watermarks/set"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: channelId, var: channel_id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, channel_id: $channel_id, on_behalf_of_content_owner: $on_behalf_of_content_owner, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows removal of channel watermark.
#
# POST /youtube/v3/watermarks/unset
# operationId: youtube.watermarks.unset
export def "youtube-watermarks-unset" [
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
  --channel-id: string # required
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  http-request {
    method: post
    path: "/youtube/v3/watermarks/unset"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: channelId, var: channel_id, required: true}, {name: onBehalfOfContentOwner, var: on_behalf_of_content_owner}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, channel_id: $channel_id, on_behalf_of_content_owner: $on_behalf_of_content_owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
