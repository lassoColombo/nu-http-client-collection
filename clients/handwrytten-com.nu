# Auto-generated client for Handwrytten API v1.0.0
# Source: https://api.apis.guru/v2/specs/handwrytten.com/1.0.0/swagger.json
# Auth: --token flag or $env.HANDWRYTTEN_API_TOKEN

const CLIENT = {
  base_url: "https://api.handwrytten.com/v1"
  token_env_var: "HANDWRYTTEN_API_TOKEN"
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

def base-url-completer [] { ["https://api.handwrytten.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    login: "record<anet_customer_id: string, free_cards: int, status: string, uid: string, user_id: int>"
    change-password: "record<status: string>"
    logout: "record<status: string>"
    register: "record<status: string, user_id: int>"
    reset-password-request: "record<status: string>"
    create-custom-card: "record"
    simple-list-cards: "record"
    list-cards: "table<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float>"
    upload-custom-logo: "record<id: int, status: string>"
    filterable-card-details: "record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, images: table<array: list, name: string>, name: string, orientation: string, price: float>"
    get-countries-list: "table<aliases: string, delivery_cost: float, id: int, states: list<record>>"
    fonts-list: "table<id: string, image: string, label: string>"
    fonts-list-for-customizer: "table<id: int, label: string>"
    get-gift-card-details: "table<denominations: list<record>, id: int, image: string, name: string>"
    gift-card-details: "table<denominations: list<record>, id: int, image: string, name: string>"
    single-step-order: "record<response: record<address_from: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, card: record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float>, date_created: string, for_free: bool, id: int, message: string>, status: string>"
    user-address: "record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>"
    delete-recipient: "record<status: string>"
    add-recipient-address: "record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>"
    recipients-list: "table<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>"
    update-user-address: "record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>"
    update-recipient: "record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>"
    get-template-categories: "table<id: int, name: string, price: float>"
    get-template-categories-authorized: "table<id: int, name: string, price: float>"
    create-template: "table<category_id: int, id: int, message: string, name: string>"
    delete-template: "record<status: string>"
    get-templates: "table<category_id: int, id: int, message: string, name: string>"
    get-templatess-authorized: "table<category_id: int, id: int, message: string, name: string>"
    update-template: "table<category_id: int, id: int, message: string, name: string>"
    get-template-detail: "record<category_id: int, id: int, message: string, name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["login" "change-password" "logout" "register" "reset-password-request" "create-custom-card" "simple-list-cards" "list-cards" "upload-custom-logo" "filterable-card-details" "get-countries-list" "fonts-list" "fonts-list-for-customizer" "get-gift-card-details" "gift-card-details" "single-step-order" "user-address" "delete-recipient" "add-recipient-address" "recipients-list" "update-user-address" "update-recipient" "get-template-categories" "get-template-categories-authorized" "create-template" "delete-template" "get-templates" "get-templatess-authorized" "update-template" "get-template-detail" "commands"] | sort) } | get name | first)
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

# Logs in to an existing account
#
# POST /auth/authorization
# Returns: record<anet_customer_id: string, free_cards: int, status: string, uid: string, user_id: int>
# operationId: login
export def "login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string # email address (e.g. john@jjf.com)
  password: string # e.g. 8yfqwiuy@!$
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/authorization"
    body: {content_type: "application/json", kind: json, fields: [{name: login, var: login}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# changes a user's password
#
# POST /auth/changePassword
# Returns: record<status: string>
# operationId: changePassword
export def "change-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # the new password (e.g. myn3wp455w0rd!)
  --old-password: string # the existing password (e.g. myoldpassword1234!)
  --uid: string # the authorized UID of the session (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/changePassword"
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: old_password, var: old_password}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    new_password: $new_password, old_password: $old_password, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# logs out a session uid
#
# POST /auth/logout
# Returns: record<status: string>
# operationId: logout
export def "logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # the authorized UID of the session (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/logout"
    body: {content_type: "application/json", kind: json, fields: [{name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a new account
#
# POST /auth/register
# Returns: record<status: string, user_id: int>
# operationId: register
export def "register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --discount-code: string # optional discount code
  fname: string # first name (e.g. John)
  lname: string # last name (e.g. Smith)
  login: string # email address (e.g. john@jjf.com)
  password: string # e.g. 8yfqwiuy@!$
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/register"
    body: {content_type: "application/json", kind: json, fields: [{name: discount_code, var: discount_code}, {name: fname, var: fname}, {name: lname, var: lname}, {name: login, var: login}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    discount_code: $discount_code, fname: $fname, lname: $lname, login: $login, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# resets a user's password
#
# POST /auth/resetPasswordRequest
# Returns: record<status: string>
# operationId: resetPasswordRequest
export def "reset-password-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # the email address of the user (e.g. joe@bloggs.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/resetPasswordRequest"
    body: {content_type: "application/json", kind: json, fields: [{name: login, var: login}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new custom card
#
# POST /cards/createCustomCard
# Returns: record
# operationId: CreateCustomCard
export def "create-custom-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: int # the card id of the card template you're starting with. You can find this by logging into Handwrytten, clicking "customize" next to any customizable card, and pulling the card ID from the end of the URL (e.g. 243)
  --cover-id: int # the id of the image you want to use for the "cover". The cover is the large image on the front of the flat card. (e.g. 42)
  --cover-size-percent: int # the size of the image to use as the cover. (e.g. 100)
  --footer-align: string # set to "left", "center", or "right" to align the footer appropriately (e.g. center)
  --footer-font-id: int # font ID of the text in the footer, found by using ListFontForCustomizer (e.g. 1)
  --footer-font-size: int # Font size of the text in the footer (e.g. 16)
  --footer-text: string # optional text for the footer of the customizable card (e.g. Sample text for the footer)
  --header-align: string # set to "left", "center", or "right" to align the header appropriately (e.g. center)
  --header-auto-size: oneof<nothing, bool> # if set to true, the header will be maximized to fill the header area
  --header-font-id: int # font ID of the text in the header, found by using ListFontForCustomizer (e.g. 8)
  --header-font-size: int # font size of the text in the header of the card (e.g. 20)
  --header-text: string # text in the header, if type is set to "text" (e.g. Sample text for the header)
  --logo-id: int # Optional. If setting "type" to "logo", set the id of the logo here. (e.g. 20)
  --logo-size-percent: int # set to the desired scaling of the logo on the header (e.g. 100)
  --name: string # the name of the new card (e.g. my custom card design)
  --type: string # Defines the top of the back of the card. Set to either "logo" or "text". (e.g. logo)
  --uid: string # authorized UID of the session. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cards/createCustomCard"
    body: {content_type: "application/json", kind: json, fields: [{name: card_id, var: card_id}, {name: cover_id, var: cover_id}, {name: cover_size_percent, var: cover_size_percent}, {name: footer_align, var: footer_align}, {name: footer_font_id, var: footer_font_id}, {name: footer_font_size, var: footer_font_size}, {name: footer_text, var: footer_text}, {name: header_align, var: header_align}, {name: header_auto_size, var: header_auto_size}, {name: header_font_id, var: header_font_id}, {name: header_font_size, var: header_font_size}, {name: header_text, var: header_text}, {name: logo_id, var: logo_id}, {name: logo_size_percent, var: logo_size_percent}, {name: name, var: name}, {name: type, var: type}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, cover_id: $cover_id, cover_size_percent: $cover_size_percent, footer_align: $footer_align, footer_font_id: $footer_font_id, footer_font_size: $footer_font_size, footer_text: $footer_text, header_align: $header_align, header_auto_size: $header_auto_size, header_font_id: $header_font_id, header_font_size: $header_font_size, header_text: $header_text, logo_id: $logo_id, logo_size_percent: $logo_size_percent, name: $name, type: $type, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information on cards
#
# GET /cards/list
# Returns: record
# operationId: simpleListCards
export def "simple-list-cards" [
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
    path: "/cards/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information on cards
#
# POST /cards/list
# Returns: table<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float>
# operationId: listCards
export def "list-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # optional category id filter (e.g. 14)
  --uid: string # optional authorized UID of the session. By providing this, the card list will include user-specific cards. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cards/list"
    body: {content_type: "application/json", kind: json, fields: [{name: category_id, var: category_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# upload logo or cover image for card
#
# POST /cards/uploadCustomLogo
# Returns: record<id: int, status: string>
# operationId: uploadCustomLogo
export def "upload-custom-logo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: path # upload images for customc cards
  type: string # set to cover or header
  uid: string # uid of the user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cards/uploadCustomLogo"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: type, var: type}, {name: uid, var: uid}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file: $file, type: $type, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides full information on a specific card
#
# POST /cards/view
# Returns: record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, images: table<array: list, name: string>, name: string, orientation: string, price: float>
# operationId: filterableCardDetails
export def "filterable-card-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-id: int # the card id to view (e.g. 14)
  --uid: string # optional authorized UID of the session. By providing this, the card details can provide user-specific cards (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cards/view"
    body: {content_type: "application/json", kind: json, fields: [{name: card_id, var: card_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the countries to which Handwritten can mail, their associated country ID and any costs
#
# GET /countries/list
# Returns: table<aliases: string, delivery_cost: float, id: int, states: list<record>>
export def "get-countries-list" [
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
    path: "/countries/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Handwryting styles available for use
#
# GET /fonts/list
# Returns: table<id: string, image: string, label: string>
# operationId: fontsList
export def "fonts-list" [
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
    path: "/fonts/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists fonts available for use with the card customizer
#
# GET /fonts/listForCustomizer
# Returns: table<id: int, label: string>
# operationId: fontsListForCustomizer
export def "fonts-list-for-customizer" [
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
    path: "/fonts/listForCustomizer"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information on gift cards
#
# GET /giftCards/view
# Returns: table<denominations: list<record>, id: int, image: string, name: string>
# operationId: getGiftCardDetails
export def "get-gift-card-details" [
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
    path: "/giftCards/view"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information on gift cards
#
# POST /giftCards/view
# Returns: table<denominations: list<record>, id: int, image: string, name: string>
# operationId: giftCardDetails
export def "gift-card-details" [
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
    method: post
    path: "/giftCards/view"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sends an order in a single step. This is much easier than using other order commands
#
# POST /orders/singleStepOrder
# Returns: record<response: record<address_from: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, card: record<available_free: int, category_id: int, cover: string, cover_height: string, cover_width: string, id: int, name: string, price: float>, date_created: string, for_free: bool, id: int, message: string>, status: string>
# operationId: singleStepOrder
export def "single-step-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: int # the id of the card you want to send (e.g. 3404)
  --credit-card-id: int # the credit card id to charge for the order. Currently this is required, even for invoiced accounts, it just won't be charged. (e.g. 34124)
  --denomination-id: int # Optional. Use if sending a gift card (e.g. 12)
  --font-label: string # the colloquial name of the font, such as 'Fancy Jenna' or 'Casual David' (e.g. Chill Charity)
  message: string # the full message body. Use '\n' for new lines (e.g. Dear Frank, Thank you so much for your interest in our services. Yours, Joe)
  --recipient-address1: string # the first address line of the return address (e.g. 123 E Main Street)
  --recipient-address2: string # the second line of the address, such as suite, apartment, building, etc. Optional (e.g. Second Floor)
  --recipient-business-name: string # the second line of the recipient address. Optional. (e.g. Spacely Space Sprockets)
  --recipient-city: string # the city of the recipient, to appear in the address (e.g. Burlington)
  --recipient-country: string # the country of the recipient. Optional and defaults to usa (e.g. Canada)
  --recipient-country-id: int # alternate way to specify country. Optional and defaults to 1 (e.g. 2)
  --recipient-name: string # the name on the recipient address (e.g. Cosmo Spacely)
  --recipient-state: string # the ABBREVIATED state or province of the recipient. This is required for US and Canada addresses and optional for all other countries (e.g. ON)
  --recipient-zip: string # the zip code or postal code of the recipient (e.g. L7L 0E9)
  --sender-address1: string # the first address line of the return address (e.g. 1430 E Indian School Road)
  --sender-address2: string # the second line of the address, such as suite, apartment, building, etc. Optional (e.g. Suite 100)
  --sender-business-name: string # the second line of the return address. Optional. (e.g. Handwrytten)
  --sender-city: string # the city of the sender, to appear in the return address (e.g. Phoenix)
  --sender-country: string # the country of the recipient. Optional and defaults to usa (e.g. United States)
  --sender-country-id: int # alternate way to specify country. Optional and defaults to 1 (e.g. 1)
  --sender-name: string # the name on the return address (e.g. Joe Sender)
  --sender-state: string # the ABBREVIATED state or province of the sender. This is required for US and Canada addresses and optional for all other countries (e.g. AZ)
  --sender-zip: string # The postal code or zip code of the sender. (e.g. 12345)
  uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/singleStepOrder"
    body: {content_type: "application/json", kind: json, fields: [{name: card_id, var: card_id}, {name: credit_card_id, var: credit_card_id}, {name: denomination_id, var: denomination_id}, {name: font_label, var: font_label}, {name: message, var: message}, {name: recipient_address1, var: recipient_address1}, {name: recipient_address2, var: recipient_address2}, {name: recipient_business_name, var: recipient_business_name}, {name: recipient_city, var: recipient_city}, {name: recipient_country, var: recipient_country}, {name: recipient_country_id, var: recipient_country_id}, {name: recipient_name, var: recipient_name}, {name: recipient_state, var: recipient_state}, {name: recipient_zip, var: recipient_zip}, {name: sender_address1, var: sender_address1}, {name: sender_address2, var: sender_address2}, {name: sender_business_name, var: sender_business_name}, {name: sender_city, var: sender_city}, {name: sender_country, var: sender_country}, {name: sender_country_id, var: sender_country_id}, {name: sender_name, var: sender_name}, {name: sender_state, var: sender_state}, {name: sender_zip, var: sender_zip}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, credit_card_id: $credit_card_id, denomination_id: $denomination_id, font_label: $font_label, message: $message, recipient_address1: $recipient_address1, recipient_address2: $recipient_address2, recipient_business_name: $recipient_business_name, recipient_city: $recipient_city, recipient_country: $recipient_country, recipient_country_id: $recipient_country_id, recipient_name: $recipient_name, recipient_state: $recipient_state, recipient_zip: $recipient_zip, sender_address1: $sender_address1, sender_address2: $sender_address2, sender_business_name: $sender_business_name, sender_city: $sender_city, sender_country: $sender_country, sender_country_id: $sender_country_id, sender_name: $sender_name, sender_state: $sender_state, sender_zip: $sender_zip, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# gets the user's return address information
#
# POST /profile/address
# Returns: record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>
# operationId: userAddress
export def "user-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # authorized UID of the session. By providing this, the card list will include user-specific cards. (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/address"
    body: {content_type: "application/json", kind: json, fields: [{name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes an existing recipient address
#
# POST /profile/deleteRecipient
# Returns: record<status: string>
# operationId: deleteRecipient
export def "delete-recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: int # the id of the address to delete (e.g. 549494)
  uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/deleteRecipient"
    body: {content_type: "application/json", kind: json, fields: [{name: address_id, var: address_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address_id: $address_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add a new recipient address
#
# POST /profile/profileAddRecipient
# Returns: record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>
# operationId: addRecipientAddress
export def "add-recipient-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the second (optional) line of the address (e.g. Suite 100)
  --business-name: string # the optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the city of the address (e.g. Phoenix)
  --country: string # the name of the country of the address, or use country_id (e.g. United States)
  --country-id: int # the country id code of the recipient
  --name: string # the name on the address (e.g. Joe Smith)
  --state: string # the abbreviated state or province of the address (e.g. AZ)
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the zip or postal code of the address (e.g. 85014)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/profileAddRecipient"
    body: {content_type: "application/json", kind: json, fields: [{name: address1, var: address1}, {name: address2, var: address2}, {name: business_name, var: business_name}, {name: city, var: city}, {name: country, var: country}, {name: country_id, var: country_id}, {name: name, var: name}, {name: state, var: state}, {name: uid, var: uid}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address1: $address1, address2: $address2, business_name: $business_name, city: $city, country: $country, country_id: $country_id, name: $name, state: $state, uid: $uid, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list the addresses in the user's account
#
# POST /profile/recipientsList
# Returns: table<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>
# operationId: recipientsList
export def "recipients-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/recipientsList"
    body: {content_type: "application/json", kind: json, fields: [{name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# update the user's return address information
#
# POST /profile/updateAddress
# Returns: record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>
# operationId: updateUserAddress
export def "update-user-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the second (optional) line of the address (e.g. Suite 100)
  address_id: int # the address you are updating (e.g. 42)
  --business-name: string # the optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the city of the address (e.g. Phoenix)
  --country: string # the name of the country of the address (e.g. United States)
  --country-id: int # the id of the country of the address. do not use with "country" parameter (e.g. 2)
  --name: string # the name on the address (e.g. Joe Smith)
  --state: string # the abbreviated state or province of the address (e.g. AZ)
  uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the zip or postal code of the address (e.g. 85014)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/updateAddress"
    body: {content_type: "application/json", kind: json, fields: [{name: address1, var: address1}, {name: address2, var: address2}, {name: address_id, var: address_id}, {name: business_name, var: business_name}, {name: city, var: city}, {name: country, var: country}, {name: country_id, var: country_id}, {name: name, var: name}, {name: state, var: state}, {name: uid, var: uid}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address1: $address1, address2: $address2, address_id: $address_id, business_name: $business_name, city: $city, country: $country, country_id: $country_id, name: $name, state: $state, uid: $uid, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updates an existing new recipient address
#
# POST /profile/updateRecipient
# Returns: record<response: record<address1: string, address2: string, business_name: string, city: string, country: string, id: int, name: string, state: string, zip: string>, status: string>
# operationId: updateRecipient
export def "update-recipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # the updated first line of the address (e.g. 1430 E Indian School Rd)
  --address2: string # the updated second (optional) line of the address (e.g. Suite 100)
  --business-name: string # the updated optional business name on the address (e.g. Handwrytten LLC)
  --city: string # the updated city of the address (e.g. Phoenix)
  --country: string # the updated name of the country of the address, or use country_id (e.g. United States)
  --country-id: int # the country id of the address
  --id: int # the id of the address to update (e.g. 549494)
  --name: string # the updated name on the address (e.g. Joe Smith)
  --state: string # the updated abbreviated state or province of the address (e.g. AZ)
  --uid: string # authorized UID of the session. (e.g. 33ce76fede1a31d5ee823179f78d9882)
  --zip: string # the updated zip or postal code of the address (e.g. 85014)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile/updateRecipient"
    body: {content_type: "application/json", kind: json, fields: [{name: address1, var: address1}, {name: address2, var: address2}, {name: business_name, var: business_name}, {name: city, var: city}, {name: country, var: country}, {name: country_id, var: country_id}, {name: id, var: id}, {name: name, var: name}, {name: state, var: state}, {name: uid, var: uid}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address1: $address1, address2: $address2, business_name: $business_name, city: $city, country: $country, country_id: $country_id, id: $id, name: $name, state: $state, uid: $uid, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List template categories
#
# GET /templateCategories/list
# Returns: table<id: int, name: string, price: float>
# operationId: getTemplateCategories
export def "get-template-categories" [
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
    path: "/templateCategories/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List template categories
#
# POST /templateCategories/list
# Returns: table<id: int, name: string, price: float>
# operationId: getTemplateCategoriesAuthorized
export def "get-template-categories-authorized" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uid: string # optional authorized UID of the session. By providing this, the template list will include user-specific template categories (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templateCategories/list"
    body: {content_type: "application/json", kind: json, fields: [{name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a New Template in the User’s Account
#
# POST /templates/create
# Returns: table<category_id: int, id: int, message: string, name: string>
# operationId: createTemplate
export def "create-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. How do I love thee?  Let me count the ways
  --name: string # the new name of the template (e.g. My custom template)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/create"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: name, var: name}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message: $message, name: $name, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a users template
#
# POST /templates/delete
# Returns: record<status: string>
# operationId: deleteTemplate
export def "delete-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-id: int # the ID of the template to delete (e.g. 12)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: template_id, var: template_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List template categories
#
# GET /templates/list
# Returns: table<category_id: int, id: int, message: string, name: string>
# operationId: getTemplates
export def "get-templates" [
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
    path: "/templates/list"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List template categories
#
# POST /templates/list
# Returns: table<category_id: int, id: int, message: string, name: string>
# operationId: getTemplatessAuthorized
export def "get-templatess-authorized" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # optional category to filter the templates (e.g. 12)
  --uid: string # optional authorized UID of the session. By providing this, the template list will include user-specific template categories (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/list"
    body: {content_type: "application/json", kind: json, fields: [{name: category_id, var: category_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Existing Template in the User’s Account
#
# POST /templates/update
# Returns: table<category_id: int, id: int, message: string, name: string>
# operationId: updateTemplate
export def "update-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # e.g. How do I love thee?  Let me count the ways
  --name: string # the new name of the template (e.g. My custom template)
  --template-id: int # the ID of the template to update (e.g. 12)
  --uid: string # The UID of the logged-in user (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/update"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: name, var: name}, {name: template_id, var: template_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message: $message, name: $name, template_id: $template_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all info on a template
#
# POST /templates/view
# Returns: record<category_id: int, id: int, message: string, name: string>
# operationId: getTemplateDetail
export def "get-template-detail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-id: int # the ID of the template to view (e.g. 12)
  --uid: string # optional authorized UID of the session. By providing this, the user can specify user-sepecific templates (e.g. fhqwfuihuifqwhiuwqfhiqwfh124)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/view"
    body: {content_type: "application/json", kind: json, fields: [{name: template_id, var: template_id}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
