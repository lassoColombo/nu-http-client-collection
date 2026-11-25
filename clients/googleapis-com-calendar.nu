# Auto-generated client for Calendar API v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/calendar/v3/openapi.json
# Auth: --token flag or $env.CALENDAR_API_TOKEN

const CLIENT = {
  base_url: "https://www.googleapis.com/calendar/v3"
  token_env_var: "CALENDAR_API_TOKEN"
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

def base-url-completer [] { ["https://www.googleapis.com/calendar/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def order-by-completer [] { ["startTime" "updated"] }
def send-updates-completer [] { ["all" "externalOnly" "none"] }
def min-access-role-completer [] { ["freeBusyReader" "owner" "reader" "writer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    calendar-calendars-insert: "record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>"
    calendar-calendars-get: "record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>"
    calendar-calendars-patch: "record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>"
    calendar-calendars-update: "record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>"
    calendar-acl-list: "record<etag: string, items: table<etag: string, id: string, kind: string, role: string, scope: record>, kind: string, nextPageToken: string, nextSyncToken: string>"
    calendar-acl-insert: "record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>"
    calendar-acl-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    calendar-acl-get: "record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>"
    calendar-acl-patch: "record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>"
    calendar-acl-update: "record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>"
    calendar-events-list: "record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string>"
    calendar-events-insert: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-import: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-quick-add: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    calendar-events-get: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-patch: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-update: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-events-instances: "record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string>"
    calendar-events-move: "record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>"
    calendar-colors-get: "record<calendar: record, event: record, kind: string, updated: string>"
    calendar-freebusy-query: "record<calendars: record, groups: record, kind: string, timeMax: string, timeMin: string>"
    calendar-calendar-list-list: "record<etag: string, items: table<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record, defaultReminders: list, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>, kind: string, nextPageToken: string, nextSyncToken: string>"
    calendar-calendar-list-insert: "record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>"
    calendar-calendar-list-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    calendar-calendar-list-get: "record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>"
    calendar-calendar-list-patch: "record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>"
    calendar-calendar-list-update: "record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>"
    calendar-settings-list: "record<etag: string, items: table<etag: string, id: string, kind: string, value: string>, kind: string, nextPageToken: string, nextSyncToken: string>"
    calendar-settings-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    calendar-settings-get: "record<etag: string, id: string, kind: string, value: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["calendar-calendars-insert" "calendar-calendars-delete" "calendar-calendars-get" "calendar-calendars-patch" "calendar-calendars-update" "calendar-acl-list" "calendar-acl-insert" "calendar-acl-watch" "calendar-acl-delete" "calendar-acl-get" "calendar-acl-patch" "calendar-acl-update" "calendar-calendars-clear" "calendar-events-list" "calendar-events-insert" "calendar-events-import" "calendar-events-quick-add" "calendar-events-watch" "calendar-events-delete" "calendar-events-get" "calendar-events-patch" "calendar-events-update" "calendar-events-instances" "calendar-events-move" "calendar-channels-stop" "calendar-colors-get" "calendar-freebusy-query" "calendar-calendar-list-list" "calendar-calendar-list-insert" "calendar-calendar-list-watch" "calendar-calendar-list-delete" "calendar-calendar-list-get" "calendar-calendar-list-patch" "calendar-calendar-list-update" "calendar-settings-list" "calendar-settings-watch" "calendar-settings-get" "commands"] | sort) } | get name | first)
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

# Creates a secondary calendar.
#
# POST /calendars
# Returns: record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>
# operationId: calendar.calendars.insert
export def "calendar-calendars-insert" [
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
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: conferenceProperties, var: conference_properties}, {name: description, var: description}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: summary, var: summary}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, conference_properties: $conference_properties, description: $description, etag: $etag, id: $id, kind: $kind, location: $location, summary: $summary, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a secondary calendar. Use calendars.clear for clearing all events on primary calendars.
#
# DELETE /calendars/{calendarId}
# operationId: calendar.calendars.delete
export def "calendar-calendars-delete" [
  calendar_id: string
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
    path: "/calendars/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata for a calendar.
#
# GET /calendars/{calendarId}
# Returns: record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>
# operationId: calendar.calendars.get
export def "calendar-calendars-get" [
  calendar_id: string
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
    path: "/calendars/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates metadata for a calendar. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}
# Returns: record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>
# operationId: calendar.calendars.patch
export def "calendar-calendars-patch" [
  calendar_id: string
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
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/calendars/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: conferenceProperties, var: conference_properties}, {name: description, var: description}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: summary, var: summary}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, conference_properties: $conference_properties, description: $description, etag: $etag, id: $id, kind: $kind, location: $location, summary: $summary, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates metadata for a calendar.
#
# PUT /calendars/{calendarId}
# Returns: record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string>
# operationId: calendar.calendars.update
export def "calendar-calendars-update" [
  calendar_id: string
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
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/calendars/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: conferenceProperties, var: conference_properties}, {name: description, var: description}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: summary, var: summary}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, conference_properties: $conference_properties, description: $description, etag: $etag, id: $id, kind: $kind, location: $location, summary: $summary, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the rules in the access control list for the calendar.
#
# GET /calendars/{calendarId}/acl
# Returns: record<etag: string, items: table<etag: string, id: string, kind: string, role: string, scope: record>, kind: string, nextPageToken: string, nextSyncToken: string>
# operationId: calendar.acl.list
export def "calendar-acl-list" [
  calendar_id: string
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted ACLs in the result. Deleted ACLs are represented by role equal to "none". Deleted ACLs will always be included if syncToken is provided. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All entries deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calendars/{calendarId}/acl"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, show_deleted: $show_deleted, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an access control rule.
#
# POST /calendars/{calendarId}/acl
# Returns: record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>
# operationId: calendar.acl.insert
export def "calendar-acl-insert" [
  calendar_id: string
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
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars/{calendarId}/acl"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: sendNotifications, var: send_notifications}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, send_notifications: $send_notifications, etag: $etag, id: $id, kind: $kind, role: $role, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch for changes to ACL resources.
#
# POST /calendars/{calendarId}/acl/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: calendar.acl.watch
export def "calendar-acl-watch" [
  calendar_id: string
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted ACLs in the result. Deleted ACLs are represented by role equal to "none". Deleted ACLs will always be included if syncToken is provided. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All entries deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars/{calendarId}/acl/watch"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: syncToken, var: sync_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, show_deleted: $show_deleted, sync_token: $sync_token, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an access control rule.
#
# DELETE /calendars/{calendarId}/acl/{ruleId}
# operationId: calendar.acl.delete
export def "calendar-acl-delete" [
  calendar_id: string
  rule_id: string
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
    path: "/calendars/{calendarId}/acl/{ruleId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: ruleId, var: rule_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, rule_id: $rule_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an access control rule.
#
# GET /calendars/{calendarId}/acl/{ruleId}
# Returns: record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>
# operationId: calendar.acl.get
export def "calendar-acl-get" [
  calendar_id: string
  rule_id: string
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
    path: "/calendars/{calendarId}/acl/{ruleId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: ruleId, var: rule_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, rule_id: $rule_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an access control rule. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}/acl/{ruleId}
# Returns: record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>
# operationId: calendar.acl.patch
export def "calendar-acl-patch" [
  calendar_id: string
  rule_id: string
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
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Note that there are no notifications on access removal. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/calendars/{calendarId}/acl/{ruleId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: ruleId, var: rule_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: sendNotifications, var: send_notifications}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, rule_id: $rule_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, send_notifications: $send_notifications, etag: $etag, id: $id, kind: $kind, role: $role, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an access control rule.
#
# PUT /calendars/{calendarId}/acl/{ruleId}
# Returns: record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>>
# operationId: calendar.acl.update
export def "calendar-acl-update" [
  calendar_id: string
  rule_id: string
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
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Note that there are no notifications on access removal. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/calendars/{calendarId}/acl/{ruleId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: ruleId, var: rule_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: sendNotifications, var: send_notifications}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, rule_id: $rule_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, send_notifications: $send_notifications, etag: $etag, id: $id, kind: $kind, role: $role, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears a primary calendar. This operation deletes all events associated with the primary calendar of an account.
#
# POST /calendars/{calendarId}/clear
# operationId: calendar.calendars.clear
export def "calendar-calendars-clear" [
  calendar_id: string
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
    path: "/calendars/{calendarId}/clear"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns events on the specified calendar.
#
# GET /calendars/{calendarId}/events
# Returns: record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string>
# operationId: calendar.events.list
export def "calendar-events-list" [
  calendar_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --event-types: list<string> # Event types to return. Optional. Possible values are: - "default" - "focusTime" - "outOfOffice"This parameter can be repeated multiple times to return events of different types. Currently, this is the only allowed value for this field: - ["default", "focusTime", "outOfOffice"] This value will be the default. If you're enrolled in the Working Location developer preview program, in addition to the default value above you can also set the "workingLocation" event type: - ["default", "focusTime", "outOfOffice", "workingLocation"] - ["workingLocation"] Additional combinations of these 4 event types will be made available in later releases. Developer Preview.
  --i-cal-uid: string # Specifies an event ID in the iCalendar format to be provided in the response. Optional. Use this if you want to search for an event by its iCalendar ID.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. The number of events in the resulting page may be less than this value, or none at all, even if there are more events matching the query. Incomplete pages can be detected by a non-empty nextPageToken field in the response. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --order-by: string@order-by-completer # The order of the events returned in the result. Optional. The default is an unspecified, stable order.
  --page-token: string # Token specifying which result page to return. Optional.
  --private-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only private properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --q: string # Free text search terms to find events that match these terms in the following fields: summary, description, location, attendee's displayName, attendee's email. Optional.
  --shared-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only shared properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events (but not the underlying recurring event) will still be included if showDeleted and singleEvents are both False. If showDeleted and singleEvents are both True, only single instances of deleted events (but not the underlying recurring events) are returned. Optional. The default is False.
  --show-hidden-invitations: oneof<nothing, bool> # Whether to include hidden invitations in the result. Optional. The default is False.
  --single-events: oneof<nothing, bool> # Whether to expand recurring events into instances and only return single one-off events and instances of recurring events, but not the underlying recurring events themselves. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All events deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. There are several query parameters that cannot be specified together with nextSyncToken to ensure consistency of the client state. These are: - iCalUID - orderBy - privateExtendedProperty - q - sharedExtendedProperty - timeMin - timeMax - updatedMin If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMin is set, timeMax must be greater than timeMin.
  --time-min: string # Lower bound (exclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMax is set, timeMin must be smaller than timeMax.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
  --updated-min: string # Lower bound for an event's last modification time (as a RFC3339 timestamp) to filter by. When specified, entries deleted since this time will always be included regardless of showDeleted. Optional. The default is not to filter by last modification time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calendars/{calendarId}/events"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: eventTypes, var: event_types, style: multi}, {name: iCalUID, var: i_cal_uid}, {name: maxAttendees, var: max_attendees}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: privateExtendedProperty, var: private_extended_property, style: multi}, {name: q, var: q}, {name: sharedExtendedProperty, var: shared_extended_property, style: multi}, {name: showDeleted, var: show_deleted}, {name: showHiddenInvitations, var: show_hidden_invitations}, {name: singleEvents, var: single_events}, {name: syncToken, var: sync_token}, {name: timeMax, var: time_max}, {name: timeMin, var: time_min}, {name: timeZone, var: time_zone}, {name: updatedMin, var: updated_min}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, event_types: $event_types, i_cal_uid: $i_cal_uid, max_attendees: $max_attendees, max_results: $max_results, order_by: $order_by, page_token: $page_token, private_extended_property: $private_extended_property, q: $q, shared_extended_property: $shared_extended_property, show_deleted: $show_deleted, show_hidden_invitations: $show_hidden_invitations, single_events: $single_events, sync_token: $sync_token, time_max: $time_max, time_min: $time_min, time_zone: $time_zone, updated_min: $updated_min
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an event.
#
# POST /calendars/{calendarId}/events
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.insert
export def "calendar-events-insert" [
  calendar_id: string
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
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the creation of the new event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Whether to send notifications about the creation of the new event. Note that some emails might still be sent. The default is false.
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars/{calendarId}/events"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: conferenceDataVersion, var: conference_data_version}, {name: maxAttendees, var: max_attendees}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}, {name: supportsAttachments, var: supports_attachments}]
    body: {content_type: "application/json", kind: json, fields: [{name: anyoneCanAddSelf, var: anyone_can_add_self}, {name: attachments, var: attachments}, {name: attendees, var: attendees}, {name: attendeesOmitted, var: attendees_omitted}, {name: colorId, var: color_id}, {name: conferenceData, var: conference_data}, {name: created, var: created}, {name: creator, var: creator}, {name: description, var: description}, {name: end, var: end}, {name: endTimeUnspecified, var: end_time_unspecified}, {name: etag, var: etag}, {name: eventType, var: event_type}, {name: extendedProperties, var: extended_properties}, {name: gadget, var: gadget}, {name: guestsCanInviteOthers, var: guests_can_invite_others}, {name: guestsCanModify, var: guests_can_modify}, {name: guestsCanSeeOtherGuests, var: guests_can_see_other_guests}, {name: hangoutLink, var: hangout_link}, {name: htmlLink, var: html_link}, {name: iCalUID, var: i_cal_uid}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: locked, var: locked}, {name: organizer, var: organizer}, {name: originalStartTime, var: original_start_time}, {name: privateCopy, var: private_copy}, {name: recurrence, var: recurrence}, {name: recurringEventId, var: recurring_event_id}, {name: reminders, var: reminders}, {name: sequence, var: sequence}, {name: source, var: source}, {name: start, var: start}, {name: status, var: status}, {name: summary, var: summary}, {name: transparency, var: transparency}, {name: updated, var: updated}, {name: visibility, var: visibility}, {name: workingLocationProperties, var: working_location_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, conference_data_version: $conference_data_version, max_attendees: $max_attendees, send_notifications: $send_notifications, send_updates: $send_updates, supports_attachments: $supports_attachments, anyone_can_add_self: $anyone_can_add_self, attachments: $attachments, attendees: $attendees, attendees_omitted: $attendees_omitted, color_id: $color_id, conference_data: $conference_data, created: $created, creator: $creator, description: $description, end: $end, end_time_unspecified: $end_time_unspecified, etag: $etag, event_type: $event_type, extended_properties: $extended_properties, gadget: $gadget, guests_can_invite_others: $guests_can_invite_others, guests_can_modify: $guests_can_modify, guests_can_see_other_guests: $guests_can_see_other_guests, hangout_link: $hangout_link, html_link: $html_link, i_cal_uid: $i_cal_uid, id: $id, kind: $kind, location: $location, locked: $locked, organizer: $organizer, original_start_time: $original_start_time, private_copy: $private_copy, recurrence: $recurrence, recurring_event_id: $recurring_event_id, reminders: $reminders, sequence: $sequence, source: $source, start: $start, status: $status, summary: $summary, transparency: $transparency, updated: $updated, visibility: $visibility, working_location_properties: $working_location_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports an event. This operation is used to add a private copy of an existing event to a calendar.
#
# POST /calendars/{calendarId}/events/import
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.import
export def "calendar-events-import" [
  calendar_id: string
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
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars/{calendarId}/events/import"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: conferenceDataVersion, var: conference_data_version}, {name: supportsAttachments, var: supports_attachments}]
    body: {content_type: "application/json", kind: json, fields: [{name: anyoneCanAddSelf, var: anyone_can_add_self}, {name: attachments, var: attachments}, {name: attendees, var: attendees}, {name: attendeesOmitted, var: attendees_omitted}, {name: colorId, var: color_id}, {name: conferenceData, var: conference_data}, {name: created, var: created}, {name: creator, var: creator}, {name: description, var: description}, {name: end, var: end}, {name: endTimeUnspecified, var: end_time_unspecified}, {name: etag, var: etag}, {name: eventType, var: event_type}, {name: extendedProperties, var: extended_properties}, {name: gadget, var: gadget}, {name: guestsCanInviteOthers, var: guests_can_invite_others}, {name: guestsCanModify, var: guests_can_modify}, {name: guestsCanSeeOtherGuests, var: guests_can_see_other_guests}, {name: hangoutLink, var: hangout_link}, {name: htmlLink, var: html_link}, {name: iCalUID, var: i_cal_uid}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: locked, var: locked}, {name: organizer, var: organizer}, {name: originalStartTime, var: original_start_time}, {name: privateCopy, var: private_copy}, {name: recurrence, var: recurrence}, {name: recurringEventId, var: recurring_event_id}, {name: reminders, var: reminders}, {name: sequence, var: sequence}, {name: source, var: source}, {name: start, var: start}, {name: status, var: status}, {name: summary, var: summary}, {name: transparency, var: transparency}, {name: updated, var: updated}, {name: visibility, var: visibility}, {name: workingLocationProperties, var: working_location_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, conference_data_version: $conference_data_version, supports_attachments: $supports_attachments, anyone_can_add_self: $anyone_can_add_self, attachments: $attachments, attendees: $attendees, attendees_omitted: $attendees_omitted, color_id: $color_id, conference_data: $conference_data, created: $created, creator: $creator, description: $description, end: $end, end_time_unspecified: $end_time_unspecified, etag: $etag, event_type: $event_type, extended_properties: $extended_properties, gadget: $gadget, guests_can_invite_others: $guests_can_invite_others, guests_can_modify: $guests_can_modify, guests_can_see_other_guests: $guests_can_see_other_guests, hangout_link: $hangout_link, html_link: $html_link, i_cal_uid: $i_cal_uid, id: $id, kind: $kind, location: $location, locked: $locked, organizer: $organizer, original_start_time: $original_start_time, private_copy: $private_copy, recurrence: $recurrence, recurring_event_id: $recurring_event_id, reminders: $reminders, sequence: $sequence, source: $source, start: $start, status: $status, summary: $summary, transparency: $transparency, updated: $updated, visibility: $visibility, working_location_properties: $working_location_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an event based on a simple text string.
#
# POST /calendars/{calendarId}/events/quickAdd
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.quickAdd
export def "calendar-events-quick-add" [
  calendar_id: string
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
  --text: string # The text describing the event to be created. (required)
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the creation of the event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the creation of the new event.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/calendars/{calendarId}/events/quickAdd"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: text, var: text, required: true}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, text: $text, send_notifications: $send_notifications, send_updates: $send_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch for changes to Events resources.
#
# POST /calendars/{calendarId}/events/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: calendar.events.watch
export def "calendar-events-watch" [
  calendar_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --event-types: list<string> # Event types to return. Optional. Possible values are: - "default" - "focusTime" - "outOfOffice"This parameter can be repeated multiple times to return events of different types. Currently, this is the only allowed value for this field: - ["default", "focusTime", "outOfOffice"] This value will be the default. If you're enrolled in the Working Location developer preview program, in addition to the default value above you can also set the "workingLocation" event type: - ["default", "focusTime", "outOfOffice", "workingLocation"] - ["workingLocation"] Additional combinations of these 4 event types will be made available in later releases. Developer Preview.
  --i-cal-uid: string # Specifies an event ID in the iCalendar format to be provided in the response. Optional. Use this if you want to search for an event by its iCalendar ID.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. The number of events in the resulting page may be less than this value, or none at all, even if there are more events matching the query. Incomplete pages can be detected by a non-empty nextPageToken field in the response. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --order-by: string@order-by-completer # The order of the events returned in the result. Optional. The default is an unspecified, stable order.
  --page-token: string # Token specifying which result page to return. Optional.
  --private-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only private properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --q: string # Free text search terms to find events that match these terms in the following fields: summary, description, location, attendee's displayName, attendee's email. Optional.
  --shared-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only shared properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events (but not the underlying recurring event) will still be included if showDeleted and singleEvents are both False. If showDeleted and singleEvents are both True, only single instances of deleted events (but not the underlying recurring events) are returned. Optional. The default is False.
  --show-hidden-invitations: oneof<nothing, bool> # Whether to include hidden invitations in the result. Optional. The default is False.
  --single-events: oneof<nothing, bool> # Whether to expand recurring events into instances and only return single one-off events and instances of recurring events, but not the underlying recurring events themselves. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All events deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. There are several query parameters that cannot be specified together with nextSyncToken to ensure consistency of the client state. These are: - iCalUID - orderBy - privateExtendedProperty - q - sharedExtendedProperty - timeMin - timeMax - updatedMin If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMin is set, timeMax must be greater than timeMin.
  --time-min: string # Lower bound (exclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMax is set, timeMin must be smaller than timeMax.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
  --updated-min: string # Lower bound for an event's last modification time (as a RFC3339 timestamp) to filter by. When specified, entries deleted since this time will always be included regardless of showDeleted. Optional. The default is not to filter by last modification time.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendars/{calendarId}/events/watch"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: eventTypes, var: event_types, style: multi}, {name: iCalUID, var: i_cal_uid}, {name: maxAttendees, var: max_attendees}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: privateExtendedProperty, var: private_extended_property, style: multi}, {name: q, var: q}, {name: sharedExtendedProperty, var: shared_extended_property, style: multi}, {name: showDeleted, var: show_deleted}, {name: showHiddenInvitations, var: show_hidden_invitations}, {name: singleEvents, var: single_events}, {name: syncToken, var: sync_token}, {name: timeMax, var: time_max}, {name: timeMin, var: time_min}, {name: timeZone, var: time_zone}, {name: updatedMin, var: updated_min}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, event_types: $event_types, i_cal_uid: $i_cal_uid, max_attendees: $max_attendees, max_results: $max_results, order_by: $order_by, page_token: $page_token, private_extended_property: $private_extended_property, q: $q, shared_extended_property: $shared_extended_property, show_deleted: $show_deleted, show_hidden_invitations: $show_hidden_invitations, single_events: $single_events, sync_token: $sync_token, time_max: $time_max, time_min: $time_min, time_zone: $time_zone, updated_min: $updated_min, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an event.
#
# DELETE /calendars/{calendarId}/events/{eventId}
# operationId: calendar.events.delete
export def "calendar-events-delete" [
  calendar_id: string
  event_id: string
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
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the deletion of the event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the deletion of the event.
]: nothing -> any {
  http-request {
    method: delete
    path: "/calendars/{calendarId}/events/{eventId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, send_notifications: $send_notifications, send_updates: $send_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an event based on its Google Calendar ID. To retrieve an event using its iCalendar ID, call the events.list method using the iCalUID parameter.
#
# GET /calendars/{calendarId}/events/{eventId}
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.get
export def "calendar-events-get" [
  calendar_id: string
  event_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calendars/{calendarId}/events/{eventId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: maxAttendees, var: max_attendees}, {name: timeZone, var: time_zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, max_attendees: $max_attendees, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an event. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}/events/{eventId}
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.patch
export def "calendar-events-patch" [
  calendar_id: string
  event_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the event update (for example, description changes, etc.). Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the event update (for example, title changes, etc.).
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/calendars/{calendarId}/events/{eventId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: conferenceDataVersion, var: conference_data_version}, {name: maxAttendees, var: max_attendees}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}, {name: supportsAttachments, var: supports_attachments}]
    body: {content_type: "application/json", kind: json, fields: [{name: anyoneCanAddSelf, var: anyone_can_add_self}, {name: attachments, var: attachments}, {name: attendees, var: attendees}, {name: attendeesOmitted, var: attendees_omitted}, {name: colorId, var: color_id}, {name: conferenceData, var: conference_data}, {name: created, var: created}, {name: creator, var: creator}, {name: description, var: description}, {name: end, var: end}, {name: endTimeUnspecified, var: end_time_unspecified}, {name: etag, var: etag}, {name: eventType, var: event_type}, {name: extendedProperties, var: extended_properties}, {name: gadget, var: gadget}, {name: guestsCanInviteOthers, var: guests_can_invite_others}, {name: guestsCanModify, var: guests_can_modify}, {name: guestsCanSeeOtherGuests, var: guests_can_see_other_guests}, {name: hangoutLink, var: hangout_link}, {name: htmlLink, var: html_link}, {name: iCalUID, var: i_cal_uid}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: locked, var: locked}, {name: organizer, var: organizer}, {name: originalStartTime, var: original_start_time}, {name: privateCopy, var: private_copy}, {name: recurrence, var: recurrence}, {name: recurringEventId, var: recurring_event_id}, {name: reminders, var: reminders}, {name: sequence, var: sequence}, {name: source, var: source}, {name: start, var: start}, {name: status, var: status}, {name: summary, var: summary}, {name: transparency, var: transparency}, {name: updated, var: updated}, {name: visibility, var: visibility}, {name: workingLocationProperties, var: working_location_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, conference_data_version: $conference_data_version, max_attendees: $max_attendees, send_notifications: $send_notifications, send_updates: $send_updates, supports_attachments: $supports_attachments, anyone_can_add_self: $anyone_can_add_self, attachments: $attachments, attendees: $attendees, attendees_omitted: $attendees_omitted, color_id: $color_id, conference_data: $conference_data, created: $created, creator: $creator, description: $description, end: $end, end_time_unspecified: $end_time_unspecified, etag: $etag, event_type: $event_type, extended_properties: $extended_properties, gadget: $gadget, guests_can_invite_others: $guests_can_invite_others, guests_can_modify: $guests_can_modify, guests_can_see_other_guests: $guests_can_see_other_guests, hangout_link: $hangout_link, html_link: $html_link, i_cal_uid: $i_cal_uid, id: $id, kind: $kind, location: $location, locked: $locked, organizer: $organizer, original_start_time: $original_start_time, private_copy: $private_copy, recurrence: $recurrence, recurring_event_id: $recurring_event_id, reminders: $reminders, sequence: $sequence, source: $source, start: $start, status: $status, summary: $summary, transparency: $transparency, updated: $updated, visibility: $visibility, working_location_properties: $working_location_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an event.
#
# PUT /calendars/{calendarId}/events/{eventId}
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.update
export def "calendar-events-update" [
  calendar_id: string
  event_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the event update (for example, description changes, etc.). Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the event update (for example, title changes, etc.).
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/calendars/{calendarId}/events/{eventId}"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: conferenceDataVersion, var: conference_data_version}, {name: maxAttendees, var: max_attendees}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}, {name: supportsAttachments, var: supports_attachments}]
    body: {content_type: "application/json", kind: json, fields: [{name: anyoneCanAddSelf, var: anyone_can_add_self}, {name: attachments, var: attachments}, {name: attendees, var: attendees}, {name: attendeesOmitted, var: attendees_omitted}, {name: colorId, var: color_id}, {name: conferenceData, var: conference_data}, {name: created, var: created}, {name: creator, var: creator}, {name: description, var: description}, {name: end, var: end}, {name: endTimeUnspecified, var: end_time_unspecified}, {name: etag, var: etag}, {name: eventType, var: event_type}, {name: extendedProperties, var: extended_properties}, {name: gadget, var: gadget}, {name: guestsCanInviteOthers, var: guests_can_invite_others}, {name: guestsCanModify, var: guests_can_modify}, {name: guestsCanSeeOtherGuests, var: guests_can_see_other_guests}, {name: hangoutLink, var: hangout_link}, {name: htmlLink, var: html_link}, {name: iCalUID, var: i_cal_uid}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: locked, var: locked}, {name: organizer, var: organizer}, {name: originalStartTime, var: original_start_time}, {name: privateCopy, var: private_copy}, {name: recurrence, var: recurrence}, {name: recurringEventId, var: recurring_event_id}, {name: reminders, var: reminders}, {name: sequence, var: sequence}, {name: source, var: source}, {name: start, var: start}, {name: status, var: status}, {name: summary, var: summary}, {name: transparency, var: transparency}, {name: updated, var: updated}, {name: visibility, var: visibility}, {name: workingLocationProperties, var: working_location_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, conference_data_version: $conference_data_version, max_attendees: $max_attendees, send_notifications: $send_notifications, send_updates: $send_updates, supports_attachments: $supports_attachments, anyone_can_add_self: $anyone_can_add_self, attachments: $attachments, attendees: $attendees, attendees_omitted: $attendees_omitted, color_id: $color_id, conference_data: $conference_data, created: $created, creator: $creator, description: $description, end: $end, end_time_unspecified: $end_time_unspecified, etag: $etag, event_type: $event_type, extended_properties: $extended_properties, gadget: $gadget, guests_can_invite_others: $guests_can_invite_others, guests_can_modify: $guests_can_modify, guests_can_see_other_guests: $guests_can_see_other_guests, hangout_link: $hangout_link, html_link: $html_link, i_cal_uid: $i_cal_uid, id: $id, kind: $kind, location: $location, locked: $locked, organizer: $organizer, original_start_time: $original_start_time, private_copy: $private_copy, recurrence: $recurrence, recurring_event_id: $recurring_event_id, reminders: $reminders, sequence: $sequence, source: $source, start: $start, status: $status, summary: $summary, transparency: $transparency, updated: $updated, visibility: $visibility, working_location_properties: $working_location_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns instances of the specified recurring event.
#
# GET /calendars/{calendarId}/events/{eventId}/instances
# Returns: record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string>
# operationId: calendar.events.instances
export def "calendar-events-instances" [
  calendar_id: string
  event_id: string
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
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --original-start: string # The original start time of the instance in the result. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events will still be included if singleEvents is False. Optional. The default is False.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset.
  --time-min: string # Lower bound (inclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calendars/{calendarId}/events/{eventId}/instances"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: alwaysIncludeEmail, var: always_include_email}, {name: maxAttendees, var: max_attendees}, {name: maxResults, var: max_results}, {name: originalStart, var: original_start}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: timeMax, var: time_max}, {name: timeMin, var: time_min}, {name: timeZone, var: time_zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, always_include_email: $always_include_email, max_attendees: $max_attendees, max_results: $max_results, original_start: $original_start, page_token: $page_token, show_deleted: $show_deleted, time_max: $time_max, time_min: $time_min, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves an event to another calendar, i.e. changes an event's organizer.
#
# POST /calendars/{calendarId}/events/{eventId}/move
# Returns: record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>>
# operationId: calendar.events.move
export def "calendar-events-move" [
  calendar_id: string
  event_id: string
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
  --destination: string # Calendar identifier of the target calendar where the event is to be moved to. (required)
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the change of the event's organizer. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the change of the event's organizer.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/calendars/{calendarId}/events/{eventId}/move"
    path_params: [{name: calendarId, var: calendar_id}, {name: eventId, var: event_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: destination, var: destination, required: true}, {name: sendNotifications, var: send_notifications}, {name: sendUpdates, var: send_updates}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, event_id: $event_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, destination: $destination, send_notifications: $send_notifications, send_updates: $send_updates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: calendar.channels.stop
export def "calendar-channels-stop" [
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
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> any {
  $in | http-request {
    method: post
    path: "/channels/stop"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the color definitions for calendars and events.
#
# GET /colors
# Returns: record<calendar: record, event: record, kind: string, updated: string>
# operationId: calendar.colors.get
export def "calendar-colors-get" [
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
    path: "/colors"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns free/busy information for a set of calendars.
#
# POST /freeBusy
# Returns: record<calendars: record, groups: record, kind: string, timeMax: string, timeMin: string>
# operationId: calendar.freebusy.query
export def "calendar-freebusy-query" [
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
  --calendar-expansion-max: int # Maximal number of calendars for which FreeBusy information is to be provided. Optional. Maximum value is 50. (format: int32)
  --group-expansion-max: int # Maximal number of calendar identifiers to be provided for a single group. Optional. An error is returned for a group with more members than this value. Maximum value is 100. (format: int32)
  --items: list # List of calendars and/or groups to query. — item shape: {id?: string}
  --time-max: string # The end of the interval for the query formatted as per RFC3339. (format: date-time)
  --time-min: string # The start of the interval for the query formatted as per RFC3339. (format: date-time)
  --time-zone: string # Time zone used in the response. Optional. The default is UTC. (default: UTC)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/freeBusy"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: calendarExpansionMax, var: calendar_expansion_max}, {name: groupExpansionMax, var: group_expansion_max}, {name: items, var: items}, {name: timeMax, var: time_max}, {name: timeMin, var: time_min}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, calendar_expansion_max: $calendar_expansion_max, group_expansion_max: $group_expansion_max, items: $items, time_max: $time_max, time_min: $time_min, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the calendars on the user's calendar list.
#
# GET /users/me/calendarList
# Returns: record<etag: string, items: table<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record, defaultReminders: list, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>, kind: string, nextPageToken: string, nextSyncToken: string>
# operationId: calendar.calendarList.list
export def "calendar-calendar-list-list" [
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --min-access-role: string@min-access-role-completer # The minimum access role for the user in the returned entries. Optional. The default is no restriction.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted calendar list entries in the result. Optional. The default is False.
  --show-hidden: oneof<nothing, bool> # Whether to show hidden entries. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If only read-only fields such as calendar properties or ACLs have changed, the entry won't be returned. All entries deleted and hidden since the previous list request will always be in the result set and it is not allowed to set showDeleted neither showHidden to False. To ensure client state consistency minAccessRole query parameter cannot be specified together with nextSyncToken. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/calendarList"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: minAccessRole, var: min_access_role}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: showHidden, var: show_hidden}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, min_access_role: $min_access_role, page_token: $page_token, show_deleted: $show_deleted, show_hidden: $show_hidden, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts an existing calendar into the user's calendar list.
#
# POST /users/me/calendarList
# Returns: record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>
# operationId: calendar.calendarList.insert
export def "calendar-calendar-list-insert" [
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
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/me/calendarList"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: colorRgbFormat, var: color_rgb_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessRole, var: access_role}, {name: backgroundColor, var: background_color}, {name: colorId, var: color_id}, {name: conferenceProperties, var: conference_properties}, {name: defaultReminders, var: default_reminders}, {name: deleted, var: deleted}, {name: description, var: description}, {name: etag, var: etag}, {name: foregroundColor, var: foreground_color}, {name: hidden, var: hidden}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: notificationSettings, var: notification_settings}, {name: primary, var: primary}, {name: selected, var: selected}, {name: summary, var: summary}, {name: summaryOverride, var: summary_override}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, color_rgb_format: $color_rgb_format, access_role: $access_role, background_color: $background_color, color_id: $color_id, conference_properties: $conference_properties, default_reminders: $default_reminders, deleted: $deleted, description: $description, etag: $etag, foreground_color: $foreground_color, hidden: $hidden, id: $id, kind: $kind, location: $location, notification_settings: $notification_settings, primary: $primary, selected: $selected, summary: $summary, summary_override: $summary_override, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch for changes to CalendarList resources.
#
# POST /users/me/calendarList/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: calendar.calendarList.watch
export def "calendar-calendar-list-watch" [
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --min-access-role: string@min-access-role-completer # The minimum access role for the user in the returned entries. Optional. The default is no restriction.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted calendar list entries in the result. Optional. The default is False.
  --show-hidden: oneof<nothing, bool> # Whether to show hidden entries. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If only read-only fields such as calendar properties or ACLs have changed, the entry won't be returned. All entries deleted and hidden since the previous list request will always be in the result set and it is not allowed to set showDeleted neither showHidden to False. To ensure client state consistency minAccessRole query parameter cannot be specified together with nextSyncToken. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/me/calendarList/watch"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: minAccessRole, var: min_access_role}, {name: pageToken, var: page_token}, {name: showDeleted, var: show_deleted}, {name: showHidden, var: show_hidden}, {name: syncToken, var: sync_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, min_access_role: $min_access_role, page_token: $page_token, show_deleted: $show_deleted, show_hidden: $show_hidden, sync_token: $sync_token, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a calendar from the user's calendar list.
#
# DELETE /users/me/calendarList/{calendarId}
# operationId: calendar.calendarList.delete
export def "calendar-calendar-list-delete" [
  calendar_id: string
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
    path: "/users/me/calendarList/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a calendar from the user's calendar list.
#
# GET /users/me/calendarList/{calendarId}
# Returns: record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>
# operationId: calendar.calendarList.get
export def "calendar-calendar-list-get" [
  calendar_id: string
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
    path: "/users/me/calendarList/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing calendar on the user's calendar list. This method supports patch semantics.
#
# PATCH /users/me/calendarList/{calendarId}
# Returns: record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>
# operationId: calendar.calendarList.patch
export def "calendar-calendar-list-patch" [
  calendar_id: string
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
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/me/calendarList/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: colorRgbFormat, var: color_rgb_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessRole, var: access_role}, {name: backgroundColor, var: background_color}, {name: colorId, var: color_id}, {name: conferenceProperties, var: conference_properties}, {name: defaultReminders, var: default_reminders}, {name: deleted, var: deleted}, {name: description, var: description}, {name: etag, var: etag}, {name: foregroundColor, var: foreground_color}, {name: hidden, var: hidden}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: notificationSettings, var: notification_settings}, {name: primary, var: primary}, {name: selected, var: selected}, {name: summary, var: summary}, {name: summaryOverride, var: summary_override}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, color_rgb_format: $color_rgb_format, access_role: $access_role, background_color: $background_color, color_id: $color_id, conference_properties: $conference_properties, default_reminders: $default_reminders, deleted: $deleted, description: $description, etag: $etag, foreground_color: $foreground_color, hidden: $hidden, id: $id, kind: $kind, location: $location, notification_settings: $notification_settings, primary: $primary, selected: $selected, summary: $summary, summary_override: $summary_override, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing calendar on the user's calendar list.
#
# PUT /users/me/calendarList/{calendarId}
# Returns: record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>
# operationId: calendar.calendarList.update
export def "calendar-calendar-list-update" [
  calendar_id: string
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
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/me/calendarList/{calendarId}"
    path_params: [{name: calendarId, var: calendar_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: colorRgbFormat, var: color_rgb_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessRole, var: access_role}, {name: backgroundColor, var: background_color}, {name: colorId, var: color_id}, {name: conferenceProperties, var: conference_properties}, {name: defaultReminders, var: default_reminders}, {name: deleted, var: deleted}, {name: description, var: description}, {name: etag, var: etag}, {name: foregroundColor, var: foreground_color}, {name: hidden, var: hidden}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: notificationSettings, var: notification_settings}, {name: primary, var: primary}, {name: selected, var: selected}, {name: summary, var: summary}, {name: summaryOverride, var: summary_override}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    calendar_id: $calendar_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, color_rgb_format: $color_rgb_format, access_role: $access_role, background_color: $background_color, color_id: $color_id, conference_properties: $conference_properties, default_reminders: $default_reminders, deleted: $deleted, description: $description, etag: $etag, foreground_color: $foreground_color, hidden: $hidden, id: $id, kind: $kind, location: $location, notification_settings: $notification_settings, primary: $primary, selected: $selected, summary: $summary, summary_override: $summary_override, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all user settings for the authenticated user.
#
# GET /users/me/settings
# Returns: record<etag: string, items: table<etag: string, id: string, kind: string, value: string>, kind: string, nextPageToken: string, nextSyncToken: string>
# operationId: calendar.settings.list
export def "calendar-settings-list" [
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/settings"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch for changes to Settings resources.
#
# POST /users/me/settings/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: calendar.settings.watch
export def "calendar-settings-watch" [
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
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/me/settings/watch"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: syncToken, var: sync_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, sync_token: $sync_token, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single user setting.
#
# GET /users/me/settings/{setting}
# Returns: record<etag: string, id: string, kind: string, value: string>
# operationId: calendar.settings.get
export def "calendar-settings-get" [
  setting: string
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
    path: "/users/me/settings/{setting}"
    path_params: [{name: setting, var: setting}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    setting: $setting, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
