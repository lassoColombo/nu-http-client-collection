# Auto-generated client for Akeneo PIM REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/akeneo.com/1.0.0/swagger.json
# Auth: --token flag or $env.AKENEO_PIM_REST_API_TOKEN

const CLIENT = {
  base_url: "http://demo.akeneo.com"
  token_env_var: "AKENEO_PIM_REST_API_TOKEN"
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

def base-url-completer [] { ["http://demo.akeneo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def media-type-completer [] { ["image" "other" "pdf" "vimeo" "youtube"] }
def type-completer [] { ["boolean" "media_file" "media_link" "multiple_options" "number" "reference_entity_multiple_links" "reference_entity_single_link" "single_option" "text"] }
def validation-rule-completer [] { ["email" "none" "regexp" "url"] }
def pagination-type-completer [] { ["page" "search_after"] }
def type-completer-1 [] { ["akeneo_reference_entity" "akeneo_reference_entity_collection" "pim_catalog_asset_collection" "pim_catalog_boolean" "pim_catalog_date" "pim_catalog_file" "pim_catalog_identifier" "pim_catalog_image" "pim_catalog_metric" "pim_catalog_multiselect" "pim_catalog_number" "pim_catalog_price_collection" "pim_catalog_reference_data_multi_select" "pim_catalog_reference_data_simple_select" "pim_catalog_simpleselect" "pim_catalog_text" "pim_catalog_textarea"] }
def type-completer-2 [] { ["image" "multiple_options" "number" "reference_entity_multiple_links" "reference_entity_single_link" "single_option" "text"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-token: "record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string>"
    get-endpoints: "record<authentication: record, host: string, routes: record>"
    get-asset-categories: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-asset-categories: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-asset-categories-code: "record<code: string, labels: record<localeCode: string>, parent: string>"
    get-asset-families: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>"
    get-assets: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<_items: list<record>>>"
    patch-assets: "table<code: string, message: string, status_code: int>"
    get-assets-code: "record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>>"
    get-asset-families-code-attributes: "table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>"
    get-asset-family-attributes-attribute-code-options: "table<code: string, labels: record<localeCode: string>>"
    get-asset-attributes-attribute-code-options-code: "record<code: string, labels: record<localeCode: string>>"
    get-asset-family-attributes-code: "record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>"
    get-asset-family-code: "record<attribute_as_main_media: string, code: string, labels: record<localeCode: string>, naming_convention: record<abort_asset_creation_on_error: bool, pattern: string, source: record>, product_link_rules: table<assign_assets_to: list, product_selections: list>, transformations: table<filename_prefix: string, filename_suffix: string, label: string, operations: record, source: record, target: record>>"
    get-asset-tags: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    get-asset-tags-code: "record<code: string>"
    get-pam-assets: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-pam-assets: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-reference-files-locale-code: "record<_link: record<download: record<href: string>>, code: string, locale: string>"
    post-reference-files-locale-code: "record<errors: table<channel: string, locale: string, message: string>, message: string>"
    get-variation-files-channel-code-locale-code: "record<_link: record<download: record<href: string>>, code: string, locale: string, scope: string>"
    get-pam-assets-code: "record<categories: list<string>, code: string, description: string, end_of_use: string, localizable: bool, reference_files: table<_link: record, code: string, locale: string>, tags: list<string>, variation_files: table<_link: record, code: string, locale: string, scope: string>>"
    association-types-get-list: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    several-association-types-patch: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    association-types-get: "record<code: string, is_quantified: bool, is_two_way: bool, labels: record<localeCode: string>>"
    attribute-groups-get-list: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    several-attribute-groups-patch: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    attribute-groups-get: "record<attributes: list<string>, code: string, labels: record<localeCode: string>, sort_order: int>"
    get-attributes: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-attributes: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-attributes-attribute-code-options: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-attributes-attribute-code-options: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-attributes-attribute-code-options-code: "record<attribute: string, code: string, labels: record<localeCode: string>, sort_order: int>"
    get-attributes-code: "record<allowed_extensions: list<string>, available_locales: list<string>, code: string, date_max: string, date_min: string, decimals_allowed: bool, default_metric_unit: string, default_value: bool, group: string, group_labels: record<localeCode: string>, labels: record<localeCode: string>, localizable: bool, max_characters: int, max_file_size: string, metric_family: string, negative_allowed: bool, number_max: string, number_min: string, reference_data_name: string, scopable: bool, sort_order: int, table_configuration: table<code: string, data_type: string, is_required_for_completeness: bool, labels: record, validations: record>, type: string, unique: bool, useable_as_grid_filter: bool, validation_regexp: string, validation_rule: string, wysiwyg_enabled: bool>"
    get-app-catalogs: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    post-app-catalog: "record<enabled: bool, id: string, name: string>"
    get-app-catalog: "record<enabled: bool, id: string, name: string>"
    patch-app-catalog: "record<enabled: bool, id: string, name: string>"
    get-app-catalog-product-uuids: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<string>>>"
    get-app-catalog-products: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<string>>>"
    get-categories: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-categories: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-categories-code: "record<code: string, labels: record<localeCode: string>, parent: string, position: int, updated: string, values: record<\"attributeCode|attributeUuid|channelCode|localeCode\": list<record>>>"
    get-channels: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    several-channels-patch: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-channels-code: "record<category_tree: string, code: string, conversion_units: record<attributeCode: string>, currencies: list<string>, labels: record<localeCode: string>, locales: list<string>>"
    currencies-get-list: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    currencies-get: "record<code: string, enabled: bool>"
    get-families: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-families: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-families-code: "record<attribute_as_image: string, attribute_as_label: string, attribute_requirements: record<channelCode: list<string>>, attributes: list<string>, code: string, labels: record<localeCode: string>>"
    get-families-family-code-variants: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-families-family-code-variants: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-families-family-code-variants-code: "record<code: string, labels: record<localeCode: string>, variant_attribute_sets: table<attributes: list, axes: list, level: int>>"
    get-locales: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    get-locales-code: "record<code: string, enabled: bool>"
    measure-families-get-list: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    measure-families-get: "record<code: string, standard: string, units: table<code: string, convert: record, symbol: string>>"
    measurement-families-get-list: "record<code: string, labels: record<localeCode: string>, standard_unit_code: string, units: record<unitCode: record<code: string, convert_from_standard: list, labels: record, symbol: string>>>"
    patch-measurement-families: "table<code: string, errors: list<record>, message: string, status_code: int>"
    get-media-files: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    get-media-files-code: "record<_links: record<download: record<href: string>>, code: string, extension: string, mime_type: string, original_filename: string, size: int>"
    get-product-models: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-product-models: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-product-models-code: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>>"
    get-product-model-draft-code: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>>"
    get-products: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-products: "record<code: string, identifier: string, line: int, message: string, status_code: int>"
    get-products-uuid: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    patch-products-uuid: "record<line: int, message: string, status_code: int, uuid: string>"
    get-products-uuid-uuid: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>"
    get-draft-uuid-uuid: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>"
    get-products-code: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>"
    get-draft-code: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>"
    get-published-products: "record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>"
    get-published-products-code: "record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, quantified_associations: record, updated: string, values: record<attributeCode: list<record>>>"
    get-reference-entities: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>"
    get-reference-entities-code: "record<_links: record<image_download: record<href: string>>, code: string, image: string, labels: record<localeCode: string>>"
    get-reference-entities-code-attributes: "table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>"
    get-reference-entity-attributes-attribute-code-options: "table<code: string, labels: record<localeCode: string>>"
    get-reference-entity-attributes-attribute-code-options-code: "record<code: string, labels: record<localeCode: string>>"
    get-reference-entity-attributes-code: "record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>"
    get-reference-entity-records: "record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>"
    patch-reference-entity-records: "table<code: string, message: string, status_code: int>"
    get-reference-entity-records-code: "record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>>"
    get-system-information: "record<edition: string, version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-token" "get-endpoints" "get-asset-categories" "patch-asset-categories" "post-asset-categories" "get-asset-categories-code" "patch-asset-categories-code" "get-asset-families" "get-assets" "patch-assets" "delete-assets-code" "get-assets-code" "patch-asset-code" "get-asset-families-code-attributes" "get-asset-family-attributes-attribute-code-options" "get-asset-attributes-attribute-code-options-code" "patch-asset-attributes-attribute-code-options-code" "get-asset-family-attributes-code" "patch-asset-family-attributes-code" "get-asset-family-code" "patch-asset-family-code" "post-asset-media-files" "get-asset-media-files-code" "get-asset-tags" "get-asset-tags-code" "patch-asset-tags-code" "get-pam-assets" "patch-pam-assets" "post-pam-assets" "get-reference-files-locale-code" "post-reference-files-locale-code" "get-reference-files-channel-code-locale-code-download" "get-variation-files-channel-code-locale-code" "post-variation-files-channel-code-locale-code" "get-variation-files-channel-code-locale-code-download" "get-pam-assets-code" "patch-pam-assets-code" "association-types-get-list" "several-association-types-patch" "association-types-post" "association-types-get" "association-types-patch" "attribute-groups-get-list" "several-attribute-groups-patch" "attribute-groups-post" "attribute-groups-get" "attribute-groups-patch" "get-attributes" "patch-attributes" "post-attributes" "get-attributes-attribute-code-options" "patch-attributes-attribute-code-options" "post-attributes-attribute-code-options" "get-attributes-attribute-code-options-code" "patch-attributes-attribute-code-options-code" "get-attributes-code" "patch-attributes-code" "get-app-catalogs" "post-app-catalog" "delete-app-catalog" "get-app-catalog" "patch-app-catalog" "get-app-catalog-product-uuids" "get-app-catalog-products" "get-app-catalog-products-uuid" "get-categories" "patch-categories" "post-categories" "get-categories-code" "patch-categories-code" "get-category-media-files-code-download" "get-channels" "several-channels-patch" "channels-post" "get-channels-code" "channels-patch" "currencies-get-list" "currencies-get" "get-families" "patch-families" "post-families" "get-families-code" "patch-families-code" "get-families-family-code-variants" "patch-families-family-code-variants" "post-families-family-code-variants" "get-families-family-code-variants-code" "patch-families-family-code-variants-code" "get-locales" "get-locales-code" "measure-families-get-list" "measure-families-get" "measurement-families-get-list" "patch-measurement-families" "get-media-files" "post-media-files" "get-media-files-code" "get-media-files-code-download" "get-product-models" "patch-product-models" "post-product-models" "delete-product-models-code" "get-product-models-code" "patch-product-models-code" "get-product-model-draft-code" "post-product-model-proposal" "get-products" "patch-products" "post-products" "get-products-uuid" "patch-products-uuid" "post-products-uuid" "delete-products-uuid-uuid" "get-products-uuid-uuid" "patch-products-uuid-uuid" "get-draft-uuid-uuid" "post-proposal-uuid" "delete-products-code" "get-products-code" "patch-products-code" "get-draft-code" "post-proposal" "get-published-products" "get-published-products-code" "get-reference-entities" "post-reference-entity-media-files" "get-reference-entity-media-files-code" "get-reference-entities-code" "patch-reference-entity-code" "get-reference-entities-code-attributes" "get-reference-entity-attributes-attribute-code-options" "get-reference-entity-attributes-attribute-code-options-code" "patch-reference-entity-attributes-attribute-code-options-code" "get-reference-entity-attributes-code" "patch-reference-entity-attributes-code" "get-reference-entity-records" "patch-reference-entity-records" "get-reference-entity-records-code" "patch-reference-entity-records-code" "get-system-information" "commands"] | sort) } | get name | first)
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

# Get authentication token
#
# POST /api/oauth/v1/token
# Returns: record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string>
# operationId: post_token
export def "post-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'application/json' or 'application/x-www-form-urlencoded', no other value allowed (required)
  --authorization: string # Equal to 'Basic xx', where 'xx' is the base 64 encoding of the client id and secret. Find out how to generate them in the Client ID/secret generation (/documentation/authentication.html#client-idsecret-generation) section. (required)
  grant_type: string # Always equal to "password"
  password: string # Your PIM password
  username: string # Your PIM username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/oauth/v1/token"
    header: [{name: Content-type, var: content_type, required: true}, {name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: grant_type, var: grant_type}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, authorization: $authorization, grant_type: $grant_type, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of all endpoints
#
# GET /api/rest/v1
# Returns: record<authentication: record, host: string, routes: record>
# operationId: get_endpoints
export def "get-endpoints" [
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
    path: "/api/rest/v1"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of PAM asset categories
#
# GET /api/rest/v1/asset-categories
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_asset_categories
export def "get-asset-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/asset-categories"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several PAM asset categories
#
# PATCH /api/rest/v1/asset-categories
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_asset_categories
export def "patch-asset-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # PAM asset category code
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-categories"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, labels: $labels, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new PAM asset category
#
# POST /api/rest/v1/asset-categories
# operationId: post_asset_categories
export def "post-asset-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # PAM asset category code
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/asset-categories"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code, labels: $labels, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PAM asset category
#
# GET /api/rest/v1/asset-categories/{code}
# Returns: record<code: string, labels: record<localeCode: string>, parent: string>
# operationId: get_asset_categories__code_
export def "get-asset-categories-code" [
  code: string
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
    path: "/api/rest/v1/asset-categories/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a PAM asset category
#
# PATCH /api/rest/v1/asset-categories/{code}
# operationId: patch_asset_categories__code_
export def "patch-asset-categories-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # PAM asset category code (spec name: code)
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-categories/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, body_code: $body_code, labels: $labels, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of asset families
#
# GET /api/rest/v1/asset-families
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>
# operationId: get_asset_families
export def "get-asset-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/asset-families"
    query: [{name: search_after, var: search_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_after: $search_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the assets of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/assets
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<_items: list<record>>>
# operationId: get_assets
export def "get-assets" [
  asset_family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter assets, for more details see the Asset filters (/documentation/filter.html#filter-assets) section
  --channel: string # Filter asset values to return scopable asset attributes for the given channel as well as the non localizable/non scopable asset attributes, for more details see the Filter asset values by channel (/documentation/filter.html#asset-values-by-channel) section
  --locales: string # Filter asset values to return localizable attributes for the given locales as well as the non localizable/non scopable asset attributes, for more details see the Filter asset values by locale (/documentation/filter.html#asset-values-by-locale) section
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/asset-families/{asset_family_code}/assets"
    path_params: [{name: asset_family_code, var: asset_family_code}]
    query: [{name: search, var: search}, {name: channel, var: channel}, {name: locales, var: locales}, {name: search_after, var: search_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, search: $search, channel: $channel, locales: $locales, search_after: $search_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several assets
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/assets
# Returns: table<code: string, message: string, status_code: int>
# operationId: patch_assets
export def "patch-assets" [
  asset_family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-families/{asset_family_code}/assets"
    path_params: [{name: asset_family_code, var: asset_family_code}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an asset
#
# DELETE /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# operationId: delete_assets__code_
export def "delete-assets-code" [
  asset_family_code: string
  code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an asset of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# Returns: record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>>
# operationId: get_assets__code_
export def "get-assets-code" [
  asset_family_code: string
  code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an asset
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# operationId: patch_asset__code_
export def "patch-asset-code" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Code of the asset (spec name: code)
  --created: string # Date of creation (format: dateTime)
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Asset attributes values, see the Focus on the asset values section for more details. — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: created, var: created}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, code: $code, body_code: $body_code, created: $created, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of attributes of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes
# Returns: table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>
# operationId: get_asset_families__code__attributes
export def "get-asset-families-code-attributes" [
  asset_family_code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes"
    path_params: [{name: asset_family_code, var: asset_family_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of attribute options of a given attribute for a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options
# Returns: table<code: string, labels: record<localeCode: string>>
# operationId: get_asset_family_attributes__attribute_code__options
export def "get-asset-family-attributes-attribute-code-options" [
  asset_family_code: string
  attribute_code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: attribute_code, var: attribute_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, attribute_code: $attribute_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute option for a given attribute of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}
# Returns: record<code: string, labels: record<localeCode: string>>
# operationId: get_asset_attributes__attribute_code__options__code_
export def "get-asset-attributes-attribute-code-options-code" [
  asset_family_code: string
  attribute_code: string
  code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: attribute_code, var: attribute_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, attribute_code: $attribute_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an asset attribute option for a given asset family
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}
# operationId: patch_asset_attributes__attribute_code__options__code_
export def "patch-asset-attributes-attribute-code-options-code" [
  asset_family_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Attribute's option code (spec name: code)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: attribute_code, var: attribute_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, attribute_code: $attribute_code, code: $code, body_code: $body_code, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{code}
# Returns: record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>
# operationId: get_asset_family_attributes__code_
export def "get-asset-family-attributes-code" [
  asset_family_code: string
  code: string
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
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an attribute of a given asset family
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/attributes/{code}
# operationId: patch_asset_family_attributes__code_
export def "patch-asset-family-attributes-code" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list<string> # Extensions allowed when the attribute type is `media_file` (default: [])
  --body-code: string # Attribute code (spec name: code)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `number` (default: false)
  --is-read-only: oneof<nothing, bool> # Whether the attribute should be in read only mode only in the UI, but you can still update it with the API (default: false)
  --is-required-for-completeness: oneof<nothing, bool> # Whether the attribute should be part of the record's completeness calculation (default: false)
  --is-rich-text-editor: oneof<nothing, bool> # Whether the UI should display a rich text editor instead of a simple text area when the attribute type is `text`
  --is-textarea: oneof<nothing, bool> # Whether the UI should display a text area instead of a simple field when the attribute type is `text` (default: false)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --max-characters: int # Maximum number of characters allowed for the value of the attribute when the attribute type is `text`
  --max-file-size: string # Max file size in MB when the attribute type is `media_file`
  --max-value: string # Maximum value allowed when the attribute type is `number`
  media_type: string@media-type-completer # For the `media_link` attribute type, it is the type of the media behind the url, to allow its preview in the PIM. For the `media_file` attribute type, it is the type of the file.
  --min-value: string # Minimum value allowed when the attribute type is `number`
  --prefix: string # Prefix of the `media_link` attribute type. The common url root that prefixes the link to the media
  --suffix: string # Suffix of the `media_link` attribute type. The common url suffix for the media
  type: string@type-completer # Attribute type. See type section for more details.
  --validation-regexp: string # Regexp expression used to validate the attribute value when the attribute type is `text`
  --validation-rule: string@validation-rule-completer # Validation rule type used to validate the attribute value when the attribute type is `text` (default: none)
  --value-per-channel: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --value-per-locale: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-families/{asset_family_code}/attributes/{code}"
    path_params: [{name: asset_family_code, var: asset_family_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_extensions, var: allowed_extensions}, {name: code, var: body_code, required: true}, {name: decimals_allowed, var: decimals_allowed}, {name: is_read_only, var: is_read_only}, {name: is_required_for_completeness, var: is_required_for_completeness}, {name: is_rich_text_editor, var: is_rich_text_editor}, {name: is_textarea, var: is_textarea}, {name: labels, var: labels}, {name: max_characters, var: max_characters}, {name: max_file_size, var: max_file_size}, {name: max_value, var: max_value}, {name: media_type, var: media_type}, {name: min_value, var: min_value}, {name: prefix, var: prefix}, {name: suffix, var: suffix}, {name: type, var: type}, {name: validation_regexp, var: validation_regexp}, {name: validation_rule, var: validation_rule}, {name: value_per_channel, var: value_per_channel}, {name: value_per_locale, var: value_per_locale}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    asset_family_code: $asset_family_code, code: $code, allowed_extensions: $allowed_extensions, body_code: $body_code, decimals_allowed: $decimals_allowed, is_read_only: $is_read_only, is_required_for_completeness: $is_required_for_completeness, is_rich_text_editor: $is_rich_text_editor, is_textarea: $is_textarea, labels: $labels, max_characters: $max_characters, max_file_size: $max_file_size, max_value: $max_value, media_type: $media_type, min_value: $min_value, prefix: $prefix, suffix: $suffix, type: $type, validation_regexp: $validation_regexp, validation_rule: $validation_rule, value_per_channel: $value_per_channel, value_per_locale: $value_per_locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an asset family
#
# GET /api/rest/v1/asset-families/{code}
# Returns: record<attribute_as_main_media: string, code: string, labels: record<localeCode: string>, naming_convention: record<abort_asset_creation_on_error: bool, pattern: string, source: record>, product_link_rules: table<assign_assets_to: list, product_selections: list>, transformations: table<filename_prefix: string, filename_suffix: string, label: string, operations: record, source: record, target: record>>
# operationId: get_asset_family__code_
export def "get-asset-family-code" [
  code: string
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
    path: "/api/rest/v1/asset-families/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an asset family
#
# PATCH /api/rest/v1/asset-families/{code}
# operationId: patch_asset_family__code_
export def "patch-asset-family-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-main-media: string # Attribute code that is used as the main media of the asset family. (default: First media file or media link attribute that was created)
  --body-code: string # Asset family code (spec name: code)
  --labels: record # Asset family labels for each locale (default: {}) — shape: {localeCode?: string}
  --naming-convention: record # The naming convention ran over the asset code or the main media filename upon each asset creation, in order to automatically set several values in asset attributes. To learn more and see the format of this property, take a look at here. (default: {}) — shape: {abort_asset_creation_on_error?: bool, pattern?: string, source?: record}
  --product-link-rules: list # The rules that will be run after the asset creation, in order to automatically link the assets of this family to a set of products. To understand the format of this property, see here. (default: []) — item shape: {assign_assets_to?: list, product_selections?: list}
  --transformations: list # The transformations to perform on source files in order to generate new files into your asset attributes (only available since v4.0). To understand the format of this property, see here. (default: []) — item shape: {filename_prefix?: string, filename_suffix?: string, label: string, operations: record, source: record, target: record}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-families/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute_as_main_media, var: attribute_as_main_media}, {name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: naming_convention, var: naming_convention}, {name: product_link_rules, var: product_link_rules}, {name: transformations, var: transformations}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, attribute_as_main_media: $attribute_as_main_media, body_code: $body_code, labels: $labels, naming_convention: $naming_convention, product_link_rules: $product_link_rules, transformations: $transformations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new media file for an asset
#
# POST /api/rest/v1/asset-media-files
# operationId: post_asset_media_files
export def "post-asset-media-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed (required)
  file: string # The binary of the media file (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/asset-media-files"
    header: [{name: Content-type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    content_type: $content_type, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the media file associated to an asset
#
# GET /api/rest/v1/asset-media-files/{code}
# operationId: get_asset_media_files__code
export def "get-asset-media-files-code" [
  code: string
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
    path: "/api/rest/v1/asset-media-files/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of PAM asset tags
#
# GET /api/rest/v1/asset-tags
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_asset_tags
export def "get-asset-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/asset-tags"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PAM asset tag
#
# GET /api/rest/v1/asset-tags/{code}
# Returns: record<code: string>
# operationId: get_asset_tags__code_
export def "get-asset-tags-code" [
  code: string
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
    path: "/api/rest/v1/asset-tags/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a PAM asset tag
#
# PATCH /api/rest/v1/asset-tags/{code}
# operationId: patch_asset_tags__code_
export def "patch-asset-tags-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # PAM asset tag code (spec name: code)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/asset-tags/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, body_code: $body_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of PAM assets
#
# GET /api/rest/v1/assets
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_pam_assets
export def "get-pam-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-type: string@pagination-type-completer # Pagination method type, see Pagination (/documentation/pagination.html) section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/assets"
    query: [{name: pagination_type, var: pagination_type}, {name: page, var: page}, {name: search_after, var: search_after}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pagination_type: $pagination_type, page: $page, search_after: $search_after, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several PAM assets
#
# PATCH /api/rest/v1/assets
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_pam_assets
export def "patch-pam-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Codes of the PAM asset categories in which the asset is classified (default: [])
  code: string # PAM asset code
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list<string> # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/assets"
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: code, var: code}, {name: description, var: description}, {name: end_of_use, var: end_of_use}, {name: localizable, var: localizable}, {name: reference_files, var: reference_files}, {name: tags, var: tags}, {name: variation_files, var: variation_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    categories: $categories, code: $code, description: $description, end_of_use: $end_of_use, localizable: $localizable, reference_files: $reference_files, tags: $tags, variation_files: $variation_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new PAM asset
#
# POST /api/rest/v1/assets
# operationId: post_pam_assets
export def "post-pam-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Codes of the PAM asset categories in which the asset is classified (default: [])
  code: string # PAM asset code
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list<string> # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/assets"
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: code, var: code}, {name: description, var: description}, {name: end_of_use, var: end_of_use}, {name: localizable, var: localizable}, {name: reference_files, var: reference_files}, {name: tags, var: tags}, {name: variation_files, var: variation_files}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    categories: $categories, code: $code, description: $description, end_of_use: $end_of_use, localizable: $localizable, reference_files: $reference_files, tags: $tags, variation_files: $variation_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reference file
#
# GET /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}
# Returns: record<_link: record<download: record<href: string>>, code: string, locale: string>
# operationId: get_reference_files__locale_code_
export def "get-reference-files-locale-code" [
  asset_code: string
  locale_code: string
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
    path: "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}"
    path_params: [{name: asset_code, var: asset_code}, {name: locale_code, var: locale_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_code: $asset_code, locale_code: $locale_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new reference file
#
# POST /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}
# Returns: record<errors: table<channel: string, locale: string, message: string>, message: string>
# operationId: post_reference_files__locale_code_
export def "post-reference-files-locale-code" [
  asset_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed (required)
  file: string # The binaries of the file (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}"
    path_params: [{name: asset_code, var: asset_code}, {name: locale_code, var: locale_code}]
    header: [{name: Content-type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    asset_code: $asset_code, locale_code: $locale_code, content_type: $content_type, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a reference file
#
# GET /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}/download
# operationId: get_reference_files__channel_code__locale_code__download
export def "get-reference-files-channel-code-locale-code-download" [
  asset_code: string
  locale_code: string
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
    path: "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}/download"
    path_params: [{name: asset_code, var: asset_code}, {name: locale_code, var: locale_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_code: $asset_code, locale_code: $locale_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variation file
#
# GET /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}
# Returns: record<_link: record<download: record<href: string>>, code: string, locale: string, scope: string>
# operationId: get_variation_files__channel_code__locale_code
export def "get-variation-files-channel-code-locale-code" [
  asset_code: string
  channel_code: string
  locale_code: string
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
    path: "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}"
    path_params: [{name: asset_code, var: asset_code}, {name: channel_code, var: channel_code}, {name: locale_code, var: locale_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new variation file
#
# POST /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}
# operationId: post_variation_files__channel_code__locale_code_
export def "post-variation-files-channel-code-locale-code" [
  asset_code: string
  channel_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed (required)
  file: string # The binaries of the file (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}"
    path_params: [{name: asset_code, var: asset_code}, {name: channel_code, var: channel_code}, {name: locale_code, var: locale_code}]
    header: [{name: Content-type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code, content_type: $content_type, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a variation file
#
# GET /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}/download
# operationId: get_variation_files__channel_code__locale_code__download
export def "get-variation-files-channel-code-locale-code-download" [
  asset_code: string
  channel_code: string
  locale_code: string
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
    path: "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}/download"
    path_params: [{name: asset_code, var: asset_code}, {name: channel_code, var: channel_code}, {name: locale_code, var: locale_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PAM asset
#
# GET /api/rest/v1/assets/{code}
# Returns: record<categories: list<string>, code: string, description: string, end_of_use: string, localizable: bool, reference_files: table<_link: record, code: string, locale: string>, tags: list<string>, variation_files: table<_link: record, code: string, locale: string, scope: string>>
# operationId: get_pam_assets__code_
export def "get-pam-assets-code" [
  code: string
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
    path: "/api/rest/v1/assets/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a PAM asset
#
# PATCH /api/rest/v1/assets/{code}
# operationId: patch_pam_assets__code_
export def "patch-pam-assets-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Codes of the PAM asset categories in which the asset is classified (default: [])
  --body-code: string # PAM asset code (spec name: code)
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list<string> # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/assets/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: code, var: body_code, required: true}, {name: description, var: description}, {name: end_of_use, var: end_of_use}, {name: localizable, var: localizable}, {name: reference_files, var: reference_files}, {name: tags, var: tags}, {name: variation_files, var: variation_files}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, categories: $categories, body_code: $body_code, description: $description, end_of_use: $end_of_use, localizable: $localizable, reference_files: $reference_files, tags: $tags, variation_files: $variation_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of association types
#
# GET /api/rest/v1/association-types
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: association_types_get_list
export def "association-types-get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/association-types"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several association types
#
# PATCH /api/rest/v1/association-types
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: several_association_types_patch
export def "several-association-types-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Association type code
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/association-types"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: is_quantified, var: is_quantified}, {name: is_two_way, var: is_two_way}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, is_quantified: $is_quantified, is_two_way: $is_two_way, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new association type
#
# POST /api/rest/v1/association-types
# operationId: association_types_post
export def "association-types-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Association type code
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/association-types"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: is_quantified, var: is_quantified}, {name: is_two_way, var: is_two_way}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code, is_quantified: $is_quantified, is_two_way: $is_two_way, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an association type
#
# GET /api/rest/v1/association-types/{code}
# Returns: record<code: string, is_quantified: bool, is_two_way: bool, labels: record<localeCode: string>>
# operationId: association_types_get
export def "association-types-get" [
  code: string
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
    path: "/api/rest/v1/association-types/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an association type
#
# PATCH /api/rest/v1/association-types/{code}
# operationId: association_types_patch
export def "association-types-patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Association type code (spec name: code)
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/association-types/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: is_quantified, var: is_quantified}, {name: is_two_way, var: is_two_way}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, body_code: $body_code, is_quantified: $is_quantified, is_two_way: $is_two_way, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of attribute groups
#
# GET /api/rest/v1/attribute-groups
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: attribute_groups_get_list
export def "attribute-groups-get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter attribute groups, for more details see the Filters (/documentation/filter.html#filter-attribute-groups) section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/attribute-groups"
    query: [{name: search, var: search}, {name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several attribute groups
#
# PATCH /api/rest/v1/attribute-groups
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: several_attribute_groups_patch
export def "several-attribute-groups-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string> # Attribute codes that compose the attribute group (default: [])
  code: string # Attribute group code
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attribute-groups"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: code, var: code}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attributes: $attributes, code: $code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new attribute group
#
# POST /api/rest/v1/attribute-groups
# operationId: attribute_groups_post
export def "attribute-groups-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string> # Attribute codes that compose the attribute group (default: [])
  code: string # Attribute group code
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/attribute-groups"
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: code, var: code}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attributes: $attributes, code: $code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute group
#
# GET /api/rest/v1/attribute-groups/{code}
# Returns: record<attributes: list<string>, code: string, labels: record<localeCode: string>, sort_order: int>
# operationId: attribute_groups_get
export def "attribute-groups-get" [
  code: string
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
    path: "/api/rest/v1/attribute-groups/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an attribute group
#
# PATCH /api/rest/v1/attribute-groups/{code}
# operationId: attribute_groups_patch
export def "attribute-groups-patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string> # Attribute codes that compose the attribute group (default: [])
  --body-code: string # Attribute group code (spec name: code)
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attribute-groups/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, attributes: $attributes, body_code: $body_code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of attributes
#
# GET /api/rest/v1/attributes
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_attributes
export def "get-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter attributes, for more details see the Filters (/documentation/filter.html#filter-attributes) section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-table-select-options: oneof<nothing, bool> # Return the options of 'select' column types (of a table attribute) in the response. (Only available since the 7.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/attributes"
    query: [{name: search, var: search}, {name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}, {name: with_table_select_options, var: with_table_select_options}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, limit: $limit, with_count: $with_count, with_table_select_options: $with_table_select_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several attributes
#
# PATCH /api/rest/v1/attributes
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_attributes
export def "patch-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list<string> # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list<string> # To make the attribute locale specfic, specify here for which locales it is specific
  code: string # Attribute code
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See type section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attributes"
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_extensions, var: allowed_extensions}, {name: available_locales, var: available_locales}, {name: code, var: code}, {name: date_max, var: date_max}, {name: date_min, var: date_min}, {name: decimals_allowed, var: decimals_allowed}, {name: default_metric_unit, var: default_metric_unit}, {name: default_value, var: default_value}, {name: group, var: group}, {name: group_labels, var: group_labels}, {name: labels, var: labels}, {name: localizable, var: localizable}, {name: max_characters, var: max_characters}, {name: max_file_size, var: max_file_size}, {name: metric_family, var: metric_family}, {name: negative_allowed, var: negative_allowed}, {name: number_max, var: number_max}, {name: number_min, var: number_min}, {name: reference_data_name, var: reference_data_name}, {name: scopable, var: scopable}, {name: sort_order, var: sort_order}, {name: table_configuration, var: table_configuration}, {name: type, var: type}, {name: unique, var: unique}, {name: useable_as_grid_filter, var: useable_as_grid_filter}, {name: validation_regexp, var: validation_regexp}, {name: validation_rule, var: validation_rule}, {name: wysiwyg_enabled, var: wysiwyg_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowed_extensions: $allowed_extensions, available_locales: $available_locales, code: $code, date_max: $date_max, date_min: $date_min, decimals_allowed: $decimals_allowed, default_metric_unit: $default_metric_unit, default_value: $default_value, group: $group, group_labels: $group_labels, labels: $labels, localizable: $localizable, max_characters: $max_characters, max_file_size: $max_file_size, metric_family: $metric_family, negative_allowed: $negative_allowed, number_max: $number_max, number_min: $number_min, reference_data_name: $reference_data_name, scopable: $scopable, sort_order: $sort_order, table_configuration: $table_configuration, type: $type, unique: $unique, useable_as_grid_filter: $useable_as_grid_filter, validation_regexp: $validation_regexp, validation_rule: $validation_rule, wysiwyg_enabled: $wysiwyg_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new attribute
#
# POST /api/rest/v1/attributes
# operationId: post_attributes
export def "post-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list<string> # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list<string> # To make the attribute locale specfic, specify here for which locales it is specific
  code: string # Attribute code
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See type section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/attributes"
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_extensions, var: allowed_extensions}, {name: available_locales, var: available_locales}, {name: code, var: code}, {name: date_max, var: date_max}, {name: date_min, var: date_min}, {name: decimals_allowed, var: decimals_allowed}, {name: default_metric_unit, var: default_metric_unit}, {name: default_value, var: default_value}, {name: group, var: group}, {name: group_labels, var: group_labels}, {name: labels, var: labels}, {name: localizable, var: localizable}, {name: max_characters, var: max_characters}, {name: max_file_size, var: max_file_size}, {name: metric_family, var: metric_family}, {name: negative_allowed, var: negative_allowed}, {name: number_max, var: number_max}, {name: number_min, var: number_min}, {name: reference_data_name, var: reference_data_name}, {name: scopable, var: scopable}, {name: sort_order, var: sort_order}, {name: table_configuration, var: table_configuration}, {name: type, var: type}, {name: unique, var: unique}, {name: useable_as_grid_filter, var: useable_as_grid_filter}, {name: validation_regexp, var: validation_regexp}, {name: validation_rule, var: validation_rule}, {name: wysiwyg_enabled, var: wysiwyg_enabled}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    allowed_extensions: $allowed_extensions, available_locales: $available_locales, code: $code, date_max: $date_max, date_min: $date_min, decimals_allowed: $decimals_allowed, default_metric_unit: $default_metric_unit, default_value: $default_value, group: $group, group_labels: $group_labels, labels: $labels, localizable: $localizable, max_characters: $max_characters, max_file_size: $max_file_size, metric_family: $metric_family, negative_allowed: $negative_allowed, number_max: $number_max, number_min: $number_min, reference_data_name: $reference_data_name, scopable: $scopable, sort_order: $sort_order, table_configuration: $table_configuration, type: $type, unique: $unique, useable_as_grid_filter: $useable_as_grid_filter, validation_regexp: $validation_regexp, validation_rule: $validation_rule, wysiwyg_enabled: $wysiwyg_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of attribute options
#
# GET /api/rest/v1/attributes/{attribute_code}/options
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_attributes__attribute_code__options
export def "get-attributes-attribute-code-options" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/attributes/{attribute_code}/options"
    path_params: [{name: attribute_code, var: attribute_code}]
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attribute_code: $attribute_code, page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several attribute options
#
# PATCH /api/rest/v1/attributes/{attribute_code}/options
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_attributes__attribute_code__options
export def "patch-attributes-attribute-code-options" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  code: string # Code of option
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attributes/{attribute_code}/options"
    path_params: [{name: attribute_code, var: attribute_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}, {name: code, var: code}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attribute_code: $attribute_code, attribute: $attribute, code: $code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new attribute option
#
# POST /api/rest/v1/attributes/{attribute_code}/options
# operationId: post_attributes__attribute_code__options
export def "post-attributes-attribute-code-options" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  code: string # Code of option
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/attributes/{attribute_code}/options"
    path_params: [{name: attribute_code, var: attribute_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}, {name: code, var: code}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attribute_code: $attribute_code, attribute: $attribute, code: $code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute option
#
# GET /api/rest/v1/attributes/{attribute_code}/options/{code}
# Returns: record<attribute: string, code: string, labels: record<localeCode: string>, sort_order: int>
# operationId: get_attributes__attribute_code__options__code_
export def "get-attributes-attribute-code-options-code" [
  attribute_code: string
  code: string
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
    path: "/api/rest/v1/attributes/{attribute_code}/options/{code}"
    path_params: [{name: attribute_code, var: attribute_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attribute_code: $attribute_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an attribute option
#
# PATCH /api/rest/v1/attributes/{attribute_code}/options/{code}
# operationId: patch_attributes__attribute_code__options__code_
export def "patch-attributes-attribute-code-options-code" [
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  --body-code: string # Code of option (spec name: code)
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attributes/{attribute_code}/options/{code}"
    path_params: [{name: attribute_code, var: attribute_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}, {name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: sort_order, var: sort_order}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    attribute_code: $attribute_code, code: $code, attribute: $attribute, body_code: $body_code, labels: $labels, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute
#
# GET /api/rest/v1/attributes/{code}
# Returns: record<allowed_extensions: list<string>, available_locales: list<string>, code: string, date_max: string, date_min: string, decimals_allowed: bool, default_metric_unit: string, default_value: bool, group: string, group_labels: record<localeCode: string>, labels: record<localeCode: string>, localizable: bool, max_characters: int, max_file_size: string, metric_family: string, negative_allowed: bool, number_max: string, number_min: string, reference_data_name: string, scopable: bool, sort_order: int, table_configuration: table<code: string, data_type: string, is_required_for_completeness: bool, labels: record, validations: record>, type: string, unique: bool, useable_as_grid_filter: bool, validation_regexp: string, validation_rule: string, wysiwyg_enabled: bool>
# operationId: get_attributes__code_
export def "get-attributes-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-table-select-options: oneof<nothing, bool> # Return the options of 'select' column types (of a table attribute) in the response. (Only available since the 7.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/attributes/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: with_table_select_options, var: with_table_select_options}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, with_table_select_options: $with_table_select_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an attribute
#
# PATCH /api/rest/v1/attributes/{code}
# operationId: patch_attributes__code_
export def "patch-attributes-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list<string> # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list<string> # To make the attribute locale specfic, specify here for which locales it is specific
  --body-code: string # Attribute code (spec name: code)
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See type section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/attributes/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_extensions, var: allowed_extensions}, {name: available_locales, var: available_locales}, {name: code, var: body_code, required: true}, {name: date_max, var: date_max}, {name: date_min, var: date_min}, {name: decimals_allowed, var: decimals_allowed}, {name: default_metric_unit, var: default_metric_unit}, {name: default_value, var: default_value}, {name: group, var: group}, {name: group_labels, var: group_labels}, {name: labels, var: labels}, {name: localizable, var: localizable}, {name: max_characters, var: max_characters}, {name: max_file_size, var: max_file_size}, {name: metric_family, var: metric_family}, {name: negative_allowed, var: negative_allowed}, {name: number_max, var: number_max}, {name: number_min, var: number_min}, {name: reference_data_name, var: reference_data_name}, {name: scopable, var: scopable}, {name: sort_order, var: sort_order}, {name: table_configuration, var: table_configuration}, {name: type, var: type}, {name: unique, var: unique}, {name: useable_as_grid_filter, var: useable_as_grid_filter}, {name: validation_regexp, var: validation_regexp}, {name: validation_rule, var: validation_rule}, {name: wysiwyg_enabled, var: wysiwyg_enabled}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, allowed_extensions: $allowed_extensions, available_locales: $available_locales, body_code: $body_code, date_max: $date_max, date_min: $date_min, decimals_allowed: $decimals_allowed, default_metric_unit: $default_metric_unit, default_value: $default_value, group: $group, group_labels: $group_labels, labels: $labels, localizable: $localizable, max_characters: $max_characters, max_file_size: $max_file_size, metric_family: $metric_family, negative_allowed: $negative_allowed, number_max: $number_max, number_min: $number_min, reference_data_name: $reference_data_name, scopable: $scopable, sort_order: $sort_order, table_configuration: $table_configuration, type: $type, unique: $unique, useable_as_grid_filter: $useable_as_grid_filter, validation_regexp: $validation_regexp, validation_rule: $validation_rule, wysiwyg_enabled: $wysiwyg_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of owned catalogs
#
# GET /api/rest/v1/catalogs
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_app_catalogs
export def "get-app-catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/catalogs"
    query: [{name: page, var: page}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new catalog
#
# POST /api/rest/v1/catalogs
# Returns: record<enabled: bool, id: string, name: string>
# operationId: post_app_catalog
export def "post-app-catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Catalog name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/rest/v1/catalogs"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a catalog
#
# DELETE /api/rest/v1/catalogs/{id}
# operationId: delete_app_catalog
export def "delete-app-catalog" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/rest/v1/catalogs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a catalog
#
# GET /api/rest/v1/catalogs/{id}
# Returns: record<enabled: bool, id: string, name: string>
# operationId: get_app_catalog
export def "get-app-catalog" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/catalogs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a catalog
#
# PATCH /api/rest/v1/catalogs/{id}
# Returns: record<enabled: bool, id: string, name: string>
# operationId: patch_app_catalog
export def "patch-app-catalog" [
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
  name: string # Catalog name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/catalogs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of product uuids
#
# GET /api/rest/v1/catalogs/{id}/product-uuids
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<string>>>
# operationId: get_app_catalog_product_uuids
export def "get-app-catalog-product-uuids" [
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
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 100)
  --updated-before: string # Filter products that have been updated BEFORE the provided date (Only available on Catalogs endpoints) (format: date)
  --updated-after: string # Filter products that have been updated AFTER the provided date (Only available on Catalogs endpoints) (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/catalogs/{id}/product-uuids"
    path_params: [{name: id, var: id}]
    query: [{name: search_after, var: search_after}, {name: limit, var: limit}, {name: updated_before, var: updated_before}, {name: updated_after, var: updated_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, search_after: $search_after, limit: $limit, updated_before: $updated_before, updated_after: $updated_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of products related to a catalog
#
# GET /api/rest/v1/catalogs/{id}/products
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<string>>>
# operationId: get_app_catalog_products
export def "get-app-catalog-products" [
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
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 100)
  --updated-before: string # Filter products that have been updated BEFORE the provided date (Only available on Catalogs endpoints) (format: date)
  --updated-after: string # Filter products that have been updated AFTER the provided date (Only available on Catalogs endpoints) (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/catalogs/{id}/products"
    path_params: [{name: id, var: id}]
    query: [{name: search_after, var: search_after}, {name: limit, var: limit}, {name: updated_before, var: updated_before}, {name: updated_after, var: updated_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, search_after: $search_after, limit: $limit, updated_before: $updated_before, updated_after: $updated_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product related to a catalog
#
# GET /api/rest/v1/catalogs/{id}/products/{uuid}
# operationId: get_app_catalog_products_uuid
export def "get-app-catalog-products-uuid" [
  id: string
  uuid: string
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
    path: "/api/rest/v1/catalogs/{id}/products/{uuid}"
    path_params: [{name: id, var: id}, {name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of categories
#
# GET /api/rest/v1/categories
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_categories
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter categories, for more details see the Filters (/documentation/filter.html#filter-categories) section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-position: oneof<nothing, bool> # Return information about category position into its category tree (only available since the 7.0 version)
  --with-enriched-attributes: oneof<nothing, bool> # Return attribute values of the category (only available on SaaS platforms)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/categories"
    query: [{name: search, var: search}, {name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}, {name: with_position, var: with_position}, {name: with_enriched_attributes, var: with_enriched_attributes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, limit: $limit, with_count: $with_count, with_position: $with_position, with_enriched_attributes: $with_enriched_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several categories
#
# PATCH /api/rest/v1/categories
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_categories
export def "patch-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Category code
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: parent, var: parent}, {name: position, var: position}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, labels: $labels, parent: $parent, position: $position, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new category
#
# POST /api/rest/v1/categories
# operationId: post_categories
export def "post-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Category code
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: parent, var: parent}, {name: position, var: position}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code, labels: $labels, parent: $parent, position: $position, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a category
#
# GET /api/rest/v1/categories/{code}
# Returns: record<code: string, labels: record<localeCode: string>, parent: string, position: int, updated: string, values: record<"attributeCode|attributeUuid|channelCode|localeCode": list<record>>>
# operationId: get_categories__code_
export def "get-categories-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-position: oneof<nothing, bool> # Return information about category position into its category tree (only available since the 7.0 version)
  --with-enriched-attributes: oneof<nothing, bool> # Return attribute values of the category (only available on SaaS platforms) [COMING SOON]
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/categories/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: with_position, var: with_position}, {name: with_enriched_attributes, var: with_enriched_attributes}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, with_position: $with_position, with_enriched_attributes: $with_enriched_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a category
#
# PATCH /api/rest/v1/categories/{code}
# operationId: patch_categories__code_
export def "patch-categories-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Category code (spec name: code)
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/categories/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: parent, var: parent}, {name: position, var: position}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, body_code: $body_code, labels: $labels, parent: $parent, position: $position, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a category media file [COMING SOON]
#
# GET /api/rest/v1/category-media-files/{code}/download
# operationId: get_category_media_files__code__download
export def "get-category-media-files-code-download" [
  code: string
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
    path: "/api/rest/v1/category-media-files/{code}/download"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of channels
#
# GET /api/rest/v1/channels
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_channels
export def "get-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/channels"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several channels
#
# PATCH /api/rest/v1/channels
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: several_channels_patch
export def "several-channels-patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  code: string # Channel code
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list<string> # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list<string> # Codes of activated locales for the channel
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/channels"
    body: {content_type: "application/json", kind: json, fields: [{name: category_tree, var: category_tree}, {name: code, var: code}, {name: conversion_units, var: conversion_units}, {name: currencies, var: currencies}, {name: labels, var: labels}, {name: locales, var: locales}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_tree: $category_tree, code: $code, conversion_units: $conversion_units, currencies: $currencies, labels: $labels, locales: $locales
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new channel
#
# POST /api/rest/v1/channels
# operationId: channels_post
export def "channels-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  code: string # Channel code
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list<string> # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list<string> # Codes of activated locales for the channel
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/channels"
    body: {content_type: "application/json", kind: json, fields: [{name: category_tree, var: category_tree}, {name: code, var: code}, {name: conversion_units, var: conversion_units}, {name: currencies, var: currencies}, {name: labels, var: labels}, {name: locales, var: locales}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    category_tree: $category_tree, code: $code, conversion_units: $conversion_units, currencies: $currencies, labels: $labels, locales: $locales
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a channel
#
# GET /api/rest/v1/channels/{code}
# Returns: record<category_tree: string, code: string, conversion_units: record<attributeCode: string>, currencies: list<string>, labels: record<localeCode: string>, locales: list<string>>
# operationId: get_channels__code_
export def "get-channels-code" [
  code: string
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
    path: "/api/rest/v1/channels/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a channel
#
# PATCH /api/rest/v1/channels/{code}
# operationId: channels_patch
export def "channels-patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  --body-code: string # Channel code (spec name: code)
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list<string> # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list<string> # Codes of activated locales for the channel
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/channels/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: category_tree, var: category_tree}, {name: code, var: body_code, required: true}, {name: conversion_units, var: conversion_units}, {name: currencies, var: currencies}, {name: labels, var: labels}, {name: locales, var: locales}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, category_tree: $category_tree, body_code: $body_code, conversion_units: $conversion_units, currencies: $currencies, labels: $labels, locales: $locales
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of currencies
#
# GET /api/rest/v1/currencies
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: currencies_get_list
export def "currencies-get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/currencies"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a currency
#
# GET /api/rest/v1/currencies/{code}
# Returns: record<code: string, enabled: bool>
# operationId: currencies_get
export def "currencies-get" [
  code: string
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
    path: "/api/rest/v1/currencies/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of families
#
# GET /api/rest/v1/families
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_families
export def "get-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter families, for more details see the Filters (/documentation/filter.html#filter-families) section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/families"
    query: [{name: search, var: search}, {name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several families
#
# PATCH /api/rest/v1/families
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_families
export def "patch-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list<string>}
  --attributes: list<string> # Attributes codes that compose the family (default: [])
  code: string # Family code
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/families"
    body: {content_type: "application/json", kind: json, fields: [{name: attribute_as_image, var: attribute_as_image}, {name: attribute_as_label, var: attribute_as_label}, {name: attribute_requirements, var: attribute_requirements}, {name: attributes, var: attributes}, {name: code, var: code}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attribute_as_image: $attribute_as_image, attribute_as_label: $attribute_as_label, attribute_requirements: $attribute_requirements, attributes: $attributes, code: $code, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new family
#
# POST /api/rest/v1/families
# operationId: post_families
export def "post-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list<string>}
  --attributes: list<string> # Attributes codes that compose the family (default: [])
  code: string # Family code
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/families"
    body: {content_type: "application/json", kind: json, fields: [{name: attribute_as_image, var: attribute_as_image}, {name: attribute_as_label, var: attribute_as_label}, {name: attribute_requirements, var: attribute_requirements}, {name: attributes, var: attributes}, {name: code, var: code}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attribute_as_image: $attribute_as_image, attribute_as_label: $attribute_as_label, attribute_requirements: $attribute_requirements, attributes: $attributes, code: $code, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a family
#
# GET /api/rest/v1/families/{code}
# Returns: record<attribute_as_image: string, attribute_as_label: string, attribute_requirements: record<channelCode: list<string>>, attributes: list<string>, code: string, labels: record<localeCode: string>>
# operationId: get_families__code_
export def "get-families-code" [
  code: string
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
    path: "/api/rest/v1/families/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a family
#
# PATCH /api/rest/v1/families/{code}
# operationId: patch_families__code_
export def "patch-families-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list<string>}
  --attributes: list<string> # Attributes codes that compose the family (default: [])
  --body-code: string # Family code (spec name: code)
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/families/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute_as_image, var: attribute_as_image}, {name: attribute_as_label, var: attribute_as_label}, {name: attribute_requirements, var: attribute_requirements}, {name: attributes, var: attributes}, {name: code, var: body_code, required: true}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, attribute_as_image: $attribute_as_image, attribute_as_label: $attribute_as_label, attribute_requirements: $attribute_requirements, attributes: $attributes, body_code: $body_code, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of family variants
#
# GET /api/rest/v1/families/{family_code}/variants
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_families__family_code__variants
export def "get-families-family-code-variants" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/families/{family_code}/variants"
    path_params: [{name: family_code, var: family_code}]
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    family_code: $family_code, page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several family variants
#
# PATCH /api/rest/v1/families/{family_code}/variants
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_families__family_code__variants
export def "patch-families-family-code-variants" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Family variant code
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list<string>, axes: list<string>, level: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/families/{family_code}/variants"
    path_params: [{name: family_code, var: family_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: variant_attribute_sets, var: variant_attribute_sets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    family_code: $family_code, code: $code, labels: $labels, variant_attribute_sets: $variant_attribute_sets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new family variant
#
# POST /api/rest/v1/families/{family_code}/variants
# operationId: post_families__family_code__variants
export def "post-families-family-code-variants" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Family variant code
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list<string>, axes: list<string>, level: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/families/{family_code}/variants"
    path_params: [{name: family_code, var: family_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: labels, var: labels}, {name: variant_attribute_sets, var: variant_attribute_sets}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    family_code: $family_code, code: $code, labels: $labels, variant_attribute_sets: $variant_attribute_sets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a family variant
#
# GET /api/rest/v1/families/{family_code}/variants/{code}
# Returns: record<code: string, labels: record<localeCode: string>, variant_attribute_sets: table<attributes: list, axes: list, level: int>>
# operationId: get_families__family_code__variants__code__
export def "get-families-family-code-variants-code" [
  family_code: string
  code: string
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
    path: "/api/rest/v1/families/{family_code}/variants/{code}"
    path_params: [{name: family_code, var: family_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    family_code: $family_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a family variant
#
# PATCH /api/rest/v1/families/{family_code}/variants/{code}
# operationId: patch_families__family_code__variants__code__
export def "patch-families-family-code-variants-code" [
  family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Family variant code (spec name: code)
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list<string>, axes: list<string>, level: int}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/families/{family_code}/variants/{code}"
    path_params: [{name: family_code, var: family_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: labels, var: labels}, {name: variant_attribute_sets, var: variant_attribute_sets}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    family_code: $family_code, code: $code, body_code: $body_code, labels: $labels, variant_attribute_sets: $variant_attribute_sets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of locales
#
# GET /api/rest/v1/locales
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_locales
export def "get-locales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter locales, for more details see the Filters (/documentation/filter.html) section
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/locales"
    query: [{name: search, var: search}, {name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a locale
#
# GET /api/rest/v1/locales/{code}
# Returns: record<code: string, enabled: bool>
# operationId: get_locales__code_
export def "get-locales-code" [
  code: string
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
    path: "/api/rest/v1/locales/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of measure familiy
#
# GET /api/rest/v1/measure-families
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: measure_families_get_list
export def "measure-families-get-list" [
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
    path: "/api/rest/v1/measure-families"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a measure family
#
# GET /api/rest/v1/measure-families/{code}
# Returns: record<code: string, standard: string, units: table<code: string, convert: record, symbol: string>>
# operationId: measure_families_get
export def "measure-families-get" [
  code: string
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
    path: "/api/rest/v1/measure-families/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of measurement families
#
# GET /api/rest/v1/measurement-families
# Returns: record<code: string, labels: record<localeCode: string>, standard_unit_code: string, units: record<unitCode: record<code: string, convert_from_standard: list, labels: record, symbol: string>>>
# operationId: measurement_families_get_list
export def "measurement-families-get-list" [
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
    path: "/api/rest/v1/measurement-families"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several measurement families
#
# PATCH /api/rest/v1/measurement-families
# Returns: table<code: string, errors: list<record>, message: string, status_code: int>
# operationId: patch_measurement_families
export def "patch-measurement-families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/measurement-families"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of product media files
#
# GET /api/rest/v1/media-files
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_media_files
export def "get-media-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/media-files"
    query: [{name: page, var: page}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product media file
#
# POST /api/rest/v1/media-files
# operationId: post_media_files
export def "post-media-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed (required)
  file: string # The binaries of the file (format: binary)
  --product: string # The product to which the media file will be associated. It is a JSON string that follows this format '{"identifier":"product_identifier", "attribute":"attribute_code", "scope":"channel_code","locale":"locale_code"}'. You have to either use this field or the `product_model` field, but not both at the same time.
  --product-model: string # The product model to which the media file will be associated. It is a JSON string that follows this format '{"code":"product_model_code", "attribute":"attribute_code", "scope":"channel_code","locale":"locale_code"}'. You have to either use this field or the `product` field, but not both at the same time.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/media-files"
    header: [{name: Content-type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}, {name: product, var: product}, {name: product_model, var: product_model}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    content_type: $content_type, file: $file, product: $product, product_model: $product_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product media file
#
# GET /api/rest/v1/media-files/{code}
# Returns: record<_links: record<download: record<href: string>>, code: string, extension: string, mime_type: string, original_filename: string, size: int>
# operationId: get_media_files__code_
export def "get-media-files-code" [
  code: string
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
    path: "/api/rest/v1/media-files/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a product media file
#
# GET /api/rest/v1/media-files/{code}/download
# operationId: get_media_files__code__download
export def "get-media-files-code-download" [
  code: string
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
    path: "/api/rest/v1/media-files/{code}/download"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of product models
#
# GET /api/rest/v1/product-models
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_product_models
export def "get-product-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter product models, for more details see the Filters (/documentation/filter.html) section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the Filter product values via channel (/documentation/filter.html#via-channel) section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the Filter product values via locale (/documentation/filter.html#via-locale) section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the Filter on product values (/documentation/filter.html#filter-product-values) section and the Filter on product model properties (/documentation/filter.html#filter-on-product-model-properties) section
  --pagination-type: string@pagination-type-completer # Pagination method type, see Pagination (/documentation/pagination.html) section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product model quality scores in the response. (Only available since the 6.0 version)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/product-models"
    query: [{name: search, var: search}, {name: scope, var: scope}, {name: locales, var: locales}, {name: attributes, var: attributes}, {name: pagination_type, var: pagination_type}, {name: page, var: page}, {name: search_after, var: search_after}, {name: limit, var: limit}, {name: with_count, var: with_count}, {name: with_quality_scores, var: with_quality_scores}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, scope: $scope, locales: $locales, attributes: $attributes, pagination_type: $pagination_type, page: $page, search_after: $search_after, limit: $limit, with_count: $with_count, with_quality_scores: $with_quality_scores
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several product models
#
# PATCH /api/rest/v1/product-models
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_product_models
export def "patch-product-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product model is categorized (default: [])
  code: string # Product model code
  --created: string # Date of creation (format: dateTime)
  --family: string # Family code from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (only available since the 7.0 version and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/product-models"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: code, var: code}, {name: created, var: created}, {name: family, var: family}, {name: family_variant, var: family_variant}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    associations: $associations, categories: $categories, code: $code, created: $created, family: $family, family_variant: $family_variant, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product model
#
# POST /api/rest/v1/product-models
# operationId: post_product_models
export def "post-product-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product model is categorized (default: [])
  code: string # Product model code
  --created: string # Date of creation (format: dateTime)
  --family: string # Family code from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (only available since the 7.0 version and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/product-models"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: code, var: code}, {name: created, var: created}, {name: family, var: family}, {name: family_variant, var: family_variant}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    associations: $associations, categories: $categories, code: $code, created: $created, family: $family, family_variant: $family_variant, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product model
#
# DELETE /api/rest/v1/product-models/{code}
# operationId: delete_product_models__code_
export def "delete-product-models-code" [
  code: string
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
    path: "/api/rest/v1/product-models/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product model
#
# GET /api/rest/v1/product-models/{code}
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>>
# operationId: get_product_models__code_
export def "get-product-models-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-quality-scores: oneof<nothing, bool> # Return product model quality scores in the response. (Only available since the 6.0 version)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/product-models/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: with_quality_scores, var: with_quality_scores}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, with_quality_scores: $with_quality_scores
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a product model
#
# PATCH /api/rest/v1/product-models/{code}
# operationId: patch_product_models__code_
export def "patch-product-models-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product model is categorized (default: [])
  --body-code: string # Product model code (spec name: code)
  --created: string # Date of creation (format: dateTime)
  --family: string # Family code from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (only available since the 7.0 version and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/product-models/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: code, var: body_code, required: true}, {name: created, var: created}, {name: family, var: family}, {name: family_variant, var: family_variant}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, associations: $associations, categories: $categories, body_code: $body_code, created: $created, family: $family, family_variant: $family_variant, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a draft
#
# GET /api/rest/v1/product-models/{code}/draft
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>>
# operationId: get_product_model_draft__code_
export def "get-product-model-draft-code" [
  code: string
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
    path: "/api/rest/v1/product-models/{code}/draft"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a draft for approval
#
# POST /api/rest/v1/product-models/{code}/proposal
# operationId: post_product_model_proposal
export def "post-product-model-proposal" [
  code: string
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
    method: post
    path: "/api/rest/v1/product-models/{code}/proposal"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of products
#
# GET /api/rest/v1/products
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_products
export def "get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter products, for more details see the Filters (/documentation/filter.html) section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the Filter product values via channel (/documentation/filter.html#via-channel) section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the Filter product values via locale (/documentation/filter.html#via-locale) section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the Filter on product values (/documentation/filter.html#filter-product-values) section
  --pagination-type: string@pagination-type-completer # Pagination method type, see Pagination (/documentation/pagination.html) section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/products"
    query: [{name: search, var: search}, {name: scope, var: scope}, {name: locales, var: locales}, {name: attributes, var: attributes}, {name: pagination_type, var: pagination_type}, {name: page, var: page}, {name: search_after, var: search_after}, {name: limit, var: limit}, {name: with_count, var: with_count}, {name: with_attribute_options, var: with_attribute_options}, {name: with_quality_scores, var: with_quality_scores}, {name: with_completenesses, var: with_completenesses}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, scope: $scope, locales: $locales, attributes: $attributes, pagination_type: $pagination_type, page: $page, search_after: $search_after, limit: $limit, with_count: $with_count, with_attribute_options: $with_attribute_options, with_quality_scores: $with_quality_scores, with_completenesses: $with_completenesses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several products
#
# PATCH /api/rest/v1/products
# Returns: record<code: string, identifier: string, line: int, message: string, status_code: int>
# operationId: patch_products
export def "patch-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/products"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: identifier, var: identifier}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, identifier: $identifier, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, uuid: $uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product
#
# POST /api/rest/v1/products
# operationId: post_products
export def "post-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/products"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: identifier, var: identifier}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, identifier: $identifier, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, uuid: $uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of products
#
# GET /api/rest/v1/products-uuid
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_products_uuid
export def "get-products-uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter products, for more details see the Filters (/documentation/filter.html) section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the Filter product values via channel (/documentation/filter.html#via-channel) section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the Filter product values via locale (/documentation/filter.html#via-locale) section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the Filter on product values (/documentation/filter.html#filter-product-values) section
  --pagination-type: string@pagination-type-completer # Pagination method type, see Pagination (/documentation/pagination.html) section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/products-uuid"
    query: [{name: search, var: search}, {name: scope, var: scope}, {name: locales, var: locales}, {name: attributes, var: attributes}, {name: pagination_type, var: pagination_type}, {name: page, var: page}, {name: search_after, var: search_after}, {name: limit, var: limit}, {name: with_count, var: with_count}, {name: with_attribute_options, var: with_attribute_options}, {name: with_quality_scores, var: with_quality_scores}, {name: with_completenesses, var: with_completenesses}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, scope: $scope, locales: $locales, attributes: $attributes, pagination_type: $pagination_type, page: $page, search_after: $search_after, limit: $limit, with_count: $with_count, with_attribute_options: $with_attribute_options, with_quality_scores: $with_quality_scores, with_completenesses: $with_completenesses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several products
#
# PATCH /api/rest/v1/products-uuid
# Returns: record<line: int, message: string, status_code: int, uuid: string>
# operationId: patch_products_uuid
export def "patch-products-uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  uuid: string # Product uuid
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/products-uuid"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, uuid: $uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new product
#
# POST /api/rest/v1/products-uuid
# operationId: post_products_uuid
export def "post-products-uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product uuid
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/products-uuid"
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, uuid: $uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product
#
# DELETE /api/rest/v1/products-uuid/{uuid}
# operationId: delete_products_uuid__uuid_
export def "delete-products-uuid-uuid" [
  uuid: string
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
    path: "/api/rest/v1/products-uuid/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product
#
# GET /api/rest/v1/products-uuid/{uuid}
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>
# operationId: get_products_uuid__uuid_
export def "get-products-uuid-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/products-uuid/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    query: [{name: with_attribute_options, var: with_attribute_options}, {name: with_quality_scores, var: with_quality_scores}, {name: with_completenesses, var: with_completenesses}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid, with_attribute_options: $with_attribute_options, with_quality_scores: $with_quality_scores, with_completenesses: $with_completenesses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a product
#
# PATCH /api/rest/v1/products-uuid/{uuid}
# operationId: patch_products_uuid__uuid_
export def "patch-products-uuid-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --body-uuid: string # Product uuid (spec name: uuid)
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/products-uuid/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: body_uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    uuid: $uuid, associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, body_uuid: $body_uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a draft
#
# GET /api/rest/v1/products-uuid/{uuid}/draft
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>
# operationId: get_draft_uuid__uuid_
export def "get-draft-uuid-uuid" [
  uuid: string
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
    path: "/api/rest/v1/products-uuid/{uuid}/draft"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a draft for approval
#
# POST /api/rest/v1/products-uuid/{uuid}/proposal
# operationId: post_proposal_uuid
export def "post-proposal-uuid" [
  uuid: string
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
    method: post
    path: "/api/rest/v1/products-uuid/{uuid}/proposal"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product
#
# DELETE /api/rest/v1/products/{code}
# operationId: delete_products__code_
export def "delete-products-code" [
  code: string
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
    path: "/api/rest/v1/products/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product
#
# GET /api/rest/v1/products/{code}
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>
# operationId: get_products__code_
export def "get-products-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/products/{code}"
    path_params: [{name: code, var: code}]
    query: [{name: with_attribute_options, var: with_attribute_options}, {name: with_quality_scores, var: with_quality_scores}, {name: with_completenesses, var: with_completenesses}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, with_attribute_options: $with_attribute_options, with_quality_scores: $with_quality_scores, with_completenesses: $with_completenesses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a product
#
# PATCH /api/rest/v1/products/{code}
# operationId: patch_products__code_
export def "patch-products-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list<string> # Codes of the categories in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # Family code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list<string> # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent product model when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see Product values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/products/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: associations, var: associations}, {name: categories, var: categories}, {name: completenesses, var: completenesses}, {name: created, var: created}, {name: enabled, var: enabled}, {name: family, var: family}, {name: groups, var: groups}, {name: identifier, var: identifier}, {name: metadata, var: metadata}, {name: parent, var: parent}, {name: quality_scores, var: quality_scores}, {name: quantified_associations, var: quantified_associations}, {name: updated, var: updated}, {name: uuid, var: uuid}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, associations: $associations, categories: $categories, completenesses: $completenesses, created: $created, enabled: $enabled, family: $family, groups: $groups, identifier: $identifier, metadata: $metadata, parent: $parent, quality_scores: $quality_scores, quantified_associations: $quantified_associations, updated: $updated, uuid: $uuid, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a draft
#
# GET /api/rest/v1/products/{code}/draft
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>>
# operationId: get_draft__code_
export def "get-draft-code" [
  code: string
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
    path: "/api/rest/v1/products/{code}/draft"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a draft for approval
#
# POST /api/rest/v1/products/{code}/proposal
# operationId: post_proposal
export def "post-proposal" [
  code: string
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
    method: post
    path: "/api/rest/v1/products/{code}/proposal"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of published products
#
# GET /api/rest/v1/published-products
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, current_page: int, _embedded: record<items: list<record>>>
# operationId: get_published_products
export def "get-published-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter published products, for more details see the Filters (/documentation/filter.html) section
  --scope: string # Filter published product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the Filter on published product values (/documentation/filter.html#filter-published-product-values) section
  --locales: string # Filter published product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the Filter on published product values (/documentation/filter.html#filter-published-product-values) section
  --attributes: string # Filter published product values to only return those concerning the given attributes, for more details see the Filter on product values (/documentation/filter.html#filter-product-values) section
  --pagination-type: string@pagination-type-completer # Pagination method type, see Pagination (/documentation/pagination.html) section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html#pagination) section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
  --limit: int # Number of results by page, see Pagination (/documentation/pagination.html) section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/published-products"
    query: [{name: search, var: search}, {name: scope, var: scope}, {name: locales, var: locales}, {name: attributes, var: attributes}, {name: pagination_type, var: pagination_type}, {name: page, var: page}, {name: search_after, var: search_after}, {name: limit, var: limit}, {name: with_count, var: with_count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, scope: $scope, locales: $locales, attributes: $attributes, pagination_type: $pagination_type, page: $page, search_after: $search_after, limit: $limit, with_count: $with_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a published product
#
# GET /api/rest/v1/published-products/{code}
# Returns: record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, quantified_associations: record, updated: string, values: record<attributeCode: list<record>>>
# operationId: get_published_products__code_
export def "get-published-products-code" [
  code: string
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
    path: "/api/rest/v1/published-products/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of reference entities
#
# GET /api/rest/v1/reference-entities
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>
# operationId: get_reference_entities
export def "get-reference-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/reference-entities"
    query: [{name: search_after, var: search_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_after: $search_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new media file for a reference entity or a record
#
# POST /api/rest/v1/reference-entities-media-files
# operationId: post_reference_entity_media_files
export def "post-reference-entity-media-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed (required)
  file: string # The binary of the media file (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/rest/v1/reference-entities-media-files"
    header: [{name: Content-type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    content_type: $content_type, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the media file associated to a reference entity or a record
#
# GET /api/rest/v1/reference-entities-media-files/{code}
# operationId: get_reference_entity_media_files__code
export def "get-reference-entity-media-files-code" [
  code: string
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
    path: "/api/rest/v1/reference-entities-media-files/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reference entity
#
# GET /api/rest/v1/reference-entities/{code}
# Returns: record<_links: record<image_download: record<href: string>>, code: string, image: string, labels: record<localeCode: string>>
# operationId: get_reference_entities__code_
export def "get-reference-entities-code" [
  code: string
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
    path: "/api/rest/v1/reference-entities/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a reference entity
#
# PATCH /api/rest/v1/reference-entities/{code}
# operationId: patch_reference_entity__code_
export def "patch-reference-entity-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Reference entity code (spec name: code)
  --image: string # Code of the reference entity image
  --labels: record # Reference entity labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/reference-entities/{code}"
    path_params: [{name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: image, var: image}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    code: $code, body_code: $body_code, image: $image, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of attributes of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes
# Returns: table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>
# operationId: get_reference_entities__code__attributes
export def "get-reference-entities-code-attributes" [
  reference_entity_code: string
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
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes"
    path_params: [{name: reference_entity_code, var: reference_entity_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of attribute options of a given attribute for a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options
# Returns: table<code: string, labels: record<localeCode: string>>
# operationId: get_reference_entity_attributes__attribute_code__options
export def "get-reference-entity-attributes-attribute-code-options" [
  reference_entity_code: string
  attribute_code: string
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
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: attribute_code, var: attribute_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, attribute_code: $attribute_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute option for a given attribute of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}
# Returns: record<code: string, labels: record<localeCode: string>>
# operationId: get_reference_entity_attributes__attribute_code__options__code_
export def "get-reference-entity-attributes-attribute-code-options-code" [
  reference_entity_code: string
  attribute_code: string
  code: string
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
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: attribute_code, var: attribute_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, attribute_code: $attribute_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a reference entity attribute option
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}
# operationId: patch_reference_entity_attributes__attribute_code__options__code_
export def "patch-reference-entity-attributes-attribute-code-options-code" [
  reference_entity_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Attribute's option code (spec name: code)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: attribute_code, var: attribute_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, attribute_code: $attribute_code, code: $code, body_code: $body_code, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attribute of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}
# Returns: record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool>
# operationId: get_reference_entity_attributes__code_
export def "get-reference-entity-attributes-code" [
  reference_entity_code: string
  code: string
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
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create an attribute of a given reference entity
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}
# operationId: patch_reference_entity_attributes__code_
export def "patch-reference-entity-attributes-code" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list<string> # Extensions allowed when the attribute type is `image` (default: [])
  --body-code: string # Attribute code (spec name: code)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `number` (default: false)
  --is-required-for-completeness: oneof<nothing, bool> # Whether the attribute should be part of the record's completeness calculation (default: false)
  --is-rich-text-editor: oneof<nothing, bool> # Whether the UI should display a rich text editor instead of a simple text area when the attribute type is `text`
  --is-textarea: oneof<nothing, bool> # Whether the UI should display a text area instead of a simple field when the attribute type is `text` (default: false)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --max-characters: int # Maximum number of characters allowed for the value of the attribute when the attribute type is `text`
  --max-file-size: string # Max file size in MB when the attribute type is `image`
  --max-value: string # Maximum value allowed when the attribute type is `number`
  --min-value: string # Minimum value allowed when the attribute type is `number`
  --body-reference-entity-code: string # Code of the linked reference entity when the attribute type is `reference_entity_single_link` or `reference_entity_multiple_links` (spec name: reference_entity_code)
  type: string@type-completer-2 # Attribute type. See type section for more details.
  --validation-regexp: string # Regexp expression used to validate the attribute value when the attribute type is `text`
  --validation-rule: string@validation-rule-completer # Validation rule type used to validate the attribute value when the attribute type is `text` (default: none)
  --value-per-channel: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --value-per-locale: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowed_extensions, var: allowed_extensions}, {name: code, var: body_code, required: true}, {name: decimals_allowed, var: decimals_allowed}, {name: is_required_for_completeness, var: is_required_for_completeness}, {name: is_rich_text_editor, var: is_rich_text_editor}, {name: is_textarea, var: is_textarea}, {name: labels, var: labels}, {name: max_characters, var: max_characters}, {name: max_file_size, var: max_file_size}, {name: max_value, var: max_value}, {name: min_value, var: min_value}, {name: reference_entity_code, var: body_reference_entity_code}, {name: type, var: type}, {name: validation_regexp, var: validation_regexp}, {name: validation_rule, var: validation_rule}, {name: value_per_channel, var: value_per_channel}, {name: value_per_locale, var: value_per_locale}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, code: $code, allowed_extensions: $allowed_extensions, body_code: $body_code, decimals_allowed: $decimals_allowed, is_required_for_completeness: $is_required_for_completeness, is_rich_text_editor: $is_rich_text_editor, is_textarea: $is_textarea, labels: $labels, max_characters: $max_characters, max_file_size: $max_file_size, max_value: $max_value, min_value: $min_value, body_reference_entity_code: $body_reference_entity_code, type: $type, validation_regexp: $validation_regexp, validation_rule: $validation_rule, value_per_channel: $value_per_channel, value_per_locale: $value_per_locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the records of a reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/records
# Returns: record<_links: record<first: record<href: string>, next: record<href: string>, self: record<href: string>>, _embedded: record<items: list<record>>>
# operationId: get_reference_entity_records
export def "get-reference-entity-records" [
  reference_entity_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter records of the reference entity, for more details see the Filters (/documentation/filter.html#filter-reference-entity-records) section
  --channel: string # Filter attribute values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the Filter attribute values by channel (/documentation/filter.html#record-values-by-channel) section
  --locales: string # Filter attribute values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the Filter attribute values by locale (/documentation/filter.html#record-values-by-locale) section
  --search-after: string # Cursor when using the `search_after` pagination method type. Should never be set manually, see Pagination (/documentation/pagination.html) section (default: cursor to the first page)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/records"
    path_params: [{name: reference_entity_code, var: reference_entity_code}]
    query: [{name: search, var: search}, {name: channel, var: channel}, {name: locales, var: locales}, {name: search_after, var: search_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, search: $search, channel: $channel, locales: $locales, search_after: $search_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create several reference entity records
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/records
# Returns: table<code: string, message: string, status_code: int>
# operationId: patch_reference_entity_records
export def "patch-reference-entity-records" [
  reference_entity_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/records"
    path_params: [{name: reference_entity_code, var: reference_entity_code}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a record of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/records/{code}
# Returns: record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>>
# operationId: get_reference_entity_records__code_
export def "get-reference-entity-records-code" [
  reference_entity_code: string
  code: string
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
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/records/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/create a record of a given reference entity
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/records/{code}
# operationId: patch_reference_entity_records__code_
export def "patch-reference-entity-records-code" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Code of the record (spec name: code)
  --created: string # Date of creation. (format: dateTime)
  --updated: string # Date of the last update. (format: dateTime)
  --values: record # Record attributes values, see Reference entity record values section for more details — shape: {attributeCode?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/rest/v1/reference-entities/{reference_entity_code}/records/{code}"
    path_params: [{name: reference_entity_code, var: reference_entity_code}, {name: code, var: code}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: body_code, required: true}, {name: created, var: created}, {name: updated, var: updated}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    reference_entity_code: $reference_entity_code, code: $code, body_code: $body_code, created: $created, updated: $updated, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system information
#
# GET /api/rest/v1/system-information
# Returns: record<edition: string, version: string>
# operationId: get_system_information
export def "get-system-information" [
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
    path: "/api/rest/v1/system-information"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
