# Auto-generated client for Box Platform API v2.0.0
# Source: https://api.apis.guru/v2/specs/box.com/2.0.0/openapi.json
# Auth: --token flag or $env.BOX_PLATFORM_API_TOKEN

const CLIENT = {
  base_url: "https://api.box.com/2.0"
  token_env_var: "BOX_PLATFORM_API_TOKEN"
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

def base-url-completer [] { ["https://api.box.com/2.0" "https://account.box.com/api/oauth2" "https://upload.box.com/api/2.0" "https://api.box.com" "https://dl.boxcloud.com/2.0"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def response-type-completer [] { ["code"] }
def direction-completer [] { ["both" "inbound" "outbound"] }
def status-completer [] { ["pending"] }
def role-completer [] { ["co-owner" "editor" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def role-completer-1 [] { ["co-owner" "editor" "owner" "previewer" "previewer uploader" "uploader" "viewer" "viewer uploader"] }
def status-completer-1 [] { ["accepted" "pending" "rejected"] }
def direction-completer-1 [] { ["ASC" "DESC"] }
def stream-type-completer [] { ["admin_logs" "admin_logs_streaming" "all" "changes" "sync"] }
def status-completer-2 [] { ["active" "inactive"] }
def disposition-action-completer [] { ["permanently_delete" "remove_retention"] }
def scope-completer [] { ["enterprise" "global"] }
def extension-completer [] { ["jpg" "png"] }
def accept-completer [] { ["application/json" "image/jpg" "image/png"] }
def type-completer [] { ["file_version"] }
def sync-state-completer [] { ["not_synced" "partially_synced" "synced"] }
def sort-completer [] { ["date" "id" "name" "size"] }
def role-completer-2 [] { ["admin" "member"] }
def invitability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def member-viewability-level-completer [] { ["admins_and_members" "admins_only" "all_managed_users"] }
def assign-to-type-completer [] { ["file" "file_version" "folder" "user"] }
def conflict-resolution-completer [] { ["none" "overwrite"] }
def display-name-completer [] { ["Classification"] }
def scope-completer-1 [] { ["enterprise"] }
def template-key-completer [] { ["securityClassification-6VMVochwUWo"] }
def actor-token-type-completer [] { ["urn:ietf:params:oauth:token-type:id_token"] }
def box-subject-type-completer [] { ["enterprise" "user"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer" "urn:ietf:params:oauth:grant-type:token-exchange"] }
def subject-token-type-completer [] { ["urn:ietf:params:oauth:token-type:access_token"] }
def grant-type-completer-1 [] { ["refresh_token"] }
def policy-type-completer [] { ["finite" "indefinite"] }
def are-owners-notified-completer [] { ["false" "true"] }
def can-owner-extend-retention-completer [] { ["false" "true"] }
def retention-type-completer [] { ["modifiable" "non-modifiable"] }
def type-completer-1 [] { ["enterprise" "folder" "metadata_template"] }
def scope-completer-2 [] { ["enterprise_content" "user_content"] }
def type-completer-2 [] { ["file" "folder" "web_link"] }
def trash-content-completer [] { ["non_trashed_only" "trashed_only"] }
def sort-completer-1 [] { ["modified_at" "relevance"] }
def type-completer-3 [] { ["shield_information_barrier_segment_member"] }
def type-completer-4 [] { ["shield_information_barrier_segment_restriction"] }
def status-completer-3 [] { ["disabled" "draft" "enabled" "invalid" "pending"] }
def type-completer-5 [] { ["shield_information_barrier"] }
def status-completer-4 [] { ["disabled" "pending"] }
def signature-color-completer [] { ["black" "blue" "red"] }
def status-completer-5 [] { ["invoked" "permanent_failure" "processing" "success" "transient_failure"] }
def resolved-for-type-completer [] { ["enterprise" "user"] }
def resolution-state-completer [] { ["approved" "completed" "incomplete" "rejected"] }
def action-completer [] { ["complete" "review"] }
def completion-rule-completer [] { ["all_assignees" "any_assignee"] }
def tos-type-completer [] { ["external" "managed"] }
def status-completer-6 [] { ["disabled" "enabled"] }
def user-type-completer [] { ["all" "external" "managed"] }
def role-completer-3 [] { ["coadmin" "user"] }
def status-completer-7 [] { ["active" "cannot_delete_edit" "cannot_delete_edit_upload" "inactive"] }
def accept-completer-1 [] { ["application/json" "image/jpg"] }
def type-completer-6 [] { ["workflow_parameters"] }
def accept-completer-2 [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-authorize: "string"
    get-collaboration-whitelist-entries: "record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, direction: string, domain: string, enterprise: record, id: string, type: string>>"
    post-collaboration-whitelist-entries: "record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string>"
    get-collaboration-whitelist-entries-id: "record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string>"
    get-collaboration-whitelist-exempt-targets: "record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, enterprise: record, id: string, modified_at: string, type: string, user: record>>"
    post-collaboration-whitelist-exempt-targets: "record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>>"
    get-collaboration-whitelist-exempt-targets-id: "record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>>"
    get-collaborations: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>"
    post-collaborations: "record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>"
    get-collaborations-id: "record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>"
    put-collaborations-id: "record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>"
    get-collections: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<collection_type: string, id: string, name: string, type: string>>"
    get-collections-id-items: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>"
    post-comments: "record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>"
    get-comments-id: "record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>"
    put-comments-id: "record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>"
    get-device-pinners-id: "record<id: string, owned_by: record<id: string, type: string, login: string, name: string>, product_name: string, type: string>"
    get-enterprises-id-device-pinners: "record<entries: table<id: string, owned_by: record, product_name: string, type: string>, limit: int, next_marker: int, order: table<by: string, direction: string>>"
    get-events: "record<chunk_size: int, entries: table<additional_details: record, created_at: string, created_by: record, event_id: string, event_type: string, recorded_at: string, session_id: string, source: record, type: string>, next_stream_position: string>"
    options-events: "record"
    get-file-requests-id: "record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>"
    put-file-requests-id: "record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>"
    post-file-requests-id-copy: "record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>"
    get-file-version-legal-holds: "record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>"
    get-file-version-legal-holds-id: "record<deleted_at: string, file: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, file_version: record<id: string, type: string, sha1: string>, id: string, legal_hold_policy_assignments: table<id: string, type: string, assigned_at: string, assigned_by: record, assigned_to: record, deleted_at: string, legal_hold_policy: record>, type: string>"
    get-file-version-retentions: "record<limit: int, next_marker: int, prev_marker: int, entries: table<applied_at: string, disposition_at: string, file: record, file_version: record, id: string, type: string, winning_retention_policy: record>>"
    get-file-version-retentions-id: "record<applied_at: string, disposition_at: string, file: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, file_version: record<id: string, type: string, sha1: string>, id: string, type: string, winning_retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>>"
    options-files-content: "record"
    post-files-content: "record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>"
    post-files-upload-sessions: "record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>"
    get-files-upload-sessions-id: "record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>"
    put-files-upload-sessions-id: "record<part: record<offset: int, part_id: string, size: int, sha1: string>>"
    post-files-upload-sessions-id-commit: "record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>"
    get-files-upload-sessions-id-parts: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<offset: int, part_id: string, size: int, sha1: string>>"
    get-files-id: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    post-files-id: "record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, file_version: record<id: string, type: string, sha1: string>, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, sha1: string, shared_link: string, size: int, trashed_at: string, type: string>"
    put-files-id: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-files-idadd-shared-link: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-files-idget-shared-link: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-files-idremove-shared-link: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-files-idupdate-shared-link: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-files-id-collaborations: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>"
    get-files-id-comments: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, created_at: string, created_by: record, is_reply_comment: bool, item: record, message: string, modified_at: string>>"
    post-files-id-content: "record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>"
    post-files-id-copy: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-files-id-metadata: "record<entries: table<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>, limit: int>"
    get-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    post-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    put-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    get-files-id-metadata-global-box-skills-cards: "record<\"$canEdit\": bool, \"$id\": string, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": int, \"$version\": int, cards: list<any>>"
    post-files-id-metadata-global-box-skills-cards: "record<\"$canEdit\": bool, \"$id\": string, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": int, \"$version\": int, cards: list<any>>"
    put-files-id-metadata-global-box-skills-cards: "record<\"$canEdit\": bool, \"$id\": string, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": int, \"$version\": int, cards: list<any>>"
    get-files-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    post-files-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    put-files-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    get-files-id-tasks: "record<entries: table<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record, type: string>, total_count: int>"
    get-files-id-thumbnail-id: "binary"
    get-files-id-trash: "record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, file_version: record<id: string, type: string, sha1: string>, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, sha1: string, shared_link: string, size: int, trashed_at: string, type: string>"
    post-files-id-upload-sessions: "record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>"
    get-files-id-versions: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record, name: string, purged_at: string, restored_at: string, restored_by: record, size: int, trashed_at: string, trashed_by: record, uploader_display_name: string>>"
    post-files-id-versions-current: "record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>"
    get-files-id-versions-id: "record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>"
    put-files-id-versions-id: "record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>"
    get-files-id-watermark: "record<watermark: record<created_at: string, modified_at: string>>"
    put-files-id-watermark: "record<watermark: record<created_at: string, modified_at: string>>"
    get-folder-locks: "record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, created_by: record, folder: record, id: string, lock_type: string, locked_operations: record, type: string>>"
    post-folder-locks: "record<created_at: string, created_by: record<id: string, type: string>, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, lock_type: string, locked_operations: record<delete: bool, move: bool>, type: string>"
    post-folders: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-folders-trash-items: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>"
    get-folders-id: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    post-folders-id: "record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, size: int, trashed_at: string, type: string>"
    put-folders-id: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-folders-idadd-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-folders-idget-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-folders-idremove-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    put-folders-idupdate-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-folders-id-collaborations: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>"
    post-folders-id-copy: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-folders-id-items: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>"
    get-folders-id-metadata: "record<entries: table<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>, limit: int>"
    get-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    post-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    put-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo: "record<\"$canEdit\": bool, \"$parent\": string, \"$scope\": string, \"$template\": string, \"$type\": string, \"$typeVersion\": float, \"$version\": int, Box__Security__Classification__Key: string>"
    get-folders-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    post-folders-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    put-folders-id-metadata-id-id: "record<\"$parent\": string, \"$scope\": string, \"$template\": string, \"$version\": int>"
    get-folders-id-trash: "record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, size: int, trashed_at: string, type: string>"
    get-folders-id-watermark: "record<watermark: record<created_at: string, modified_at: string>>"
    put-folders-id-watermark: "record<watermark: record<created_at: string, modified_at: string>>"
    post-group-memberships: "record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>"
    get-group-memberships-id: "record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>"
    put-group-memberships-id: "record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>"
    get-groups: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, group_type: string, name: string>>"
    post-groups: "record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>"
    post-groups-terminate-sessions: "record<message: string>"
    get-groups-id: "record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>"
    put-groups-id: "record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>"
    get-groups-id-collaborations: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>"
    get-groups-id-memberships: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record>>"
    post-invites: "record<actionable_by: record<id: string, type: string, login: string, name: string>, created_at: string, id: string, invited_by: record<id: string, type: string, login: string, name: string>, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string>"
    get-invites-id: "record<actionable_by: record<id: string, type: string, login: string, name: string>, created_at: string, id: string, invited_by: record<id: string, type: string, login: string, name: string>, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string>"
    get-legal-hold-policies: "record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string, assignment_counts: record, created_at: string, created_by: record, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>>"
    post-legal-hold-policies: "record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>"
    get-legal-hold-policies-id: "record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>"
    put-legal-hold-policies-id: "record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>"
    get-legal-hold-policy-assignments: "record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string>>"
    post-legal-hold-policy-assignments: "record<id: string, type: string, assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record, deleted_at: string, legal_hold_policy: record<id: string, type: string>>"
    get-legal-hold-policy-assignments-id: "record<id: string, type: string, assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record, deleted_at: string, legal_hold_policy: record<id: string, type: string>>"
    get-legal-hold-policy-assignments-id-file-versions-on-hold: "record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>"
    get-legal-hold-policy-assignments-id-files-on-hold: "record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>"
    get-metadata-cascade-policies: "record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, owner_enterprise: record, parent: record, scope: string, templateKey: string, type: string>>"
    post-metadata-cascade-policies: "record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string>"
    get-metadata-cascade-policies-id: "record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string>"
    post-metadata-queries-execute-read: "record<entries: list<any>, limit: int, next_marker: string>"
    get-metadata-query-indices: "record<entries: table<fields: list, id: string, status: string, type: string>, limit: int, next_marker: string>"
    get-metadata-templates: "record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>"
    get-metadata-templates-enterprise: "record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>"
    get-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaadd: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemadelete: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaupdate: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    get-metadata-templates-global: "record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>"
    post-metadata-templates-schema: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    post-metadata-templates-schemaclassifications: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    get-metadata-templates-id-id-schema: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    put-metadata-templates-id-id-schema: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    get-metadata-templates-id: "record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>"
    post-oauth2-token: "record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string>"
    post-oauth2-tokenrefresh: "record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string>"
    get-recent-items: "record<limit: int, next_marker: int, prev_marker: int, entries: table<interacted_at: string, interaction_shared_link: string, interaction_type: string, item: record, type: string>>"
    get-retention-policies: "record<entries: table<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, limit: int, next_marker: string>"
    post-retention-policies: "record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>"
    get-retention-policies-id: "record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>"
    put-retention-policies-id: "record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>"
    get-retention-policies-id-assignments: "record<entries: table<id: string, type: string>, limit: int, next_marker: string>"
    post-retention-policy-assignments: "record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, start_date_field: string, type: string>"
    get-retention-policy-assignments-id: "record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, start_date_field: string, type: string>"
    get-retention-policy-assignments-id-file-versions-under-retention: "record<limit: int, next_marker: int, prev_marker: int, entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>>"
    get-retention-policy-assignments-id-files-under-retention: "record<limit: int, next_marker: int, prev_marker: int, entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>>"
    get-shared-items: "record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-shared-itemsfolders: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-shared-itemsweb-links: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    get-shield-information-barrier-reports: "record<entries: table<id: string, type: string, created_at: string, created_by: record, details: record, shield_information_barrier: record, status: string, updated_at: string>, limit: int, next_marker: string>"
    post-shield-information-barrier-reports: "record<id: string, type: string, created_at: string, created_by: record<id: string, type: string>, details: record<details: record<folder_id: string>>, shield_information_barrier: record<shield_information_barrier: record<id: string, type: string>>, status: string, updated_at: string>"
    get-shield-information-barrier-reports-id: "record<id: string, type: string, created_at: string, created_by: record<id: string, type: string>, details: record<details: record<folder_id: string>>, shield_information_barrier: record<shield_information_barrier: record<id: string, type: string>>, status: string, updated_at: string>"
    get-shield-information-barrier-segment-members: "record<entries: table<id: string, type: string, user: record, created_at: string, created_by: record, shield_information_barrier: record, shield_information_barrier_segment: record, updated_at: string, updated_by: record>, limit: int, next_marker: string>"
    post-shield-information-barrier-segment-members: "record<id: string, type: string, user: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barrier-segment-members-id: "record<id: string, type: string, user: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barrier-segment-restrictions: "record<entries: table<id: string, type: string, restricted_segment: record, shield_information_barrier_segment: record, created_at: string, created_by: record, shield_information_barrier: record, updated_at: string, updated_by: record>, limit: int, next_marker: string>"
    post-shield-information-barrier-segment-restrictions: "record<id: string, type: string, restricted_segment: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barrier-segment-restrictions-id: "record<id: string, type: string, restricted_segment: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barrier-segments: "record<entries: table<created_at: string, created_by: record, description: string, id: string, name: string, shield_information_barrier: record, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string>"
    post-shield-information-barrier-segments: "record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barrier-segments-id: "record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    put-shield-information-barrier-segments-id: "record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barriers: "record<entries: table<created_at: string, created_by: record, enabled_at: string, enabled_by: record, enterprise: record, id: string, status: string, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string>"
    post-shield-information-barriers: "record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    post-shield-information-barriers-change-status: "record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    get-shield-information-barriers-id: "record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>"
    get-sign-requests: "record<limit: int, next_marker: int, prev_marker: int, entries: table<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record, prefill_tags: list, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record, signature_color: string, signers: list, signing_log: record, source_files: list, status: string, type: string>>"
    post-sign-requests: "record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>"
    get-sign-requests-id: "record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>"
    post-sign-requests-id-cancel: "record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>"
    get-storage-policies: "record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string, name: string>>"
    get-storage-policies-id: "record<id: string, type: string, name: string>"
    get-storage-policy-assignments: "record<limit: int, next_marker: int, prev_marker: int, entries: table<assigned_to: record, storage_policy: record>>"
    post-storage-policy-assignments: "record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>"
    get-storage-policy-assignments-id: "record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>"
    put-storage-policy-assignments-id: "record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>"
    post-task-assignments: "record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>"
    get-task-assignments-id: "record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>"
    put-task-assignments-id: "record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>"
    post-tasks: "record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>"
    get-tasks-id: "record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>"
    put-tasks-id: "record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>"
    get-tasks-id-assignments: "record<entries: table<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string>, total_count: int>"
    get-terms-of-service-user-statuses: "record<entries: table<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record, type: string, user: record>, total_count: int>"
    post-terms-of-service-user-statuses: "record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record<id: string, type: string, login: string, name: string>>"
    put-terms-of-service-user-statuses-id: "record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record<id: string, type: string, login: string, name: string>>"
    get-terms-of-services: "record<entries: table<id: string, type: string, created_at: string, enterprise: record, modified_at: string, status: string, text: string, tos_type: string>, total_count: int>"
    post-terms-of-services: "record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>"
    get-terms-of-services-id: "record<id: string, type: string, created_at: string, enterprise: record<id: string, name: string, type: string>, modified_at: string, status: string, text: string, tos_type: string>"
    put-terms-of-services-id: "record<id: string, type: string, created_at: string, enterprise: record<id: string, name: string, type: string>, modified_at: string, status: string, text: string, tos_type: string>"
    get-users: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record, phone: string, space_amount: int, space_used: int, status: string, timezone: string>>"
    post-users: "record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>"
    get-users-me: "record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>"
    post-users-terminate-sessions: "record<message: string>"
    get-users-id: "record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>"
    put-users-id: "record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>"
    get-users-id-avatar: "binary"
    post-users-id-avatar: "record<pic_urls: record<large: string, preview: string, small: string>>"
    get-users-id-email-aliases: "record<entries: table<email: string, id: string, is_confirmed: bool, type: string>, total_count: int>"
    post-users-id-email-aliases: "record<email: string, id: string, is_confirmed: bool, type: string>"
    put-users-id-folders-0: "record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>"
    get-users-id-memberships: "record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record>>"
    post-web-links: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    get-web-links-id: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    post-web-links-id: "record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, trashed_at: string, type: string, url: string>"
    put-web-links-id: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    put-web-links-idadd-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    get-web-links-idget-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    put-web-links-idremove-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    put-web-links-idupdate-shared-link: "record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>"
    get-web-links-id-trash: "record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, trashed_at: string, type: string, url: string>"
    get-webhooks: "record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, target: record, type: string>>"
    post-webhooks: "record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>"
    get-webhooks-id: "record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>"
    put-webhooks-id: "record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>"
    get-workflows: "record<limit: int, next_marker: int, prev_marker: int, entries: table<description: string, id: string, is_enabled: bool, name: string, type: string, flows: list>>"
    post-zip-downloads: "record<download_url: string, expires_at: string, name_conflicts: list<list<record>>, status_url: string>"
    get-zip-downloads-id-content: "binary"
    get-zip-downloads-id-status: "record<downloaded_file_count: int, skipped_file_count: int, skipped_folder_count: int, state: string, total_file_count: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-authorize" "get-collaboration-whitelist-entries" "post-collaboration-whitelist-entries" "delete-collaboration-whitelist-entries-id" "get-collaboration-whitelist-entries-id" "get-collaboration-whitelist-exempt-targets" "post-collaboration-whitelist-exempt-targets" "delete-collaboration-whitelist-exempt-targets-id" "get-collaboration-whitelist-exempt-targets-id" "get-collaborations" "post-collaborations" "delete-collaborations-id" "get-collaborations-id" "put-collaborations-id" "get-collections" "get-collections-id-items" "post-comments" "delete-comments-id" "get-comments-id" "put-comments-id" "delete-device-pinners-id" "get-device-pinners-id" "get-enterprises-id-device-pinners" "get-events" "options-events" "delete-file-requests-id" "get-file-requests-id" "put-file-requests-id" "post-file-requests-id-copy" "get-file-version-legal-holds" "get-file-version-legal-holds-id" "get-file-version-retentions" "get-file-version-retentions-id" "options-files-content" "post-files-content" "post-files-upload-sessions" "delete-files-upload-sessions-id" "get-files-upload-sessions-id" "put-files-upload-sessions-id" "post-files-upload-sessions-id-commit" "get-files-upload-sessions-id-parts" "delete-files-id" "get-files-id" "post-files-id" "put-files-id" "put-files-idadd-shared-link" "get-files-idget-shared-link" "put-files-idremove-shared-link" "put-files-idupdate-shared-link" "get-files-id-collaborations" "get-files-id-comments" "get-files-id-content" "post-files-id-content" "post-files-id-copy" "get-files-id-metadata" "delete-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "get-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "post-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "put-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "delete-files-id-metadata-global-box-skills-cards" "get-files-id-metadata-global-box-skills-cards" "post-files-id-metadata-global-box-skills-cards" "put-files-id-metadata-global-box-skills-cards" "delete-files-id-metadata-id-id" "get-files-id-metadata-id-id" "post-files-id-metadata-id-id" "put-files-id-metadata-id-id" "get-files-id-tasks" "get-files-id-thumbnail-id" "delete-files-id-trash" "get-files-id-trash" "post-files-id-upload-sessions" "get-files-id-versions" "post-files-id-versions-current" "delete-files-id-versions-id" "get-files-id-versions-id" "put-files-id-versions-id" "delete-files-id-watermark" "get-files-id-watermark" "put-files-id-watermark" "get-folder-locks" "post-folder-locks" "delete-folder-locks-id" "post-folders" "get-folders-trash-items" "delete-folders-id" "get-folders-id" "post-folders-id" "put-folders-id" "put-folders-idadd-shared-link" "get-folders-idget-shared-link" "put-folders-idremove-shared-link" "put-folders-idupdate-shared-link" "get-folders-id-collaborations" "post-folders-id-copy" "get-folders-id-items" "get-folders-id-metadata" "delete-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "get-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "post-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "put-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" "delete-folders-id-metadata-id-id" "get-folders-id-metadata-id-id" "post-folders-id-metadata-id-id" "put-folders-id-metadata-id-id" "delete-folders-id-trash" "get-folders-id-trash" "delete-folders-id-watermark" "get-folders-id-watermark" "put-folders-id-watermark" "post-group-memberships" "delete-group-memberships-id" "get-group-memberships-id" "put-group-memberships-id" "get-groups" "post-groups" "post-groups-terminate-sessions" "delete-groups-id" "get-groups-id" "put-groups-id" "get-groups-id-collaborations" "get-groups-id-memberships" "post-invites" "get-invites-id" "get-legal-hold-policies" "post-legal-hold-policies" "delete-legal-hold-policies-id" "get-legal-hold-policies-id" "put-legal-hold-policies-id" "get-legal-hold-policy-assignments" "post-legal-hold-policy-assignments" "delete-legal-hold-policy-assignments-id" "get-legal-hold-policy-assignments-id" "get-legal-hold-policy-assignments-id-file-versions-on-hold" "get-legal-hold-policy-assignments-id-files-on-hold" "get-metadata-cascade-policies" "post-metadata-cascade-policies" "delete-metadata-cascade-policies-id" "get-metadata-cascade-policies-id" "post-metadata-cascade-policies-id-apply" "post-metadata-queries-execute-read" "get-metadata-query-indices" "get-metadata-templates" "get-metadata-templates-enterprise" "delete-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema" "get-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema" "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaadd" "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemadelete" "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaupdate" "get-metadata-templates-global" "post-metadata-templates-schema" "post-metadata-templates-schemaclassifications" "delete-metadata-templates-id-id-schema" "get-metadata-templates-id-id-schema" "put-metadata-templates-id-id-schema" "get-metadata-templates-id" "post-oauth2-revoke" "post-oauth2-token" "post-oauth2-tokenrefresh" "get-recent-items" "get-retention-policies" "post-retention-policies" "delete-retention-policies-id" "get-retention-policies-id" "put-retention-policies-id" "get-retention-policies-id-assignments" "post-retention-policy-assignments" "delete-retention-policy-assignments-id" "get-retention-policy-assignments-id" "get-retention-policy-assignments-id-file-versions-under-retention" "get-retention-policy-assignments-id-files-under-retention" "get-search" "get-shared-items" "get-shared-itemsfolders" "get-shared-itemsweb-links" "get-shield-information-barrier-reports" "post-shield-information-barrier-reports" "get-shield-information-barrier-reports-id" "get-shield-information-barrier-segment-members" "post-shield-information-barrier-segment-members" "delete-shield-information-barrier-segment-members-id" "get-shield-information-barrier-segment-members-id" "get-shield-information-barrier-segment-restrictions" "post-shield-information-barrier-segment-restrictions" "delete-shield-information-barrier-segment-restrictions-id" "get-shield-information-barrier-segment-restrictions-id" "get-shield-information-barrier-segments" "post-shield-information-barrier-segments" "delete-shield-information-barrier-segments-id" "get-shield-information-barrier-segments-id" "put-shield-information-barrier-segments-id" "get-shield-information-barriers" "post-shield-information-barriers" "post-shield-information-barriers-change-status" "get-shield-information-barriers-id" "get-sign-requests" "post-sign-requests" "get-sign-requests-id" "post-sign-requests-id-cancel" "post-sign-requests-id-resend" "put-skill-invocations-id" "get-storage-policies" "get-storage-policies-id" "get-storage-policy-assignments" "post-storage-policy-assignments" "delete-storage-policy-assignments-id" "get-storage-policy-assignments-id" "put-storage-policy-assignments-id" "post-task-assignments" "delete-task-assignments-id" "get-task-assignments-id" "put-task-assignments-id" "post-tasks" "delete-tasks-id" "get-tasks-id" "put-tasks-id" "get-tasks-id-assignments" "get-terms-of-service-user-statuses" "post-terms-of-service-user-statuses" "put-terms-of-service-user-statuses-id" "get-terms-of-services" "post-terms-of-services" "get-terms-of-services-id" "put-terms-of-services-id" "get-users" "post-users" "get-users-me" "post-users-terminate-sessions" "delete-users-id" "get-users-id" "put-users-id" "delete-users-id-avatar" "get-users-id-avatar" "post-users-id-avatar" "get-users-id-email-aliases" "post-users-id-email-aliases" "delete-users-id-email-aliases-id" "put-users-id-folders-0" "get-users-id-memberships" "post-web-links" "delete-web-links-id" "get-web-links-id" "post-web-links-id" "put-web-links-id" "put-web-links-idadd-shared-link" "get-web-links-idget-shared-link" "put-web-links-idremove-shared-link" "put-web-links-idupdate-shared-link" "delete-web-links-id-trash" "get-web-links-id-trash" "get-webhooks" "post-webhooks" "delete-webhooks-id" "get-webhooks-id" "put-webhooks-id" "get-workflows" "post-workflows-id-start" "post-zip-downloads" "get-zip-downloads-id-content" "get-zip-downloads-id-status" "commands"] | sort) } | get name | first)
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

# Authorize user
#
# GET /authorize
# Returns: string
# operationId: get_authorize
export def "get-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string@response-type-completer # The type of response we'd like to receive. (required, format: token, e.g. code)
  --client-id: string # The Client ID of the application that is requesting to authenticate the user. To get the Client ID for your application, log in to your Box developer console and click the **Edit Application** link for the application you're working with. In the OAuth 2.0 Parameters section of the configuration page, find the item labelled `client_id`. The text of that item is your application's Client ID. (required, e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --redirect-uri: string # The URI to which Box redirects the browser after the user has granted or denied the application permission. This URI match one of the redirect URIs in the configuration of your application. It must be a valid HTTPS URI and it needs to be able to handle the redirection to complete the next step in the OAuth 2.0 flow. Although this parameter is optional, it must be a part of the authorization URL if you configured multiple redirect URIs for the application in the developer console. A missing parameter causes a `redirect_uri_missing` error after the user grants application access. (format: url, e.g. http://example.com/auth/callback)
  --state: string # A custom string of your choice. Box will pass the same string to the redirect URL when authentication is complete. This parameter can be used to identify a user on redirect, as well as protect against hijacked sessions and other exploits. (e.g. my_state)
  --scope: string # A comma-separated list of application scopes you'd like to authenticate the user for. This defaults to all the scopes configured for the application in its configuration page. (e.g. admin_readwrite)
]: nothing -> any {
  http-request {
    method: get
    path: "/authorize"
    query: [{name: response_type, var: response_type, required: true, default: code}, {name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri}, {name: state, var: state}, {name: scope, var: scope}]
    accept: ["text/html"]
    ok: [200]
    base_url: "https://account.box.com/api/oauth2"
    auth: none
  } {
    response_type: $response_type, client_id: $client_id, redirect_uri: $redirect_uri, state: $state, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List allowed collaboration domains
#
# GET /collaboration_whitelist_entries
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, direction: string, domain: string, enterprise: record, id: string, type: string>>
# operationId: get_collaboration_whitelist_entries
export def "get-collaboration-whitelist-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collaboration_whitelist_entries"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add domain to list of allowed collaboration domains
#
# POST /collaboration_whitelist_entries
# Returns: record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string>
# operationId: post_collaboration_whitelist_entries
export def "post-collaboration-whitelist-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer # The direction in which to allow collaborations. (e.g. inbound)
  domain: string # The domain to add to the list of allowed domains. (e.g. example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collaboration_whitelist_entries"
    body: {content_type: "application/json", kind: json, fields: [{name: direction, var: direction}, {name: domain, var: domain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    direction: $direction, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove domain from list of allowed collaboration domains
#
# DELETE /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# operationId: delete_collaboration_whitelist_entries_id
export def "delete-collaboration-whitelist-entries-id" [
  collaboration_whitelist_entry_id: string
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
    path: "/collaboration_whitelist_entries/{collaboration_whitelist_entry_id}"
    path_params: [{name: collaboration_whitelist_entry_id, var: collaboration_whitelist_entry_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collaboration_whitelist_entry_id: $collaboration_whitelist_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get allowed collaboration domain
#
# GET /collaboration_whitelist_entries/{collaboration_whitelist_entry_id}
# Returns: record<created_at: string, direction: string, domain: string, enterprise: record<id: string, name: string, type: string>, id: string, type: string>
# operationId: get_collaboration_whitelist_entries_id
export def "get-collaboration-whitelist-entries-id" [
  collaboration_whitelist_entry_id: string
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
    path: "/collaboration_whitelist_entries/{collaboration_whitelist_entry_id}"
    path_params: [{name: collaboration_whitelist_entry_id, var: collaboration_whitelist_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collaboration_whitelist_entry_id: $collaboration_whitelist_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users exempt from collaboration domain restrictions
#
# GET /collaboration_whitelist_exempt_targets
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, enterprise: record, id: string, modified_at: string, type: string, user: record>>
# operationId: get_collaboration_whitelist_exempt_targets
export def "get-collaboration-whitelist-exempt-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collaboration_whitelist_exempt_targets"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user exemption from collaboration domain restrictions
#
# POST /collaboration_whitelist_exempt_targets
# Returns: record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>>
# operationId: post_collaboration_whitelist_exempt_targets
export def "post-collaboration-whitelist-exempt-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # The user to exempt. — shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collaboration_whitelist_exempt_targets"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user from list of users exempt from domain restrictions
#
# DELETE /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# operationId: delete_collaboration_whitelist_exempt_targets_id
export def "delete-collaboration-whitelist-exempt-targets-id" [
  collaboration_whitelist_exempt_target_id: string
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
    path: "/collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}"
    path_params: [{name: collaboration_whitelist_exempt_target_id, var: collaboration_whitelist_exempt_target_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collaboration_whitelist_exempt_target_id: $collaboration_whitelist_exempt_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user exempt from collaboration domain restrictions
#
# GET /collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}
# Returns: record<created_at: string, enterprise: record<id: string, name: string, type: string>, id: string, modified_at: string, type: string, user: record<id: string, name: string, type: string>>
# operationId: get_collaboration_whitelist_exempt_targets_id
export def "get-collaboration-whitelist-exempt-targets-id" [
  collaboration_whitelist_exempt_target_id: string
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
    path: "/collaboration_whitelist_exempt_targets/{collaboration_whitelist_exempt_target_id}"
    path_params: [{name: collaboration_whitelist_exempt_target_id, var: collaboration_whitelist_exempt_target_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collaboration_whitelist_exempt_target_id: $collaboration_whitelist_exempt_target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pending collaborations
#
# GET /collaborations
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>
# operationId: get_collaborations
export def "get-collaborations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The status of the collaborations to retrieve (required, e.g. pending)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collaborations"
    query: [{name: status, var: status, required: true, default: pending}, {name: fields, var: fields, style: csv}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, fields: $fields, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create collaboration
#
# POST /collaborations
# Returns: record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>
# operationId: post_collaborations
export def "post-collaborations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: oneof<nothing, bool> # Determines if users should receive email notification for the action performed. (e.g. true)
  accessible_by: record # The user or group to give access to the item. — shape: {id?: string, login?: string, type: "user"|"group"}
  --can-view-path: oneof<nothing, bool> # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on. Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user. Only owner or co-owners can invite collaborators with a `can_view_path` of `true`. `can_view_path` can only be used for folder collaborations. (e.g. true)
  --expires-at: string # Set the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item. This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
  item: record # The item to attach the comment to. — shape: {id: string, type: "file"|"folder"}
  role: string@role-completer # The level of access granted. (e.g. editor)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collaborations"
    query: [{name: fields, var: fields, style: csv}, {name: notify, var: notify}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessible_by, var: accessible_by}, {name: can_view_path, var: can_view_path}, {name: expires_at, var: expires_at}, {name: item, var: item}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, notify: $notify, accessible_by: $accessible_by, can_view_path: $can_view_path, expires_at: $expires_at, item: $item, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove collaboration
#
# DELETE /collaborations/{collaboration_id}
# operationId: delete_collaborations_id
export def "delete-collaborations-id" [
  collaboration_id: string
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
    path: "/collaborations/{collaboration_id}"
    path_params: [{name: collaboration_id, var: collaboration_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    collaboration_id: $collaboration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get collaboration
#
# GET /collaborations/{collaboration_id}
# Returns: record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>
# operationId: get_collaborations_id
export def "get-collaborations-id" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collaborations/{collaboration_id}"
    path_params: [{name: collaboration_id, var: collaboration_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collaboration_id: $collaboration_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update collaboration
#
# PUT /collaborations/{collaboration_id}
# Returns: record<acceptance_requirements_status: record<strong_password_requirement: record<enterprise_has_strong_password_required_for_external_users: bool, user_has_strong_password: bool>, terms_of_service_requirement: record<is_accepted: bool, terms_of_service: record>, two_factor_authentication_requirement: record<enterprise_has_two_factor_auth_enabled: bool, user_has_two_factor_authentication_enabled: bool>>, accessible_by: record<id: string, type: string, login: string, name: string>, acknowledged_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>
# operationId: put_collaborations_id
export def "put-collaborations-id" [
  collaboration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --can-view-path: oneof<nothing, bool> # Determines if the invited users can see the entire parent path to the associated folder. The user will not gain privileges in any parent folder and therefore can not see content the user is not collaborated on. Be aware that this meaningfully increases the time required to load the invitee's **All Files** page. We recommend you limit the number of collaborations with `can_view_path` enabled to 1,000 per user. Only owner or co-owners can invite collaborators with a `can_view_path` of `true`. `can_view_path` can only be used for folder collaborations. (e.g. true)
  --expires-at: string # Update the expiration date for the collaboration. At this date, the collaboration will be automatically removed from the item. This feature will only work if the **Automatically remove invited collaborators: Allow folder owners to extend the expiry date** setting has been enabled in the **Enterprise Settings** of the **Admin Console**. When the setting is not enabled, collaborations can not have an expiry date and a value for this field will be result in an error. Additionally, a collaboration can only be given an expiration if it was created after the **Automatically remove invited collaborator** setting was enabled. (format: date-time, e.g. 2019-08-29T23:59:00-07:00)
  role: string@role-completer-1 # The level of access granted. (e.g. editor)
  --status: string@status-completer-1 # Set the status of a `pending` collaboration invitation, effectively accepting, or rejecting the invite. (e.g. accepted)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/collaborations/{collaboration_id}"
    path_params: [{name: collaboration_id, var: collaboration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: can_view_path, var: can_view_path}, {name: expires_at, var: expires_at}, {name: role, var: role}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    collaboration_id: $collaboration_id, can_view_path: $can_view_path, expires_at: $expires_at, role: $role, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all collections
#
# GET /collections
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<collection_type: string, id: string, name: string, type: string>>
# operationId: get_collections
export def "get-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collections"
    query: [{name: fields, var: fields, style: csv}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collection items
#
# GET /collections/{collection_id}/items
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>
# operationId: get_collections_id_items
export def "get-collections-id-items" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collections/{collection_id}/items"
    path_params: [{name: collection_id, var: collection_id}]
    query: [{name: fields, var: fields, style: csv}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    collection_id: $collection_id, fields: $fields, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create comment
#
# POST /comments
# Returns: record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>
# operationId: post_comments
export def "post-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --item: record # The item to attach the comment to. — shape: {id: string, type: "file"|"comment"}
  message: string # The text of the comment. To mention a user, use the `tagged_message` parameter instead. (e.g. Review completed!)
  --tagged-message: string # The text of the comment, including `@[user_id:name]` somewhere in the message to mention another user, which will send them an email notification, letting them know they have been mentioned. The `user_id` is the target user's ID, where the `name` can be any custom phrase. In the Box UI this name will link to the user's profile. If you are not mentioning another user, use `message` instead. (e.g. @[1234:John] Review completed!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/comments"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: item, var: item}, {name: message, var: message}, {name: tagged_message, var: tagged_message}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, item: $item, message: $message, tagged_message: $tagged_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove comment
#
# DELETE /comments/{comment_id}
# operationId: delete_comments_id
export def "delete-comments-id" [
  comment_id: string
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
    path: "/comments/{comment_id}"
    path_params: [{name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get comment
#
# GET /comments/{comment_id}
# Returns: record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>
# operationId: get_comments_id
export def "get-comments-id" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/comments/{comment_id}"
    path_params: [{name: comment_id, var: comment_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update comment
#
# PUT /comments/{comment_id}
# Returns: record<id: string, type: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, is_reply_comment: bool, item: record<id: string, type: string>, message: string, modified_at: string>
# operationId: put_comments_id
export def "put-comments-id" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --message: string # The text of the comment to update (e.g. Review completed!)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/comments/{comment_id}"
    path_params: [{name: comment_id, var: comment_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, fields: $fields, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove device pin
#
# DELETE /device_pinners/{device_pinner_id}
# operationId: delete_device_pinners_id
export def "delete-device-pinners-id" [
  device_pinner_id: string
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
    path: "/device_pinners/{device_pinner_id}"
    path_params: [{name: device_pinner_id, var: device_pinner_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_pinner_id: $device_pinner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get device pin
#
# GET /device_pinners/{device_pinner_id}
# Returns: record<id: string, owned_by: record<id: string, type: string, login: string, name: string>, product_name: string, type: string>
# operationId: get_device_pinners_id
export def "get-device-pinners-id" [
  device_pinner_id: string
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
    path: "/device_pinners/{device_pinner_id}"
    path_params: [{name: device_pinner_id, var: device_pinner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_pinner_id: $device_pinner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List enterprise device pins
#
# GET /enterprises/{enterprise_id}/device_pinners
# Returns: record<entries: table<id: string, owned_by: record, product_name: string, type: string>, limit: int, next_marker: int, order: table<by: string, direction: string>>
# operationId: get_enterprises_id_device_pinners
export def "get-enterprises-id-device-pinners" [
  enterprise_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/enterprises/{enterprise_id}/device_pinners"
    path_params: [{name: enterprise_id, var: enterprise_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    enterprise_id: $enterprise_id, marker: $marker, limit: $limit, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user and enterprise events
#
# GET /events
# Returns: record<chunk_size: int, entries: table<additional_details: record, created_at: string, created_by: record, event_id: string, event_type: string, recorded_at: string, session_id: string, source: record, type: string>, next_stream_position: string>
# operationId: get_events
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream-type: string@stream-type-completer # Defines the type of events that are returned * `all` returns everything for a user and is the default * `changes` returns events that may cause file tree changes such as file updates or collaborations. * `sync` is similar to `changes` but only applies to synced folders * `admin_logs` returns all events for an entire enterprise and requires the user making the API call to have admin permissions. This stream type is for programmatically pulling from a 1 year history of events across all users within the enterprise and within a `created_after` and `created_before` time frame. The complete history of events will be returned in chronological order based on the event time, but latency will be much higher than `admin_logs_streaming`. * `admin_logs_streaming` returns all events for an entire enterprise and requires the user making the API call to have admin permissions. This stream type is for polling for recent events across all users within the enterprise. Latency will be much lower than `admin_logs`, but events will not be returned in chronological order and may contain duplicates. (default: all, e.g. all)
  --stream-position: string # The location in the event stream to start receiving events from. * `now` will return an empty list events and the latest stream position for initialization. * `0` or `null` will return all events. (e.g. 1348790499819)
  --limit: int # Limits the number of events returned Note: Sometimes, the events less than the limit requested can be returned even when there may be more events remaining. This is primarily done in the case where a number of events have already been retrieved and these retrieved events are returned rather than delaying for an unknown amount of time to see if there are any more results. (format: int64, default: 100, e.g. 50)
  --event-type: list<string> # A comma-separated list of events to filter by. This can only be used when requesting the events with a `stream_type` of `admin_logs` or `adming_logs_streaming`. For any other `stream_type` this value will be ignored. (e.g. [ACCESS_GRANTED])
  --created-after: string # The lower bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --created-before: string # The upper bound date and time to return events for. This can only be used when requesting the events with a `stream_type` of `admin_logs`. For any other `stream_type` this value will be ignored. (format: date-time, e.g. 2013-12-12T10:53:43-08:00)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: stream_type, var: stream_type}, {name: stream_position, var: stream_position}, {name: limit, var: limit}, {name: event_type, var: event_type, style: csv}, {name: created_after, var: created_after}, {name: created_before, var: created_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_type: $stream_type, stream_position: $stream_position, limit: $limit, event_type: $event_type, created_after: $created_after, created_before: $created_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events long poll endpoint
#
# OPTIONS /events
# Returns: record
# operationId: options_events
export def "options-events" [
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
    method: options
    path: "/events"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file request
#
# DELETE /file_requests/{file_request_id}
# operationId: delete_file_requests_id
export def "delete-file-requests-id" [
  file_request_id: string
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
    path: "/file_requests/{file_request_id}"
    path_params: [{name: file_request_id, var: file_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_request_id: $file_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file request
#
# GET /file_requests/{file_request_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>
# operationId: get_file_requests_id
export def "get-file-requests-id" [
  file_request_id: string
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
    path: "/file_requests/{file_request_id}"
    path_params: [{name: file_request_id, var: file_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_request_id: $file_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update file request
#
# PUT /file_requests/{file_request_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>
# operationId: put_file_requests_id
export def "put-file-requests-id" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --description: string # An optional new description for the file request. This can be used to change the description of the file request. This will default to the value on the existing file request. (e.g. Please upload required documents)
  --expires-at: string # The date after which a file request will no longer accept new submissions. After this date, the `status` will automatically be set to `inactive`. This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
  --is-description-required: oneof<nothing, bool> # Whether a file request submitter is required to provide a description of the files they are submitting. When this setting is set to true, the Box UI will show a description field on the file request form. This will default to the value on the existing file request. (e.g. true)
  --is-email-required: oneof<nothing, bool> # Whether a file request submitter is required to provide their email address. When this setting is set to true, the Box UI will show an email field on the file request form. This will default to the value on the existing file request. (e.g. true)
  --status: string@status-completer-2 # An optional new status of the file request. When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code. This will default to the value on the existing file request. (e.g. active)
  --title: string # An optional new title for the file request. This can be used to change the title of the file request. This will default to the value on the existing file request. (e.g. Please upload required documents)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/file_requests/{file_request_id}"
    path_params: [{name: file_request_id, var: file_request_id}]
    header: [{name: if-match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: is_description_required, var: is_description_required}, {name: is_email_required, var: is_email_required}, {name: status, var: status}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_request_id: $file_request_id, if_match: $if_match, description: $description, expires_at: $expires_at, is_description_required: $is_description_required, is_email_required: $is_email_required, status: $status, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy file request
#
# POST /file_requests/{file_request_id}/copy
# Returns: record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, expires_at: string, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, is_description_required: bool, is_email_required: bool, status: string, title: string, type: string, updated_at: string, updated_by: record<id: string, type: string, login: string, name: string>, url: string>
# operationId: post_file_requests_id_copy
export def "post-file-requests-id-copy" [
  file_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional new description for the file request. This can be used to change the description of the file request. This will default to the value on the existing file request. (e.g. Please upload required documents)
  --expires-at: string # The date after which a file request will no longer accept new submissions. After this date, the `status` will automatically be set to `inactive`. This will default to the value on the existing file request. (format: date-time, e.g. 2020-09-28T10:53:43-08:00)
  --is-description-required: oneof<nothing, bool> # Whether a file request submitter is required to provide a description of the files they are submitting. When this setting is set to true, the Box UI will show a description field on the file request form. This will default to the value on the existing file request. (e.g. true)
  --is-email-required: oneof<nothing, bool> # Whether a file request submitter is required to provide their email address. When this setting is set to true, the Box UI will show an email field on the file request form. This will default to the value on the existing file request. (e.g. true)
  --status: string@status-completer-2 # An optional new status of the file request. When the status is set to `inactive`, the file request will no longer accept new submissions, and any visitor to the file request URL will receive a `HTTP 404` status code. This will default to the value on the existing file request. (e.g. active)
  --title: string # An optional new title for the file request. This can be used to change the title of the file request. This will default to the value on the existing file request. (e.g. Please upload required documents)
  folder: record # The folder to associate the new file request to. — shape: {id: string, type?: "folder"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/file_requests/{file_request_id}/copy"
    path_params: [{name: file_request_id, var: file_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: is_description_required, var: is_description_required}, {name: is_email_required, var: is_email_required}, {name: status, var: status}, {name: title, var: title}, {name: folder, var: folder}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_request_id: $file_request_id, description: $description, expires_at: $expires_at, is_description_required: $is_description_required, is_email_required: $is_email_required, status: $status, title: $title, folder: $folder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List file version legal holds
#
# GET /file_version_legal_holds
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>
# operationId: get_file_version_legal_holds
export def "get-file-version-legal-holds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string # The ID of the legal hold policy to get the file version legal holds for. (required, e.g. 133870)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/file_version_legal_holds"
    query: [{name: policy_id, var: policy_id, required: true}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_id: $policy_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file version legal hold
#
# GET /file_version_legal_holds/{file_version_legal_hold_id}
# Returns: record<deleted_at: string, file: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, file_version: record<id: string, type: string, sha1: string>, id: string, legal_hold_policy_assignments: table<id: string, type: string, assigned_at: string, assigned_by: record, assigned_to: record, deleted_at: string, legal_hold_policy: record>, type: string>
# operationId: get_file_version_legal_holds_id
export def "get-file-version-legal-holds-id" [
  file_version_legal_hold_id: string
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
    path: "/file_version_legal_holds/{file_version_legal_hold_id}"
    path_params: [{name: file_version_legal_hold_id, var: file_version_legal_hold_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_version_legal_hold_id: $file_version_legal_hold_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List file version retentions
#
# GET /file_version_retentions
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<applied_at: string, disposition_at: string, file: record, file_version: record, id: string, type: string, winning_retention_policy: record>>
# operationId: get_file_version_retentions
export def "get-file-version-retentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: string # Filters results by files with this ID. (e.g. 43123123)
  --file-version-id: string # Filters results by file versions with this ID. (e.g. 1)
  --policy-id: string # Filters results by the retention policy with this ID. (e.g. 982312)
  --disposition-action: string@disposition-action-completer # Filters results by the retention policy with this disposition action. (e.g. permanently_delete)
  --disposition-before: string # Filters results by files that will have their disposition come into effect before this date. (e.g. 2012-12-12T10:53:43-08:00)
  --disposition-after: string # Filters results by files that will have their disposition come into effect after this date. (e.g. 2012-12-19T10:34:23-08:00)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/file_version_retentions"
    query: [{name: file_id, var: file_id}, {name: file_version_id, var: file_version_id}, {name: policy_id, var: policy_id}, {name: disposition_action, var: disposition_action}, {name: disposition_before, var: disposition_before}, {name: disposition_after, var: disposition_after}, {name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, file_version_id: $file_version_id, policy_id: $policy_id, disposition_action: $disposition_action, disposition_before: $disposition_before, disposition_after: $disposition_after, limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get retention on file
#
# GET /file_version_retentions/{file_version_retention_id}
# Returns: record<applied_at: string, disposition_at: string, file: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, file_version: record<id: string, type: string, sha1: string>, id: string, type: string, winning_retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>>
# operationId: get_file_version_retentions_id
export def "get-file-version-retentions-id" [
  file_version_retention_id: string
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
    path: "/file_version_retentions/{file_version_retention_id}"
    path_params: [{name: file_version_retention_id, var: file_version_retention_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_version_retention_id: $file_version_retention_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preflight check before upload
#
# OPTIONS /files/content
# Returns: record
# operationId: options_files_content
export def "options-files-content" [
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
    method: options
    path: "/files/content"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /files/content
# Returns: record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>
# operationId: post_files_content
export def "post-files-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format. The `attributes` part of the body must come **before** the `file` part. Requests that do not follow this format when uploading the file will receive a HTTP `400` error with a `metadata_after_file_contents` error code. — shape: {content_created_at?: string, content_modified_at?: string, name: string, parent: record}
  file: string # The content of the file to upload to Box. The `attributes` part of the body must come **before** the `file` part. Requests that do not follow this format when uploading the file will receive a HTTP `400` error with a `metadata_after_file_contents` error code. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/content"
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: content-md5, var: content_md5}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attributes, var: attributes}, {name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    fields: $fields, content_md5: $content_md5, attributes: $attributes, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create upload session
#
# POST /files/upload_sessions
# Returns: record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>
# operationId: post_files_upload_sessions
export def "post-files-upload-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string # The name of new file (e.g. Project.mov)
  file_size: int # The total number of bytes of the file to be uploaded (format: int64, e.g. 104857600)
  folder_id: string # The ID of the folder to upload the new file to. (e.g. 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/upload_sessions"
    body: {content_type: "application/json", kind: json, fields: [{name: file_name, var: file_name}, {name: file_size, var: file_size}, {name: folder_id, var: folder_id}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    file_name: $file_name, file_size: $file_size, folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove upload session
#
# DELETE /files/upload_sessions/{upload_session_id}
# operationId: delete_files_upload_sessions_id
export def "delete-files-upload-sessions-id" [
  upload_session_id: string
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
    path: "/files/upload_sessions/{upload_session_id}"
    path_params: [{name: upload_session_id, var: upload_session_id}]
    accept: ["application/json"]
    ok: [204]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    upload_session_id: $upload_session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upload session
#
# GET /files/upload_sessions/{upload_session_id}
# Returns: record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>
# operationId: get_files_upload_sessions_id
export def "get-files-upload-sessions-id" [
  upload_session_id: string
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
    path: "/files/upload_sessions/{upload_session_id}"
    path_params: [{name: upload_session_id, var: upload_session_id}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    upload_session_id: $upload_session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload part of file
#
# PUT /files/upload_sessions/{upload_session_id}
# Returns: record<part: record<offset: int, part_id: string, size: int, sha1: string>>
# operationId: put_files_upload_sessions_id
export def "put-files-upload-sessions-id" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # The [RFC3230][1] message digest of the chunk uploaded. Only SHA1 is supported. The SHA1 digest must be base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`. To get the value for the `SHA` digest, use the openSSL command to encode the file part: `openssl sha1 -binary <FILE_PART_NAME> | base64` [1]: https://tools.ietf.org/html/rfc3230 (required, e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --content-range: string # The byte range of the chunk. Must not overlap with the range of a part already uploaded this session. Each part’s size must be exactly equal in size to the part size specified in the upload session that you created. One exception is the last part of the file, as this can be smaller. When providing the value for `content-range`, remember that: * The lower bound of each part's byte range must be a multiple of the part size. * The higher bound must be a multiple of the part size - 1. (required, e.g. bytes 8388608-16777215/445856194)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/upload_sessions/{upload_session_id}"
    path_params: [{name: upload_session_id, var: upload_session_id}]
    header: [{name: digest, var: digest, required: true}, {name: content-range, var: content_range, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    upload_session_id: $upload_session_id, digest: $digest, content_range: $content_range, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit upload session
#
# POST /files/upload_sessions/{upload_session_id}/commit
# Returns: record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>
# operationId: post_files_upload_sessions_id_commit
export def "post-files-upload-sessions-id-commit" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # The [RFC3230][1] message digest of the whole file. Only SHA1 is supported. The SHA1 digest must be Base64 encoded. The format of this header is as `sha=BASE64_ENCODED_DIGEST`. [1]: https://tools.ietf.org/html/rfc3230 (required, e.g. sha=fpRyg5eVQletdZqEKaFlqwBXJzM=)
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  parts: list # The list details for the uploaded parts — item shape: {offset?: int, part_id?: string, size?: int, sha1?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/upload_sessions/{upload_session_id}/commit"
    path_params: [{name: upload_session_id, var: upload_session_id}]
    header: [{name: digest, var: digest, required: true}, {name: if-match, var: if_match}, {name: if-none-match, var: if_none_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: parts, var: parts}]}
    accept: ["application/json"]
    ok: [201, 202]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    upload_session_id: $upload_session_id, digest: $digest, if_match: $if_match, if_none_match: $if_none_match, parts: $parts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List parts
#
# GET /files/upload_sessions/{upload_session_id}/parts
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<offset: int, part_id: string, size: int, sha1: string>>
# operationId: get_files_upload_sessions_id_parts
export def "get-files-upload-sessions-id-parts" [
  upload_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/upload_sessions/{upload_session_id}/parts"
    path_params: [{name: upload_session_id, var: upload_session_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    upload_session_id: $upload_session_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file
#
# DELETE /files/{file_id}
# operationId: delete_files_id
export def "delete-files-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    header: [{name: if-match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file information
#
# GET /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_files_id
export def "get-files-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item. This header can be used to access items that have not been explicitly shared with a user. Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`. This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
  --x-rep-hints: string # A header required to request specific `representations` of a file. Use this in combination with the `fields` query parameter to request a specific file representation. The general format for these representations is `X-Rep-Hints: [...]` where `[...]` is one or many hints in the format `[fileType?query]`. For example, to request a `png` representation in `32x32` as well as `64x64` pixel dimensions provide the following hints. `x-rep-hints: [jpg?dimensions=32x32][jpg?dimensions=64x64]` Additionally, a `text` representation is available for all document file types in Box using the `[extracted_text]` representation. `x-rep-hints: [extracted_text]` (required, nullable, e.g. [pdf])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-none-match, var: if_none_match}, {name: boxapi, var: boxapi}, {name: x-rep-hints, var: x_rep_hints, required: true}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, if_none_match: $if_none_match, boxapi: $boxapi, x_rep_hints: $x_rep_hints
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore file
#
# POST /files/{file_id}
# Returns: record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, file_version: record<id: string, type: string, sha1: string>, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, sha1: string, shared_link: string, size: int, trashed_at: string, type: string>
# operationId: post_files_id
export def "post-files-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the file. (e.g. Restored.docx)
  --parent: record # The parent for this item — shape: {id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update file
#
# PUT /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_files_id
export def "put-files-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --description: string # The description for a file. This can be seen in the right-hand sidebar panel when viewing a file in the Box web app. Additionally, this index is used in the search index of the file, allowing users to find the file by the content in the description. (e.g. The latest reports. Automatically updated)
  --disposition-at: string # The retention expiration timestamp for the given file. This date cannot be shortened once set on a file. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --lock: record # Defines a lock on an item. This prevents the item from being moved, renamed, or otherwise changed by anyone other than the user who created the lock. Set this to `null` to remove the lock. — shape: {access?: "lock", expires_at?: string, is_download_prevented?: bool}
  --name: string # An optional different name for the file. This can be used to rename the file. (e.g. NewFile.txt)
  --parent: record # The parent for this item — shape: {id?: string}
  --permissions: record # Defines who can download a file. — shape: {can_download?: "open"|"company"}
  --shared-link: record # Defines a shared link for an item. Set this to `null` to remove the shared link. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
  --tags: list<string> # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item. To add or remove a tag, retrieve the item's current tags, modify them, and then update this field. There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: disposition_at, var: disposition_at}, {name: lock, var: lock}, {name: name, var: name}, {name: parent, var: parent}, {name: permissions, var: permissions}, {name: shared_link, var: shared_link}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, if_match: $if_match, description: $description, disposition_at: $disposition_at, lock: $lock, name: $name, parent: $parent, permissions: $permissions, shared_link: $shared_link, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add shared link to file
#
# PUT /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_files_id#add_shared_link
export def "put-files-idadd-shared-link" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the file. Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared link for file
#
# GET /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_files_id#get_shared_link
export def "get-files-idget-shared-link" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove shared link from file
#
# PUT /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_files_id#remove_shared_link
export def "put-files-idremove-shared-link" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the file. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update shared link on file
#
# PUT /files/{file_id}
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_files_id#update_shared_link
export def "put-files-idupdate-shared-link" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List file collaborations
#
# GET /files/{file_id}/collaborations
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>
# operationId: get_files_id_collaborations
export def "get-files-id-collaborations" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/collaborations"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List file comments
#
# GET /files/{file_id}/comments
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, created_at: string, created_by: record, is_reply_comment: bool, item: record, message: string, modified_at: string>>
# operationId: get_files_id_comments
export def "get-files-id-comments" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/comments"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file
#
# GET /files/{file_id}/content
# operationId: get_files_id_content
export def "get-files-id-content" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The file version to download (e.g. 4)
  --access-token: string # An optional access token that can be used to pre-authenticate this request, which means that a download link can be shared with a browser or a third party service without them needing to know how to handle the authentication. When using this parameter, please make sure that the access token is sufficiently scoped down to only allow read access to that file and no other files or folders. (e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --range: string # The byte range of the content to download. The format `bytes={start_byte}-{end_byte}` can be used to specify what section of the file to download. (e.g. bytes=0-1024)
  --boxapi: string # The URL, and optional password, for the shared link of this item. This header can be used to access items that have not been explicitly shared with a user. Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`. This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> any {
  http-request {
    method: get
    path: "/files/{file_id}/content"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: version, var: version}, {name: access_token, var: access_token}]
    header: [{name: range, var: range}, {name: boxapi, var: boxapi}]
    accept: ["application/json"]
    ok: [202, 302]
    auth: bearer
  } {
    file_id: $file_id, version: $version, access_token: $access_token, range: $range, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file version
#
# POST /files/{file_id}/content
# Returns: record<entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record, description: string, item_status: string, modified_at: string, modified_by: record, owned_by: record, parent: record, path_collection: record, purged_at: string, shared_link: record, size: int, trashed_at: string>, total_count: int>
# operationId: post_files_id_content
export def "post-files-id-content" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --content-md5: string # An optional header containing the SHA1 hash of the file to ensure that the file was not corrupted in transit. (e.g. 134b65991ed521fcfe4724b7d814ab8ded5185dc)
  attributes: record # The additional attributes of the file being uploaded. Mainly the name and the parent folder. These attributes are part of the multi part request body and are in JSON format. The `attributes` part of the body must come **before** the `file` part. Requests that do not follow this format when uploading the file will receive a HTTP `400` error with a `metadata_after_file_contents` error code. — shape: {content_modified_at?: string, name: string}
  file: string # The content of the file to upload to Box. The `attributes` part of the body must come **before** the `file` part. Requests that do not follow this format when uploading the file will receive a HTTP `400` error with a `metadata_after_file_contents` error code. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/content"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-match, var: if_match}, {name: content-md5, var: content_md5}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: attributes, var: attributes}, {name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, if_match: $if_match, content_md5: $content_md5, attributes: $attributes, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy file
#
# POST /files/{file_id}/copy
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: post_files_id_copy
export def "post-files-id-copy" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied file. There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), and protected names like `.` and `..` are automatically sanitized by removing the non-allowed characters. (e.g. FileCopy.txt)
  parent: record # The destination folder to copy the file to. — shape: {id: string}
  --version: string # An optional ID of the specific file version to copy. (e.g. 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/copy"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201, 304]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, name: $name, parent: $parent, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata instances on file
#
# GET /files/{file_id}/metadata
# Returns: record<entries: table<"$parent": string, "$scope": string, "$template": string, "$version": int>, limit: int>
# operationId: get_files_id_metadata
export def "get-files-id-metadata" [
  file_id: string
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
    path: "/files/{file_id}/metadata"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove classification from file
#
# DELETE /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "delete-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  file_id: string
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
    path: "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get classification on file
#
# GET /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: get_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "get-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  file_id: string
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
    path: "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add classification to file
#
# POST /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: post_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "post-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box-security-classification-key: string # The name of the classification to apply to this file. To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](e://get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Box__Security__Classification__Key, var: box_security_classification_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, box_security_classification_key: $box_security_classification_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update classification on file
#
# PUT /files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: put_files_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "put-files-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  file_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Box Skill cards from file
#
# DELETE /files/{file_id}/metadata/global/boxSkillsCards
# operationId: delete_files_id_metadata_global_boxSkillsCards
export def "delete-files-id-metadata-global-box-skills-cards" [
  file_id: string
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
    path: "/files/{file_id}/metadata/global/boxSkillsCards"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Box Skill cards on file
#
# GET /files/{file_id}/metadata/global/boxSkillsCards
# Returns: record<"$canEdit": bool, "$id": string, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": int, "$version": int, cards: list<any>>
# operationId: get_files_id_metadata_global_boxSkillsCards
export def "get-files-id-metadata-global-box-skills-cards" [
  file_id: string
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
    path: "/files/{file_id}/metadata/global/boxSkillsCards"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Box Skill cards on file
#
# POST /files/{file_id}/metadata/global/boxSkillsCards
# Returns: record<"$canEdit": bool, "$id": string, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": int, "$version": int, cards: list<any>>
# operationId: post_files_id_metadata_global_boxSkillsCards
export def "post-files-id-metadata-global-box-skills-cards" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cards: list # A list of Box Skill cards to apply to this file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/metadata/global/boxSkillsCards"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cards, var: cards}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, cards: $cards
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Box Skill cards on file
#
# PUT /files/{file_id}/metadata/global/boxSkillsCards
# Returns: record<"$canEdit": bool, "$id": string, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": int, "$version": int, cards: list<any>>
# operationId: put_files_id_metadata_global_boxSkillsCards
export def "put-files-id-metadata-global-box-skills-cards" [
  file_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}/metadata/global/boxSkillsCards"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove metadata instance from file
#
# DELETE /files/{file_id}/metadata/{scope}/{template_key}
# operationId: delete_files_id_metadata_id_id
export def "delete-files-id-metadata-id-id" [
  file_id: string
  scope: string@scope-completer
  template_key: string
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
    path: "/files/{file_id}/metadata/{scope}/{template_key}"
    path_params: [{name: file_id, var: file_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata instance on file
#
# GET /files/{file_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: get_files_id_metadata_id_id
export def "get-files-id-metadata-id-id" [
  file_id: string
  scope: string@scope-completer
  template_key: string
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
    path: "/files/{file_id}/metadata/{scope}/{template_key}"
    path_params: [{name: file_id, var: file_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create metadata instance on file
#
# POST /files/{file_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: post_files_id_metadata_id_id
export def "post-files-id-metadata-id-id" [
  file_id: string
  scope: string@scope-completer
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/metadata/{scope}/{template_key}"
    path_params: [{name: file_id, var: file_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, scope: $scope, template_key: $template_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update metadata instance on file
#
# PUT /files/{file_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: put_files_id_metadata_id_id
export def "put-files-id-metadata-id-id" [
  file_id: string
  scope: string@scope-completer
  template_key: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}/metadata/{scope}/{template_key}"
    path_params: [{name: file_id, var: file_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, scope: $scope, template_key: $template_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tasks on file
#
# GET /files/{file_id}/tasks
# Returns: record<entries: table<action: string, completion_rule: string, created_at: string, created_by: record, due_at: string, id: string, is_completed: bool, item: record, message: string, task_assignment_collection: record, type: string>, total_count: int>
# operationId: get_files_id_tasks
export def "get-files-id-tasks" [
  file_id: string
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
    path: "/files/{file_id}/tasks"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file thumbnail
#
# GET /files/{file_id}/thumbnail.{extension}
# Returns: binary
# operationId: get_files_id_thumbnail_id
export def "get-files-id-thumbnail-id" [
  file_id: string
  extension: string@extension-completer
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
  --min-height: int # The minimum height of the thumbnail (e.g. 32)
  --min-width: int # The minimum width of the thumbnail (e.g. 32)
  --max-height: int # The maximum height of the thumbnail (e.g. 320)
  --max-width: int # The maximum width of the thumbnail (e.g. 320)
]: nothing -> any {
  http-request {
    method: get
    path: "/files/{file_id}/thumbnail.{extension}"
    path_params: [{name: file_id, var: file_id}, {name: extension, var: extension}]
    query: [{name: min_height, var: min_height}, {name: min_width, var: min_width}, {name: max_height, var: max_height}, {name: max_width, var: max_width}]
    accept: ["image/jpg", "image/png", "application/json"]
    ok: [200, 202, 302]
    auth: bearer
  } {
    file_id: $file_id, extension: $extension, min_height: $min_height, min_width: $min_width, max_height: $max_height, max_width: $max_width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Permanently remove file
#
# DELETE /files/{file_id}/trash
# operationId: delete_files_id_trash
export def "delete-files-id-trash" [
  file_id: string
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
    path: "/files/{file_id}/trash"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trashed file
#
# GET /files/{file_id}/trash
# Returns: record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, file_version: record<id: string, type: string, sha1: string>, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, sha1: string, shared_link: string, size: int, trashed_at: string, type: string>
# operationId: get_files_id_trash
export def "get-files-id-trash" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/trash"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create upload session for existing file
#
# POST /files/{file_id}/upload_sessions
# Returns: record<id: string, num_parts_processed: int, part_size: int, session_endpoints: record<abort: string, commit: string, list_parts: string, log_event: string, status: string, upload_part: string>, session_expires_at: string, total_parts: int, type: string>
# operationId: post_files_id_upload_sessions
export def "post-files-id-upload-sessions" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-name: string # The optional new name of new file (e.g. Project.mov)
  file_size: int # The total number of bytes of the file to be uploaded (format: int64, e.g. 104857600)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/upload_sessions"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file_name, var: file_name}, {name: file_size, var: file_size}]}
    accept: ["application/json"]
    ok: [201]
    base_url: "https://upload.box.com/api/2.0"
    auth: bearer
  } {
    file_id: $file_id, file_name: $file_name, file_size: $file_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all file versions
#
# GET /files/{file_id}/versions
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record, name: string, purged_at: string, restored_at: string, restored_by: record, size: int, trashed_at: string, trashed_by: record, uploader_display_name: string>>
# operationId: get_files_id_versions
export def "get-files-id-versions" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/versions"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promote file version
#
# POST /files/{file_id}/versions/current
# Returns: record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>
# operationId: post_files_id_versions_current
export def "post-files-id-versions-current" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --id: string # The file version ID (e.g. 11446498)
  --type: string@type-completer # The type to promote (e.g. file_version)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{file_id}/versions/current"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    file_id: $file_id, fields: $fields, id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove file version
#
# DELETE /files/{file_id}/versions/{file_version_id}
# operationId: delete_files_id_versions_id
export def "delete-files-id-versions-id" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{file_id}/versions/{file_version_id}"
    path_params: [{name: file_id, var: file_id}, {name: file_version_id, var: file_version_id}]
    header: [{name: if-match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id, file_version_id: $file_version_id, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file version
#
# GET /files/{file_id}/versions/{file_version_id}
# Returns: record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>
# operationId: get_files_id_versions_id
export def "get-files-id-versions-id" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{file_id}/versions/{file_version_id}"
    path_params: [{name: file_id, var: file_id}, {name: file_version_id, var: file_version_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, file_version_id: $file_version_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore file version
#
# PUT /files/{file_id}/versions/{file_version_id}
# Returns: record<id: string, type: string, sha1: string, created_at: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, purged_at: string, restored_at: string, restored_by: record<id: string, type: string, login: string, name: string>, size: int, trashed_at: string, trashed_by: record<id: string, type: string, login: string, name: string>, uploader_display_name: string>
# operationId: put_files_id_versions_id
export def "put-files-id-versions-id" [
  file_id: string
  file_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trashed-at: string # Set this to `null` to clear the date and restore the file. (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}/versions/{file_version_id}"
    path_params: [{name: file_id, var: file_id}, {name: file_version_id, var: file_version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: trashed_at, var: trashed_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, file_version_id: $file_version_id, trashed_at: $trashed_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove watermark from file
#
# DELETE /files/{file_id}/watermark
# operationId: delete_files_id_watermark
export def "delete-files-id-watermark" [
  file_id: string
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
    path: "/files/{file_id}/watermark"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watermark on file
#
# GET /files/{file_id}/watermark
# Returns: record<watermark: record<created_at: string, modified_at: string>>
# operationId: get_files_id_watermark
export def "get-files-id-watermark" [
  file_id: string
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
    path: "/files/{file_id}/watermark"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply watermark to file
#
# PUT /files/{file_id}/watermark
# Returns: record<watermark: record<created_at: string, modified_at: string>>
# operationId: put_files_id_watermark
export def "put-files-id-watermark" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  watermark: record # The watermark to imprint on the file — shape: {imprint: "default"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/{file_id}/watermark"
    path_params: [{name: file_id, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: watermark, var: watermark}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    file_id: $file_id, watermark: $watermark
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List folder locks
#
# GET /folder_locks
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<created_at: string, created_by: record, folder: record, id: string, lock_type: string, locked_operations: record, type: string>>
# operationId: get_folder_locks
export def "get-folder-locks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # The unique identifier that represent a folder. The ID for any folder can be determined by visiting this folder in the web application and copying the ID from the URL. For example, for the URL `https://*.app.box.com/folder/123` the `folder_id` is `123`. The root folder of a Box account is always represented by the ID `0`. (required, e.g. 12345)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folder_locks"
    query: [{name: folder_id, var: folder_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create folder lock
#
# POST /folder_locks
# Returns: record<created_at: string, created_by: record<id: string, type: string>, folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, id: string, lock_type: string, locked_operations: record<delete: bool, move: bool>, type: string>
# operationId: post_folder_locks
export def "post-folder-locks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  folder: record # The folder to apply the lock to. — shape: {id: string, type: string}
  --locked-operations: record # The operations to lock for the folder. If `locked_operations` is included in the request, both `move` and `delete` must also be included and both set to `true`. — shape: {delete: bool, move: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folder_locks"
    body: {content_type: "application/json", kind: json, fields: [{name: folder, var: folder}, {name: locked_operations, var: locked_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder: $folder, locked_operations: $locked_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete folder lock
#
# DELETE /folder_locks/{folder_lock_id}
# operationId: delete_folder_locks_id
export def "delete-folder-locks-id" [
  folder_lock_id: string
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
    path: "/folder_locks/{folder_lock_id}"
    path_params: [{name: folder_lock_id, var: folder_lock_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_lock_id: $folder_lock_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create folder
#
# POST /folders
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: post_folders
export def "post-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --folder-upload-email: record # The Write Folder Upload Email object — shape: {access?: "open"|"collaborators"}
  name: string # The name for the new folder. There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), as well as names with trailing spaces are prohibited. Additionally, the names `.` and `..` are not allowed either. (e.g. New Folder)
  parent: record # The parent folder to create the new folder within. — shape: {id: string}
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: folder_upload_email, var: folder_upload_email}, {name: name, var: name}, {name: parent, var: parent}, {name: sync_state, var: sync_state}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, folder_upload_email: $folder_upload_email, name: $name, parent: $parent, sync_state: $sync_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List trashed items
#
# GET /folders/trash/items
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>
# operationId: get_folders_trash_items
export def "get-folders-trash-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time. By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --sort: string@sort-completer # Defines the **second** attribute by which items are sorted. Items are always sorted by their `type` first, with folders listed before files, and files listed before web links. This parameter is not supported when using marker-based pagination. (e.g. id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/trash/items"
    query: [{name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: usemarker, var: usemarker}, {name: marker, var: marker}, {name: direction, var: direction}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields, limit: $limit, offset: $offset, usemarker: $usemarker, marker: $marker, direction: $direction, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete folder
#
# DELETE /folders/{folder_id}
# operationId: delete_folders_id
export def "delete-folders-id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Delete a folder that is not empty by recursively deleting the folder and all of its content. (e.g. true)
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
]: nothing -> any {
  http-request {
    method: delete
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: recursive, var: recursive}]
    header: [{name: if-match, var: if_match}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id, recursive: $recursive, if_match: $if_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get folder information
#
# GET /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_folders_id
export def "get-folders-id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # The URL, and optional password, for the shared link of this item. This header can be used to access items that have not been explicitly shared with a user. Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`. This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-none-match, var: if_none_match}, {name: boxapi, var: boxapi}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, if_none_match: $if_none_match, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore folder
#
# POST /folders/{folder_id}
# Returns: record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, size: int, trashed_at: string, type: string>
# operationId: post_folders_id
export def "post-folders-id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the folder. (e.g. Restored Photos)
  --parent: record # The parent for this item — shape: {id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update folder
#
# PUT /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_folders_id
export def "put-folders-id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-match: string # Ensures this item hasn't recently changed before making changes. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `412 Precondition Failed` if it has changed since. (e.g. 1)
  --can-non-owners-invite: oneof<nothing, bool> # Specifies if users who are not the owner of the folder can invite new collaborators to the folder. (e.g. true)
  --can-non-owners-view-collaborators: oneof<nothing, bool> # Restricts collaborators who are not the owner of this folder from viewing other collaborations on this folder. It also restricts non-owners from inviting new collaborators. When setting this field to `false`, it is required to also set `can_non_owners_invite_collaborators` to `false` if it has not already been set. (e.g. true)
  --collections: list # An array of collections to make this folder a member of. Currently we only support the `favorites` collection. To get the ID for a collection, use the [List all collections][1] endpoint. Passing an empty array `[]` or `null` will remove the folder from all collections. [1]: ../advanced-files-and-folders/#get-collections — item shape: {id?: string, type?: string}
  --description: string # The optional description of this folder (e.g. Legal contracts for the new ACME deal)
  --folder-upload-email: record # The Write Folder Upload Email object — shape: {access?: "open"|"collaborators"}
  --is-collaboration-restricted-to-enterprise: oneof<nothing, bool> # Specifies if new invites to this folder are restricted to users within the enterprise. This does not affect existing collaborations. (e.g. true)
  --name: string # The optional new name for this folder. (e.g. New Folder)
  --parent: record # The parent folder for this folder. Use this to move the folder or to restore it out of the trash. — shape: {id?: string}
  --shared-link: record # Defines a shared link for an item. Set this to `null` to remove the shared link. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
  --sync-state: string@sync-state-completer # Specifies whether a folder should be synced to a user's device or not. This is used by Box Sync (discontinued) and is not used by Box Drive. (e.g. synced)
  --tags: list<string> # The tags for this item. These tags are shown in the Box web app and mobile apps next to an item. To add or remove a tag, retrieve the item's current tags, modify them, and then update this field. There is a limit of 100 tags per item, and 10,000 unique tags per enterprise. (e.g. [approved])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-match, var: if_match}]
    body: {content_type: "application/json", kind: json, fields: [{name: can_non_owners_invite, var: can_non_owners_invite}, {name: can_non_owners_view_collaborators, var: can_non_owners_view_collaborators}, {name: collections, var: collections}, {name: description, var: description}, {name: folder_upload_email, var: folder_upload_email}, {name: is_collaboration_restricted_to_enterprise, var: is_collaboration_restricted_to_enterprise}, {name: name, var: name}, {name: parent, var: parent}, {name: shared_link, var: shared_link}, {name: sync_state, var: sync_state}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, if_match: $if_match, can_non_owners_invite: $can_non_owners_invite, can_non_owners_view_collaborators: $can_non_owners_view_collaborators, collections: $collections, description: $description, folder_upload_email: $folder_upload_email, is_collaboration_restricted_to_enterprise: $is_collaboration_restricted_to_enterprise, name: $name, parent: $parent, shared_link: $shared_link, sync_state: $sync_state, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add shared link to folder
#
# PUT /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_folders_id#add_shared_link
export def "put-folders-idadd-shared-link" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the folder. Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared link for folder
#
# GET /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_folders_id#get_shared_link
export def "get-folders-idget-shared-link" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove shared link from folder
#
# PUT /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_folders_id#remove_shared_link
export def "put-folders-idremove-shared-link" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the folder. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update shared link on folder
#
# PUT /folders/{folder_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_folders_id#update_shared_link
export def "put-folders-idupdate-shared-link" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List folder collaborations
#
# GET /folders/{folder_id}/collaborations
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>
# operationId: get_folders_id_collaborations
export def "get-folders-id-collaborations" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{folder_id}/collaborations"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy folder
#
# POST /folders/{folder_id}/copy
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: post_folders_id_copy
export def "post-folders-id-copy" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the copied folder. There are some restrictions to the file name. Names containing non-printable ASCII characters, forward and backward slashes (`/`, `\`), as well as names with trailing spaces are prohibited. Additionally, the names `.` and `..` are not allowed either. (e.g. New Folder)
  parent: record # The destination folder to copy the folder to. — shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}/copy"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201, 304]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List items in folder
#
# GET /folders/{folder_id}/items
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: list<any>>
# operationId: get_folders_id_items
export def "get-folders-id-items" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. Additionally this field can be used to query any metadata applied to the file by specifying the `metadata` field as well as the scope and key of the template to retrieve, for example `?field=metadata.enterprise_12345.contractTemplate`. (e.g. [id, type, name])
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time. By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --sort: string@sort-completer # Defines the **second** attribute by which items are sorted. Items are always sorted by their `type` first, with folders listed before files, and files listed before web links. This parameter is not supported for marker-based pagination on the root folder (the folder with an ID of `0`). (e.g. id)
  --direction: string@direction-completer-1 # The direction to sort results in. This can be either in alphabetical ascending (`ASC`) or descending (`DESC`) order. (e.g. ASC)
  --boxapi: string # The URL, and optional password, for the shared link of this item. This header can be used to access items that have not been explicitly shared with a user. Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`. This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{folder_id}/items"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}, {name: usemarker, var: usemarker}, {name: marker, var: marker}, {name: offset, var: offset}, {name: limit, var: limit}, {name: sort, var: sort}, {name: direction, var: direction}]
    header: [{name: boxapi, var: boxapi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields, usemarker: $usemarker, marker: $marker, offset: $offset, limit: $limit, sort: $sort, direction: $direction, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata instances on folder
#
# GET /folders/{folder_id}/metadata
# Returns: record<entries: table<"$parent": string, "$scope": string, "$template": string, "$version": int>, limit: int>
# operationId: get_folders_id_metadata
export def "get-folders-id-metadata" [
  folder_id: string
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
    path: "/folders/{folder_id}/metadata"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove classification from folder
#
# DELETE /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# operationId: delete_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "delete-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  folder_id: string
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
    path: "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get classification on folder
#
# GET /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: get_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "get-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  folder_id: string
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
    path: "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add classification to folder
#
# POST /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: post_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "post-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --box-security-classification-key: string # The name of the classification to apply to this folder. To list the available classifications in an enterprise, use the classification API to retrieve the [classification template](e://get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema) which lists all available classification keys. (e.g. Sensitive)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: folder_id, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Box__Security__Classification__Key, var: box_security_classification_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id, box_security_classification_key: $box_security_classification_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update classification on folder
#
# PUT /folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo
# Returns: record<"$canEdit": bool, "$parent": string, "$scope": string, "$template": string, "$type": string, "$typeVersion": float, "$version": int, Box__Security__Classification__Key: string>
# operationId: put_folders_id_metadata_enterprise_securityClassification-6VMVochwUWo
export def "put-folders-id-metadata-enterprise-security-classification-6vm-vochw-u-wo" [
  folder_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}/metadata/enterprise/securityClassification-6VMVochwUWo"
    path_params: [{name: folder_id, var: folder_id}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove metadata instance from folder
#
# DELETE /folders/{folder_id}/metadata/{scope}/{template_key}
# operationId: delete_folders_id_metadata_id_id
export def "delete-folders-id-metadata-id-id" [
  folder_id: string
  scope: string@scope-completer
  template_key: string
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
    path: "/folders/{folder_id}/metadata/{scope}/{template_key}"
    path_params: [{name: folder_id, var: folder_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata instance on folder
#
# GET /folders/{folder_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: get_folders_id_metadata_id_id
export def "get-folders-id-metadata-id-id" [
  folder_id: string
  scope: string@scope-completer
  template_key: string
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
    path: "/folders/{folder_id}/metadata/{scope}/{template_key}"
    path_params: [{name: folder_id, var: folder_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create metadata instance on folder
#
# POST /folders/{folder_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: post_folders_id_metadata_id_id
export def "post-folders-id-metadata-id-id" [
  folder_id: string
  scope: string@scope-completer
  template_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}/metadata/{scope}/{template_key}"
    path_params: [{name: folder_id, var: folder_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id, scope: $scope, template_key: $template_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update metadata instance on folder
#
# PUT /folders/{folder_id}/metadata/{scope}/{template_key}
# Returns: record<"$parent": string, "$scope": string, "$template": string, "$version": int>
# operationId: put_folders_id_metadata_id_id
export def "put-folders-id-metadata-id-id" [
  folder_id: string
  scope: string@scope-completer
  template_key: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}/metadata/{scope}/{template_key}"
    path_params: [{name: folder_id, var: folder_id}, {name: scope, var: scope}, {name: template_key, var: template_key}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, scope: $scope, template_key: $template_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently remove folder
#
# DELETE /folders/{folder_id}/trash
# operationId: delete_folders_id_trash
export def "delete-folders-id-trash" [
  folder_id: string
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
    path: "/folders/{folder_id}/trash"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trashed folder
#
# GET /folders/{folder_id}/trash
# Returns: record<content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, folder_upload_email: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, size: int, trashed_at: string, type: string>
# operationId: get_folders_id_trash
export def "get-folders-id-trash" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/folders/{folder_id}/trash"
    path_params: [{name: folder_id, var: folder_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove watermark from folder
#
# DELETE /folders/{folder_id}/watermark
# operationId: delete_folders_id_watermark
export def "delete-folders-id-watermark" [
  folder_id: string
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
    path: "/folders/{folder_id}/watermark"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watermark for folder
#
# GET /folders/{folder_id}/watermark
# Returns: record<watermark: record<created_at: string, modified_at: string>>
# operationId: get_folders_id_watermark
export def "get-folders-id-watermark" [
  folder_id: string
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
    path: "/folders/{folder_id}/watermark"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply watermark to folder
#
# PUT /folders/{folder_id}/watermark
# Returns: record<watermark: record<created_at: string, modified_at: string>>
# operationId: put_folders_id_watermark
export def "put-folders-id-watermark" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  watermark: record # The watermark to imprint on the folder — shape: {imprint: "default"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/folders/{folder_id}/watermark"
    path_params: [{name: folder_id, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: watermark, var: watermark}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    folder_id: $folder_id, watermark: $watermark
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user to group
#
# POST /group_memberships
# Returns: record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>
# operationId: post_group_memberships
export def "post-group-memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`. Setting these permissions overwrites the default access levels of an admin. Specifying a value of "null" for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (e.g. {can_run_reports: true})
  group: record # The group to add the user to. — shape: {id: string}
  --role: string@role-completer-2 # The role of the user in the group. (e.g. member)
  user: record # The user to add to the group. — shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/group_memberships"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: configurable_permissions, var: configurable_permissions}, {name: group, var: group}, {name: role, var: role}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, configurable_permissions: $configurable_permissions, group: $group, role: $role, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user from group
#
# DELETE /group_memberships/{group_membership_id}
# operationId: delete_group_memberships_id
export def "delete-group-memberships-id" [
  group_membership_id: string
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
    path: "/group_memberships/{group_membership_id}"
    path_params: [{name: group_membership_id, var: group_membership_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_membership_id: $group_membership_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group membership
#
# GET /group_memberships/{group_membership_id}
# Returns: record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>
# operationId: get_group_memberships_id
export def "get-group-memberships-id" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/group_memberships/{group_membership_id}"
    path_params: [{name: group_membership_id, var: group_membership_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_membership_id: $group_membership_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group membership
#
# PUT /group_memberships/{group_membership_id}
# Returns: record<created_at: string, group: record<id: string, type: string, group_type: string, name: string>, id: string, modified_at: string, role: string, type: string, user: record<id: string, type: string, login: string, name: string>>
# operationId: put_group_memberships_id
export def "put-group-memberships-id" [
  group_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --configurable-permissions: record # Custom configuration for the permissions an admin if a group will receive. This option has no effect on members with a role of `member`. Setting these permissions overwrites the default access levels of an admin. Specifying a value of "null" for this object will disable all configurable permissions. Specifying permissions will set them accordingly, omitted permissions will be enabled by default. (e.g. {can_run_reports: true})
  --role: string@role-completer-2 # The role of the user in the group. (e.g. member)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/group_memberships/{group_membership_id}"
    path_params: [{name: group_membership_id, var: group_membership_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: configurable_permissions, var: configurable_permissions}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_membership_id: $group_membership_id, fields: $fields, configurable_permissions: $configurable_permissions, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups for enterprise
#
# GET /groups
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, group_type: string, name: string>>
# operationId: get_groups
export def "get-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-term: string # Limits the results to only groups whose `name` starts with the search term. (e.g. Engineering)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: filter_term, var: filter_term}, {name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_term: $filter_term, fields: $fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create group
#
# POST /groups
# Returns: record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>
# operationId: post_groups
export def "post-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group. Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**. We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders. When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group. When set to `admins_and_members` all the admins listed above and group members can invite the group. When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group. * `admins_only` - the enterprise admin, co-admins, group's group admin * `admins_and_members` - all admins and group members * `all_managed_users` - all managed users in the enterprise (e.g. admins_only)
  name: string # The name of the new group to be created. This name must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`. Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application. This is desirable for one-way syncing of groups. (e.g. Active Directory)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: external_sync_identifier, var: external_sync_identifier}, {name: invitability_level, var: invitability_level}, {name: member_viewability_level, var: member_viewability_level}, {name: name, var: name}, {name: provenance, var: provenance}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, description: $description, external_sync_identifier: $external_sync_identifier, invitability_level: $invitability_level, member_viewability_level: $member_viewability_level, name: $name, provenance: $provenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create jobs to terminate user group session
#
# POST /groups/terminate_sessions
# Returns: record<message: string>
# operationId: post_groups_terminate_sessions
export def "post-groups-terminate-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: list<string> # A list of group IDs (e.g. [123456, 456789])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/terminate_sessions"
    body: {content_type: "application/json", kind: json, fields: [{name: group_ids, var: group_ids}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    group_ids: $group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove group
#
# DELETE /groups/{group_id}
# operationId: delete_groups_id
export def "delete-groups-id" [
  group_id: string
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
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group
#
# GET /groups/{group_id}
# Returns: record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>
# operationId: get_groups_id
export def "get-groups-id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group
#
# PUT /groups/{group_id}
# Returns: record<id: string, type: string, group_type: string, name: string, created_at: string, modified_at: string>
# operationId: put_groups_id
export def "put-groups-id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --description: string # A human readable description of the group. (e.g. "Customer Support Group - as imported from Active Directory")
  --external-sync-identifier: string # An arbitrary identifier that can be used by external group sync tools to link this Box Group to an external group. Example values of this field could be an **Active Directory Object ID** or a **Google Group ID**. We recommend you use of this field in order to avoid issues when group names are updated in either Box or external systems. (e.g. AD:123456)
  --invitability-level: string@invitability-level-completer # Specifies who can invite the group to collaborate on folders. When set to `admins_only` the enterprise admin, co-admins, and the group's admin can invite the group. When set to `admins_and_members` all the admins listed above and group members can invite the group. When set to `all_managed_users` all managed users in the enterprise can invite the group. (e.g. admins_only)
  --member-viewability-level: string@member-viewability-level-completer # Specifies who can see the members of the group. * `admins_only` - the enterprise admin, co-admins, group's group admin * `admins_and_members` - all admins and group members * `all_managed_users` - all managed users in the enterprise (e.g. admins_only)
  --name: string # The name of the new group to be created. Must be unique within the enterprise. (e.g. Customer Support)
  --provenance: string # Keeps track of which external source this group is coming, for example `Active Directory`, or `Okta`. Setting this will also prevent Box admins from editing the group name and its members directly via the Box web application. This is desirable for one-way syncing of groups. (e.g. Active Directory)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: external_sync_identifier, var: external_sync_identifier}, {name: invitability_level, var: invitability_level}, {name: member_viewability_level, var: member_viewability_level}, {name: name, var: name}, {name: provenance, var: provenance}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, fields: $fields, description: $description, external_sync_identifier: $external_sync_identifier, invitability_level: $invitability_level, member_viewability_level: $member_viewability_level, name: $name, provenance: $provenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List group collaborations
#
# GET /groups/{group_id}/collaborations
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<acceptance_requirements_status: record, accessible_by: record, acknowledged_at: string, created_at: string, created_by: record, expires_at: string, id: string, invite_email: string, item: record, modified_at: string, role: string, status: string, type: string>>
# operationId: get_groups_id_collaborations
export def "get-groups-id-collaborations" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/collaborations"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List members of group
#
# GET /groups/{group_id}/memberships
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record>>
# operationId: get_groups_id_memberships
export def "get-groups-id-memberships" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{group_id}/memberships"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user invite
#
# POST /invites
# Returns: record<actionable_by: record<id: string, type: string, login: string, name: string>, created_at: string, id: string, invited_by: record<id: string, type: string, login: string, name: string>, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string>
# operationId: post_invites
export def "post-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  actionable_by: record # The user to invite — shape: {login?: string}
  enterprise: record # The enterprise to invite the user to — shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invites"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionable_by, var: actionable_by}, {name: enterprise, var: enterprise}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields, actionable_by: $actionable_by, enterprise: $enterprise
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user invite status
#
# GET /invites/{invite_id}
# Returns: record<actionable_by: record<id: string, type: string, login: string, name: string>, created_at: string, id: string, invited_by: record<id: string, type: string, login: string, name: string>, invited_to: record<id: string, name: string, type: string>, modified_at: string, status: string, type: string>
# operationId: get_invites_id
export def "get-invites-id" [
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invites/{invite_id}"
    path_params: [{name: invite_id, var: invite_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invite_id: $invite_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all legal hold policies
#
# GET /legal_hold_policies
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string, assignment_counts: record, created_at: string, created_by: record, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>>
# operationId: get_legal_hold_policies
export def "get-legal-hold-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-name: string # Limits results to policies for which the names start with this search term. This is a case-insensitive prefix. (e.g. Sales Policy)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legal_hold_policies"
    query: [{name: policy_name, var: policy_name}, {name: fields, var: fields, style: csv}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, fields: $fields, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create legal hold policy
#
# POST /legal_hold_policies
# Returns: record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>
# operationId: post_legal_hold_policies
export def "post-legal-hold-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --filter-ended-at: string # The filter end date. When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter. Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-18T10:53:43-08:00)
  --filter-started-at: string # The filter start date. When this policy is applied using a `custodian` legal hold assignments, it will only apply to file versions created or uploaded inside of the date range. Other assignment types, such as folders and files, will ignore the date filter. Required if `is_ongoing` is set to `false`. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --is-ongoing: oneof<nothing, bool> # Whether new assignments under this policy should continue applying to files even after initialization. When this policy is applied using a legal hold assignment, it will continue applying the policy to any new file versions even after it has been applied. For example, if a legal hold assignment is placed on a user today, and that user uploads a file tomorrow, that file will get held. This will continue until the policy is retired. Required if no filter dates are set. (e.g. true)
  policy_name: string # The name of the policy. (e.g. Sales Policy)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_hold_policies"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: filter_ended_at, var: filter_ended_at}, {name: filter_started_at, var: filter_started_at}, {name: is_ongoing, var: is_ongoing}, {name: policy_name, var: policy_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, filter_ended_at: $filter_ended_at, filter_started_at: $filter_started_at, is_ongoing: $is_ongoing, policy_name: $policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove legal hold policy
#
# DELETE /legal_hold_policies/{legal_hold_policy_id}
# operationId: delete_legal_hold_policies_id
export def "delete-legal-hold-policies-id" [
  legal_hold_policy_id: string
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
    path: "/legal_hold_policies/{legal_hold_policy_id}"
    path_params: [{name: legal_hold_policy_id, var: legal_hold_policy_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    legal_hold_policy_id: $legal_hold_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get legal hold policy
#
# GET /legal_hold_policies/{legal_hold_policy_id}
# Returns: record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>
# operationId: get_legal_hold_policies_id
export def "get-legal-hold-policies-id" [
  legal_hold_policy_id: string
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
    path: "/legal_hold_policies/{legal_hold_policy_id}"
    path_params: [{name: legal_hold_policy_id, var: legal_hold_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_hold_policy_id: $legal_hold_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update legal hold policy
#
# PUT /legal_hold_policies/{legal_hold_policy_id}
# Returns: record<id: string, type: string, assignment_counts: record<file: int, file_version: int, folder: int, user: int>, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, deleted_at: string, description: string, filter_ended_at: string, filter_started_at: string, modified_at: string, policy_name: string, release_notes: string, status: string>
# operationId: put_legal_hold_policies_id
export def "put-legal-hold-policies-id" [
  legal_hold_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the policy. (e.g. A custom policy for the sales team)
  --policy-name: string # The name of the policy. (e.g. Sales Policy)
  --release-notes: string # Notes around why the policy was released. (e.g. Required for GDPR)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/legal_hold_policies/{legal_hold_policy_id}"
    path_params: [{name: legal_hold_policy_id, var: legal_hold_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: policy_name, var: policy_name}, {name: release_notes, var: release_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_hold_policy_id: $legal_hold_policy_id, description: $description, policy_name: $policy_name, release_notes: $release_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List legal hold policy assignments
#
# GET /legal_hold_policy_assignments
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string>>
# operationId: get_legal_hold_policy_assignments
export def "get-legal-hold-policy-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string # The ID of the legal hold policy (required, e.g. 324432)
  --assign-to-type: string@assign-to-type-completer # Filters the results by the type of item the policy was applied to. (e.g. file)
  --assign-to-id: string # Filters the results by the ID of item the policy was applied to. (e.g. 1234323)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legal_hold_policy_assignments"
    query: [{name: policy_id, var: policy_id, required: true}, {name: assign_to_type, var: assign_to_type}, {name: assign_to_id, var: assign_to_id}, {name: marker, var: marker}, {name: limit, var: limit}, {name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_id: $policy_id, assign_to_type: $assign_to_type, assign_to_id: $assign_to_id, marker: $marker, limit: $limit, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign legal hold policy
#
# POST /legal_hold_policy_assignments
# Returns: record<id: string, type: string, assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record, deleted_at: string, legal_hold_policy: record<id: string, type: string>>
# operationId: post_legal_hold_policy_assignments
export def "post-legal-hold-policy-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The item to assign the policy to — shape: {id: string, type: "file"|"file_version"|"folder"|"user"}
  policy_id: string # The ID of the policy to assign. (e.g. 123244)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legal_hold_policy_assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: assign_to, var: assign_to}, {name: policy_id, var: policy_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    assign_to: $assign_to, policy_id: $policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign legal hold policy
#
# DELETE /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# operationId: delete_legal_hold_policy_assignments_id
export def "delete-legal-hold-policy-assignments-id" [
  legal_hold_policy_assignment_id: string
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
    path: "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}"
    path_params: [{name: legal_hold_policy_assignment_id, var: legal_hold_policy_assignment_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}
# Returns: record<id: string, type: string, assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record, deleted_at: string, legal_hold_policy: record<id: string, type: string>>
# operationId: get_legal_hold_policy_assignments_id
export def "get-legal-hold-policy-assignments-id" [
  legal_hold_policy_assignment_id: string
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
    path: "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}"
    path_params: [{name: legal_hold_policy_assignment_id, var: legal_hold_policy_assignment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List previous file versions for legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/file_versions_on_hold
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>
# operationId: get_legal_hold_policy_assignments_id_file_versions_on_hold
export def "get-legal-hold-policy-assignments-id-file-versions-on-hold" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/file_versions_on_hold"
    path_params: [{name: legal_hold_policy_assignment_id, var: legal_hold_policy_assignment_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}, {name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id, marker: $marker, limit: $limit, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current file versions for legal hold policy assignment
#
# GET /legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/files_on_hold
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<deleted_at: string, file: record, file_version: record, id: string, legal_hold_policy_assignments: list, type: string>>
# operationId: get_legal_hold_policy_assignments_id_files_on_hold
export def "get-legal-hold-policy-assignments-id-files-on-hold" [
  legal_hold_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legal_hold_policy_assignments/{legal_hold_policy_assignment_id}/files_on_hold"
    path_params: [{name: legal_hold_policy_assignment_id, var: legal_hold_policy_assignment_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}, {name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    legal_hold_policy_assignment_id: $legal_hold_policy_assignment_id, marker: $marker, limit: $limit, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata cascade policies
#
# GET /metadata_cascade_policies
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, owner_enterprise: record, parent: record, scope: string, templateKey: string, type: string>>
# operationId: get_metadata_cascade_policies
export def "get-metadata-cascade-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # Specifies which folder to return policies for. This can not be used on the root folder with ID `0`. (required, e.g. 31232)
  --owner-enterprise-id: string # The ID of the enterprise ID for which to find metadata cascade policies. If not specified, it defaults to the current enterprise. (e.g. 31232)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata_cascade_policies"
    query: [{name: folder_id, var: folder_id, required: true}, {name: owner_enterprise_id, var: owner_enterprise_id}, {name: marker, var: marker}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, owner_enterprise_id: $owner_enterprise_id, marker: $marker, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create metadata cascade policy
#
# POST /metadata_cascade_policies
# Returns: record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string>
# operationId: post_metadata_cascade_policies
export def "post-metadata-cascade-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  folder_id: string # The ID of the folder to apply the policy to. This folder will need to already have an instance of the targeted metadata template applied to it. (e.g. 1234567)
  scope: string@scope-completer # The scope of the targeted metadata template. This template will need to already have an instance applied to the targeted folder. (e.g. enterprise)
  template_key: string # The key of the targeted metadata template. This template will need to already have an instance applied to the targeted folder. In many cases the template key is automatically derived of its display name, for example `Contract Template` would become `contractTemplate`. In some cases the creator of the template will have provided its own template key. Please [list the templates for an enterprise][list], or get all instances on a [file][file] or [folder][folder] to inspect a template's key. [list]: e://get-metadata-templates-enterprise [file]: e://get-files-id-metadata [folder]: e://get-folders-id-metadata (e.g. productInfo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata_cascade_policies"
    body: {content_type: "application/json", kind: json, fields: [{name: folder_id, var: folder_id}, {name: scope, var: scope}, {name: templateKey, var: template_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    folder_id: $folder_id, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove metadata cascade policy
#
# DELETE /metadata_cascade_policies/{metadata_cascade_policy_id}
# operationId: delete_metadata_cascade_policies_id
export def "delete-metadata-cascade-policies-id" [
  metadata_cascade_policy_id: string
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
    path: "/metadata_cascade_policies/{metadata_cascade_policy_id}"
    path_params: [{name: metadata_cascade_policy_id, var: metadata_cascade_policy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    metadata_cascade_policy_id: $metadata_cascade_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata cascade policy
#
# GET /metadata_cascade_policies/{metadata_cascade_policy_id}
# Returns: record<id: string, owner_enterprise: record<id: string, type: string>, parent: record<id: string, type: string>, scope: string, templateKey: string, type: string>
# operationId: get_metadata_cascade_policies_id
export def "get-metadata-cascade-policies-id" [
  metadata_cascade_policy_id: string
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
    path: "/metadata_cascade_policies/{metadata_cascade_policy_id}"
    path_params: [{name: metadata_cascade_policy_id, var: metadata_cascade_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metadata_cascade_policy_id: $metadata_cascade_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force-apply metadata cascade policy to folder
#
# POST /metadata_cascade_policies/{metadata_cascade_policy_id}/apply
# operationId: post_metadata_cascade_policies_id_apply
export def "post-metadata-cascade-policies-id-apply" [
  metadata_cascade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  conflict_resolution: string@conflict-resolution-completer # Describes the desired behavior when dealing with the conflict where a metadata template already has an instance applied to a child. * `none` will preserve the existing value on the file * `overwrite` will force-apply the templates values over any existing values. (e.g. none)
]: any -> any {
  $in | http-request {
    method: post
    path: "/metadata_cascade_policies/{metadata_cascade_policy_id}/apply"
    path_params: [{name: metadata_cascade_policy_id, var: metadata_cascade_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conflict_resolution, var: conflict_resolution}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    metadata_cascade_policy_id: $metadata_cascade_policy_id, conflict_resolution: $conflict_resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query files/folders by metadata
#
# POST /metadata_queries/execute_read
# Returns: record<entries: list<any>, limit: int, next_marker: string>
# operationId: post_metadata_queries_execute_read
export def "post-metadata-queries-execute-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ancestor_folder_id: string # The ID of the folder that you are restricting the query to. A value of zero will return results from all folders you have access to. A non-zero value will only return results found in the folder corresponding to the ID or in any of its subfolders. (e.g. 0)
  --fields: list<string> # By default, this endpoint returns only the most basic info about the items for which the query matches. This attribute can be used to specify a list of additional attributes to return for any item, including its metadata. This attribute takes a list of item fields, metadata template identifiers, or metadata template field identifiers. For example: * `created_by` will add the details of the user who created the item to the response. * `metadata..` will return the mini-representation of the metadata instance identified by the `scope` and `templateKey`. * `metadata...` will return all the mini-representation of the metadata instance identified by the `scope` and `templateKey` plus the field specified by the `field` name. Multiple fields for the same `scope` and `templateKey` can be defined. (e.g. [extension, created_at, item_status, metadata.enterprise_1234.contracts, metadata.enterprise_1234.regions.location])
  from: string # Specifies the template used in the query. Must be in the form `scope.templateKey`. Not all templates can be used in this field, most notably the built-in, Box-provided classification templates can not be used in a query. (e.g. enterprise_123456.someTemplate)
  --limit: int # A value between 0 and 100 that indicates the maximum number of results to return for a single request. This only specifies a maximum boundary and will not guarantee the minimum number of results returned. (default: 100, e.g. 50)
  --marker: string # Marker to use for requesting the next page. (e.g. AAAAAmVYB1FWec8GH6yWu2nwmanfMh07IyYInaa7DZDYjgO1H4KoLW29vPlLY173OKsci6h6xGh61gG73gnaxoS+o0BbI1/h6le6cikjlupVhASwJ2Cj0tOD9wlnrUMHHw3/ISf+uuACzrOMhN6d5fYrbidPzS6MdhJOejuYlvsg4tcBYzjauP3+VU51p77HFAIuObnJT0ff)
  --order-by: list # A list of template fields and directions to sort the metadata query results by. The ordering `direction` must be the same for each item in the array. — item shape: {direction?: "ASC"|"DESC"|"asc"|"desc", field_key?: string}
  --query: string # The query to perform. A query is a logical expression that is very similar to a SQL `SELECT` statement. Values in the search query can be turned into parameters specified in the `query_param` arguments list to prevent having to manually insert search values into the query string. For example, a value of `:amount` would represent the `amount` value in `query_params` object. (e.g. value >= :amount)
  --query-params: record # Set of arguments corresponding to the parameters specified in the `query`. The type of each parameter used in the `query_params` must match the type of the corresponding metadata template field. (e.g. {amount: 100})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata_queries/execute_read"
    body: {content_type: "application/json", kind: json, fields: [{name: ancestor_folder_id, var: ancestor_folder_id}, {name: fields, var: fields}, {name: from, var: from}, {name: limit, var: limit}, {name: marker, var: marker}, {name: order_by, var: order_by}, {name: query, var: query}, {name: query_params, var: query_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ancestor_folder_id: $ancestor_folder_id, fields: $fields, from: $from, limit: $limit, marker: $marker, order_by: $order_by, query: $query, query_params: $query_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata query indices
#
# GET /metadata_query_indices
# Returns: record<entries: table<fields: list, id: string, status: string, type: string>, limit: int, next_marker: string>
# operationId: get_metadata_query_indices
export def "get-metadata-query-indices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of the metadata template (required, e.g. global)
  --template-key: string # The name of the metadata template (required, e.g. properties)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata_query_indices"
    query: [{name: scope, var: scope, required: true}, {name: template_key, var: template_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find metadata template by instance ID
#
# GET /metadata_templates
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>
# operationId: get_metadata_templates
export def "get-metadata-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-instance-id: string # The ID of an instance of the metadata template to find. (required, format: uuid, e.g. 01234500-12f1-1234-aa12-b1d234cb567e)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata_templates"
    query: [{name: metadata_instance_id, var: metadata_instance_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metadata_instance_id: $metadata_instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all metadata templates for enterprise
#
# GET /metadata_templates/enterprise
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>
# operationId: get_metadata_templates_enterprise
export def "get-metadata-templates-enterprise" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata_templates/enterprise"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all classifications
#
# DELETE /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# operationId: delete_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema
export def "delete-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema" [
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
    path: "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all classifications
#
# GET /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: get_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema
export def "get-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schema" [
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
    path: "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#add
export def "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaadd" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema"
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#delete
export def "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemadelete" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema"
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update classification
#
# PUT /metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: put_metadata_templates_enterprise_securityClassification-6VMVochwUWo_schema#update
export def "put-metadata-templates-enterprise-security-classification-6vm-vochw-u-wo-schemaupdate" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata_templates/enterprise/securityClassification-6VMVochwUWo/schema"
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all global metadata templates
#
# GET /metadata_templates/global
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<copyInstanceOnItemCopy: bool, displayName: string, fields: list, hidden: bool, id: string, scope: string, templateKey: string, type: string>>
# operationId: get_metadata_templates_global
export def "get-metadata-templates-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metadata_templates/global"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create metadata template
#
# POST /metadata_templates/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: post_metadata_templates_schema
export def "post-metadata-templates-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-instance-on-item-copy: oneof<nothing, bool> # Whether or not to copy any metadata attached to a file or folder when it is copied. By default, metadata is not copied along with a file or folder when it is copied. (default: false, e.g. true)
  display_name: string # The display name of the template. (e.g. Product Info)
  --fields: list # An ordered list of template fields which are part of the template. Each field can be a regular text field, date field, number field, as well as a single or multi-select list. — item shape: {description?: string, displayName: string, hidden?: bool, key: string, options?: list, type: "string"|"float"|"date"|"enum"|"multiSelect"}
  --hidden: oneof<nothing, bool> # Defines if this template is visible in the Box web app UI, or if it is purely intended for usage through the API. (default: false, e.g. true)
  scope: string # The scope of the metadata template to create. Applications can only create templates for use within the authenticated user's enterprise. This value needs to be set to `enterprise`, as `global` scopes can not be created by applications. (e.g. enterprise)
  --template-key: string # A unique identifier for the template. This identifier needs to be unique across the enterprise for which the metadata template is being created. When not provided, the API will create a unique `templateKey` based on the value of the `displayName`. (e.g. productInfo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata_templates/schema"
    body: {content_type: "application/json", kind: json, fields: [{name: copyInstanceOnItemCopy, var: copy_instance_on_item_copy}, {name: displayName, var: display_name}, {name: fields, var: fields}, {name: hidden, var: hidden}, {name: scope, var: scope}, {name: templateKey, var: template_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    copy_instance_on_item_copy: $copy_instance_on_item_copy, display_name: $display_name, fields: $fields, hidden: $hidden, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add initial classifications
#
# POST /metadata_templates/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<displayName: string, hidden: bool, id: string, key: string, options: list, type: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: post_metadata_templates_schema#classifications
export def "post-metadata-templates-schemaclassifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-instance-on-item-copy: oneof<nothing, bool> # `false` (e.g. false)
  display_name: string@display-name-completer # `Classification` (e.g. Classification)
  --fields: list # The classification template holds one field, which holds all the valid classification values. — item shape: {displayName?: "Classification", hidden?: bool, key?: "Box__Security__Classification__Key", options?: list, type?: "enum"}
  --hidden: oneof<nothing, bool> # `false` (e.g. false)
  scope: string@scope-completer-1 # The scope in which to create the classifications. This should be `enterprise` or `enterprise_{id}` where `id` is the unique ID of the enterprise. (e.g. enterprise)
  --template-key: string@template-key-completer # `securityClassification-6VMVochwUWo` (e.g. securityClassification-6VMVochwUWo)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/metadata_templates/schema"
    body: {content_type: "application/json", kind: json, fields: [{name: copyInstanceOnItemCopy, var: copy_instance_on_item_copy}, {name: displayName, var: display_name}, {name: fields, var: fields}, {name: hidden, var: hidden}, {name: scope, var: scope}, {name: templateKey, var: template_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    copy_instance_on_item_copy: $copy_instance_on_item_copy, display_name: $display_name, fields: $fields, hidden: $hidden, scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove metadata template
#
# DELETE /metadata_templates/{scope}/{template_key}/schema
# operationId: delete_metadata_templates_id_id_schema
export def "delete-metadata-templates-id-id-schema" [
  scope: string@scope-completer
  template_key: string
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
    path: "/metadata_templates/{scope}/{template_key}/schema"
    path_params: [{name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata template by name
#
# GET /metadata_templates/{scope}/{template_key}/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: get_metadata_templates_id_id_schema
export def "get-metadata-templates-id-id-schema" [
  scope: string@scope-completer
  template_key: string
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
    path: "/metadata_templates/{scope}/{template_key}/schema"
    path_params: [{name: scope, var: scope}, {name: template_key, var: template_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, template_key: $template_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update metadata template
#
# PUT /metadata_templates/{scope}/{template_key}/schema
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: put_metadata_templates_id_id_schema
export def "put-metadata-templates-id-id-schema" [
  scope: string@scope-completer
  template_key: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/metadata_templates/{scope}/{template_key}/schema"
    path_params: [{name: scope, var: scope}, {name: template_key, var: template_key}]
    body: {content_type: "application/json-patch+json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, template_key: $template_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata template by ID
#
# GET /metadata_templates/{template_id}
# Returns: record<copyInstanceOnItemCopy: bool, displayName: string, fields: table<description: string, displayName: string, hidden: bool, key: string, options: list, type: string, id: string>, hidden: bool, id: string, scope: string, templateKey: string, type: string>
# operationId: get_metadata_templates_id
export def "get-metadata-templates-id" [
  template_id: string
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
    path: "/metadata_templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke access token
#
# POST /oauth2/revoke
# operationId: post_oauth2_revoke
export def "post-oauth2-revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID of the application requesting to revoke the access token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting to revoke an access token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --body-token: string # The access token to revoke. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW) (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth2/revoke"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.box.com"
    auth: none
  } {
    client_id: $client_id, client_secret: $client_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request access token
#
# POST /oauth2/token
# Returns: record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string>
# operationId: post_oauth2_token
export def "post-oauth2-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actor-token: string # The token used to create an annotator token. This is a JWT assertion. Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --actor-token-type: string@actor-token-type-completer # The type of `actor_token` passed in. Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: urn, e.g. urn:ietf:params:oauth:token-type:id_token)
  --assertion: string # A JWT assertion for which to request a new access token. Used in combination with `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (format: jwt, e.g. xxxxx.yyyyy.zzzzz)
  --box-shared-link: string # Full URL of the shared link on the file or folder that the token should be generated for. (format: url, e.g. https://cloud.box.com/s/123456)
  --box-subject-id: string # Used in combination with `client_credentials` as the `grant_type`. Value is determined by `box_subject_type`. If `user` use user ID and if `enterprise` use enterprise ID. (e.g. 123456789)
  --box-subject-type: string@box-subject-type-completer # Used in combination with `client_credentials` as the `grant_type`. (e.g. enterprise)
  --client-id: string # The Client ID of the application requesting an access token. Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  --client-secret: string # The client secret of the application requesting an access token. Used in combination with `authorization_code`, `client_credentials`, or `urn:ietf:params:oauth:grant-type:jwt-bearer` as the `grant_type`. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  --code: string # The client-side authorization code passed to your application by Box in the browser redirect after the user has successfully granted your application permission to make API calls on their behalf. Used in combination with `authorization_code` as the `grant_type`. (format: token, e.g. n22JPxrh18m4Y0wIZPIqYZK7VRrsMTWW)
  grant_type: string@grant-type-completer # The type of request being made, either using a client-side obtained authorization code, a refresh token, a JWT assertion, client credentials grant or another access token for the purpose of downscoping a token. (format: urn, e.g. authorization_code)
  --refresh-token: string # A refresh token used to get a new access token with. Used in combination with `refresh_token` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --resource: string # Full URL for the file that the token should be generated for. (format: url, e.g. https://api.box.com/2.0/files/123456)
  --scope: string # The space-delimited list of scopes that you want apply to the new access token. The `subject_token` will need to have all of these scopes or the call will error with **401 Unauthorized**. (format: space_delimited_list, e.g. item_upload item_preview base_explorer)
  --subject-token: string # The token to exchange for a downscoped token. This can be a regular access token, a JWT assertion, or an app token. Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
  --subject-token-type: string@subject-token-type-completer # The type of `subject_token` passed in. Used in combination with `urn:ietf:params:oauth:grant-type:token-exchange` as the `grant_type`. (e.g. urn:ietf:params:oauth:token-type:access_token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: actor_token, var: actor_token}, {name: actor_token_type, var: actor_token_type}, {name: assertion, var: assertion}, {name: box_shared_link, var: box_shared_link}, {name: box_subject_id, var: box_subject_id}, {name: box_subject_type, var: box_subject_type}, {name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}, {name: grant_type, var: grant_type}, {name: refresh_token, var: refresh_token}, {name: resource, var: resource}, {name: scope, var: scope}, {name: subject_token, var: subject_token}, {name: subject_token_type, var: subject_token_type}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.box.com"
    auth: none
  } {
    actor_token: $actor_token, actor_token_type: $actor_token_type, assertion: $assertion, box_shared_link: $box_shared_link, box_subject_id: $box_subject_id, box_subject_type: $box_subject_type, client_id: $client_id, client_secret: $client_secret, code: $code, grant_type: $grant_type, refresh_token: $refresh_token, resource: $resource, scope: $scope, subject_token: $subject_token, subject_token_type: $subject_token_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh access token
#
# POST /oauth2/token
# Returns: record<access_token: string, expires_in: int, issued_token_type: string, refresh_token: string, restricted_to: table<object: record, scope: string>, token_type: string>
# operationId: post_oauth2_token#refresh
export def "post-oauth2-tokenrefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The client ID of the application requesting to refresh the token. (e.g. ly1nj6n11vionaie65emwzk575hnnmrk)
  client_secret: string # The client secret of the application requesting to refresh the token. (e.g. hOzsTeFlT6ko0dme22uGbQal04SBPYc1)
  grant_type: string@grant-type-completer-1 # The type of request being made, in this case a refresh request. (format: urn, e.g. refresh_token)
  refresh_token: string # The refresh token to refresh. (format: token, e.g. c3FIOG9vSGV4VHo4QzAyg5T1JvNnJoZ3ExaVNyQWw6WjRsanRKZG5lQk9qUE1BVQ)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: grant_type, var: grant_type}, {name: refresh_token, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.box.com"
    auth: none
  } {
    client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List recently accessed items
#
# GET /recent_items
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<interacted_at: string, interaction_shared_link: string, interaction_type: string, item: record, type: string>>
# operationId: get_recent_items
export def "get-recent-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recent_items"
    query: [{name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields, limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List retention policies
#
# GET /retention_policies
# Returns: record<entries: table<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, limit: int, next_marker: string>
# operationId: get_retention_policies
export def "get-retention-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-name: string # Filters results by a case sensitive prefix of the name of retention policies. (e.g. Sales Policy)
  --policy-type: string@policy-type-completer # Filters results by the type of retention policy. (e.g. finite)
  --created-by-user-id: string # Filters results by the ID of the user who created policy. (e.g. 21312321)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policies"
    query: [{name: policy_name, var: policy_name}, {name: policy_type, var: policy_type}, {name: created_by_user_id, var: created_by_user_id}, {name: fields, var: fields, style: csv}, {name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, policy_type: $policy_type, created_by_user_id: $created_by_user_id, fields: $fields, limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create retention policy
#
# POST /retention_policies
# Returns: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>
# operationId: post_retention_policies
export def "post-retention-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-owners-notified: oneof<nothing, bool> # Whether owner and co-owners of a file are notified when the policy nears expiration. (e.g. true)
  --can-owner-extend-retention: oneof<nothing, bool> # Whether the owner of a file will be allowed to extend the retention. (e.g. true)
  --custom-notification-recipients: list # A list of users notified when the retention policy duration is about to end. — item shape: {id?: string, type: "user", login: string, name: string}
  --description: string # The additional text description of the retention policy. (e.g. Policy to retain all reports for at least one month)
  disposition_action: string@disposition-action-completer # The disposition action of the retention policy. `permanently_delete` deletes the content retained by the policy permanently. `remove_retention` lifts retention policy from the content, allowing it to be deleted by users once the retention policy has expired. (e.g. permanently_delete)
  policy_name: string # The name for the retention policy (e.g. Some Policy Name)
  policy_type: string@policy-type-completer # The type of the retention policy. A retention policy type can either be `finite`, where a specific amount of time to retain the content is known upfront, or `indefinite`, where the amount of time to retain the content is still unknown. (e.g. finite)
  --retention-length: string # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content. If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (format: int32, e.g. 365)
  --retention-type: string@retention-type-completer # Specifies the retention type: * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes. * `non-modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies. (e.g. modifiable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/retention_policies"
    body: {content_type: "application/json", kind: json, fields: [{name: are_owners_notified, var: are_owners_notified}, {name: can_owner_extend_retention, var: can_owner_extend_retention}, {name: custom_notification_recipients, var: custom_notification_recipients}, {name: description, var: description}, {name: disposition_action, var: disposition_action}, {name: policy_name, var: policy_name}, {name: policy_type, var: policy_type}, {name: retention_length, var: retention_length}, {name: retention_type, var: retention_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    are_owners_notified: $are_owners_notified, can_owner_extend_retention: $can_owner_extend_retention, custom_notification_recipients: $custom_notification_recipients, description: $description, disposition_action: $disposition_action, policy_name: $policy_name, policy_type: $policy_type, retention_length: $retention_length, retention_type: $retention_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete retention policy
#
# DELETE /retention_policies/{retention_policy_id}
# operationId: delete_retention_policies_id
export def "delete-retention-policies-id" [
  retention_policy_id: string
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
    path: "/retention_policies/{retention_policy_id}"
    path_params: [{name: retention_policy_id, var: retention_policy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    retention_policy_id: $retention_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get retention policy
#
# GET /retention_policies/{retention_policy_id}
# Returns: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>
# operationId: get_retention_policies_id
export def "get-retention-policies-id" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policies/{retention_policy_id}"
    path_params: [{name: retention_policy_id, var: retention_policy_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_id: $retention_policy_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update retention policy
#
# PUT /retention_policies/{retention_policy_id}
# Returns: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string, are_owners_notified: bool, assignment_counts: record<enterprise: int, folder: int, metadata_template: int>, can_owner_extend_retention: bool, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, custom_notification_recipients: table<id: string, type: string, login: string, name: string>, description: string, modified_at: string, policy_type: string, retention_type: string, status: string>
# operationId: put_retention_policies_id
export def "put-retention-policies-id" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-owners-notified: oneof<nothing, bool> # Determines if owners and co-owners of items under the policy are notified when the retention duration is about to end. (e.g. false)
  --can-owner-extend-retention: oneof<nothing, bool> # Determines if the owner of items under the policy can extend the retention when the original retention duration is about to end. (e.g. false)
  --custom-notification-recipients: list # A list of users notified when the retention duration is about to end. — item shape: {id?: string, type: "user", login: string, name: string}
  --description: string # The additional text description of the retention policy. (e.g. Policy to retain all reports for at least one month)
  --disposition-action: string@disposition-action-completer # The disposition action of the retention policy. `permanently_delete` deletes the content retained by the policy permanently. `remove_retention` lifts retention policy from the content, allowing it to be deleted by users once the retention policy has expired. (e.g. permanently_delete)
  --policy-name: string # The name for the retention policy (e.g. Some Policy Name)
  --retention-length: string # The length of the retention policy. This value specifies the duration in days that the retention policy will be active for after being assigned to content. If the policy has a `policy_type` of `indefinite`, the `retention_length` will also be `indefinite`. (format: int32, e.g. 365)
  --retention-type: string # Specifies the retention type: * `modifiable`: You can modify the retention policy. For example, you can add or remove folders, shorten or lengthen the policy duration, or delete the assignment. Use this type if your retention policy is not related to any regulatory purposes. * `non-modifiable`: You can modify the retention policy only in a limited way: add a folder, lengthen the duration, retire the policy, change the disposition action or notification settings. You cannot perform other actions, such as deleting the assignment or shortening the policy duration. Use this type to ensure compliance with regulatory retention policies. When updating a retention policy, you can use `non-modifiable` type only. You can convert a `modifiable` policy to `non-modifiable`, but not the other way around. (e.g. non-modifiable)
  --status: string # Used to retire a retention policy. If not retiring a policy, do not include this parameter or set it to `null`. (e.g. retired)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/retention_policies/{retention_policy_id}"
    path_params: [{name: retention_policy_id, var: retention_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: are_owners_notified, var: are_owners_notified}, {name: can_owner_extend_retention, var: can_owner_extend_retention}, {name: custom_notification_recipients, var: custom_notification_recipients}, {name: description, var: description}, {name: disposition_action, var: disposition_action}, {name: policy_name, var: policy_name}, {name: retention_length, var: retention_length}, {name: retention_type, var: retention_type}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_id: $retention_policy_id, are_owners_notified: $are_owners_notified, can_owner_extend_retention: $can_owner_extend_retention, custom_notification_recipients: $custom_notification_recipients, description: $description, disposition_action: $disposition_action, policy_name: $policy_name, retention_length: $retention_length, retention_type: $retention_type, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List retention policy assignments
#
# GET /retention_policies/{retention_policy_id}/assignments
# Returns: record<entries: table<id: string, type: string>, limit: int, next_marker: string>
# operationId: get_retention_policies_id_assignments
export def "get-retention-policies-id-assignments" [
  retention_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of the retention policy assignment to retrieve. (e.g. metadata_template)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policies/{retention_policy_id}/assignments"
    path_params: [{name: retention_policy_id, var: retention_policy_id}]
    query: [{name: type, var: type}, {name: fields, var: fields, style: csv}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_id: $retention_policy_id, type: $type, fields: $fields, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign retention policy
#
# POST /retention_policy_assignments
# Returns: record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, start_date_field: string, type: string>
# operationId: post_retention_policy_assignments
export def "post-retention-policy-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The item to assign the policy to — shape: {id: string, type: "enterprise"|"folder"|"metadata_template"}
  --filter-fields: list # If the `assign_to` type is `metadata_template`, then optionally add the `filter_fields` parameter which will require an array of objects with a field entry and a value entry. Currently only one object of `field` and `value` is supported. — item shape: {field?: string, value?: string}
  policy_id: string # The ID of the retention policy to assign (e.g. 173463)
  --start-date-field: string # The date the retention policy assignment begins. If the `assigned_to` type is `metadata_template`, this field can be a date field's metadata attribute key id. (e.g. upload_date)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/retention_policy_assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: assign_to, var: assign_to}, {name: filter_fields, var: filter_fields}, {name: policy_id, var: policy_id}, {name: start_date_field, var: start_date_field}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    assign_to: $assign_to, filter_fields: $filter_fields, policy_id: $policy_id, start_date_field: $start_date_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove retention policy assignment
#
# DELETE /retention_policy_assignments/{retention_policy_assignment_id}
# operationId: delete_retention_policy_assignments_id
export def "delete-retention-policy-assignments-id" [
  retention_policy_assignment_id: string
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
    path: "/retention_policy_assignments/{retention_policy_assignment_id}"
    path_params: [{name: retention_policy_assignment_id, var: retention_policy_assignment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    retention_policy_assignment_id: $retention_policy_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get retention policy assignment
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}
# Returns: record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string>, filter_fields: table<field: string, value: string>, id: string, retention_policy: record<id: string, type: string, disposition_action: string, policy_name: string, retention_length: string>, start_date_field: string, type: string>
# operationId: get_retention_policy_assignments_id
export def "get-retention-policy-assignments-id" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policy_assignments/{retention_policy_assignment_id}"
    path_params: [{name: retention_policy_assignment_id, var: retention_policy_assignment_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_assignment_id: $retention_policy_assignment_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file versions under retention
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}/file_versions_under_retention
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>>
# operationId: get_retention_policy_assignments_id_file_versions_under_retention
export def "get-retention-policy-assignments-id-file-versions-under-retention" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policy_assignments/{retention_policy_assignment_id}/file_versions_under_retention"
    path_params: [{name: retention_policy_assignment_id, var: retention_policy_assignment_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_assignment_id: $retention_policy_assignment_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get files under retention
#
# GET /retention_policy_assignments/{retention_policy_assignment_id}/files_under_retention
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>>
# operationId: get_retention_policy_assignments_id_files_under_retention
export def "get-retention-policy-assignments-id-files-under-retention" [
  retention_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/retention_policy_assignments/{retention_policy_assignment_id}/files_under_retention"
    path_params: [{name: retention_policy_assignment_id, var: retention_policy_assignment_id}]
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    retention_policy_assignment_id: $retention_policy_assignment_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for content
#
# GET /search
# operationId: get_search
export def "get-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The string to search for. This query is matched against item names, descriptions, text content of files, and various other fields of the different item types. This parameter supports a variety of operators to further refine the results returns. * `""` - by wrapping a query in double quotes only exact matches are returned by the API. Exact searches do not return search matches based on specific character sequences. Instead, they return matches based on phrases, that is, word sequences. For example: A search for `"Blue-Box"` may return search results including the sequence `"blue.box"`, `"Blue Box"`, and `"Blue-Box"`; any item containing the words `Blue` and `Box` consecutively, in the order specified. * `AND` - returns items that contain both the search terms. For example, a search for `marketing AND BoxWorks` returns items that have both `marketing` and `BoxWorks` within its text in any order. It does not return a result that only has `BoxWorks` in its text. * `OR` - returns items that contain either of the search terms. For example, a search for `marketing OR BoxWorks` returns a result that has either `marketing` or `BoxWorks` within its text. Using this operator is not necessary as we implicitly interpret multi-word queries as `OR` unless another supported boolean term is used. * `NOT` - returns items that do not contain the search term provided. For example, a search for `marketing AND NOT BoxWorks` returns a result that has only `marketing` within its text. Results containing `BoxWorks` are omitted. Please note that we do not support lower case (that is, `and`, `or`, and `not`) or mixed case (that is, `And`, `Or`, and `Not`) operators. This field is required unless the `mdfilters` parameter is defined. (e.g. sales)
  --scope: string@scope-completer-2 # Limits the search results to either the files that the user has access to, or to files available to the entire enterprise. The scope defaults to `user_content`, which limits the search results to content that is available to the currently authenticated user. The `enterprise_content` can be requested by an admin through our support channels. Once this scope has been enabled for a user, it will allow that use to query for content across the entire enterprise and not only the content that they have access to. (default: user_content, e.g. user_content)
  --file-extensions: list<string> # Limits the search results to any files that match any of the provided file extensions. This list is a comma-separated list of file extensions without the dots. (e.g. [pdf, png, gif])
  --created-at-range: list<string> # Limits the search results to any items created within a given date range. Date ranges are defined as comma separated RFC3339 timestamps. If the the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything created before the end date will be returned. If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --updated-at-range: list<string> # Limits the search results to any items updated within a given date range. Date ranges are defined as comma separated RFC3339 timestamps. If the start date is omitted (`,2014-05-17T13:35:01-07:00`) anything updated before the end date will be returned. If the end date is omitted (`2014-05-15T13:35:01-07:00,`) the current date will be used as the end date instead. (e.g. [2014-05-15T13:35:01-07:00, 2014-05-17T13:35:01-07:00])
  --size-range: list<int> # Limits the search results to any items with a size within a given file size range. This applied to files and folders. Size ranges are defined as comma separated list of a lower and upper byte size limit (inclusive). The upper and lower bound can be omitted to create open ranges. (e.g. [1000000, 5000000])
  --owner-user-ids: list<string> # Limits the search results to any items that are owned by the given list of owners, defined as a list of comma separated user IDs. Please note that the items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned. To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [123422, 23532, 3241212])
  --recent-updater-user-ids: list<string> # Limits the search results to any items that have been updated by the given list of users, defined as a list of comma separated user IDs. Please note that the items still need to be owned or shared with the currently authenticated user for them to show up in the search results. If the user does not have access to any files owned by any of the users an empty result set will be returned. This feature only searches back to the last 10 versions of an item. (e.g. [123422, 23532, 3241212])
  --ancestor-folder-ids: list<string> # Limits the search results to items within the given list of folders, defined as a comma separated lists of folder IDs. Search results will also include items within any subfolders of those ancestor folders. Please note that the folders still need to be owned or shared with the currently authenticated user. If the folder is not accessible by this user, or it does not exist, a `HTTP 404` error code will be returned instead. To search across an entire enterprise, we recommend using the `enterprise_content` scope parameter which can be requested with our support team. (e.g. [4535234, 234123235, 2654345])
  --content-types: list<string> # Limits the search results to any items that match the search query for a specific part of the file, for example the file description. Content types are defined as a comma separated lists of Box recognized content types. The allowed content types are as follows. * `name` - The name of the item, as defined by its `name` field. * `description` - The description of the item, as defined by its `description` field. * `file_content` - The actual content of the file. * `comments` - The content of any of the comments on a file or folder. * `tags` - Any tags that are applied to an item, as defined by its `tags` field. (e.g. [name, description])
  --type: string@type-completer-2 # Limits the search results to any items of this type. This parameter only takes one value. By default the API returns items that match any of these types. * `file` - Limits the search results to files * `folder` - Limits the search results to folders * `web_link` - Limits the search results to web links, also known as bookmarks (e.g. file)
  --trash-content: string@trash-content-completer # Determines if the search should look in the trash for items. By default, this API only returns search results for items not currently in the trash (`non_trashed_only`). * `trashed_only` - Only searches for items currently in the trash * `non_trashed_only` - Only searches for items currently not in the trash (default: non_trashed_only, e.g. non_trashed_only)
  --mdfilters: list # Limits the search results to any items for which the metadata matches the provided filter. This parameter contains a list of 1 metadata template to filter the search results by. This list can currently only contain one entry, though this might be expanded in the future. This parameter is required unless the `query` parameter is provided. (e.g. [{filters: {category: online}, scope: enterprise, templateKey: contract}])
  --sort: string@sort-completer-1 # Defines the order in which search results are returned. This API defaults to returning items by relevance unless this parameter is explicitly specified. * `relevance` (default) returns the results sorted by relevance to the query search term. The relevance is based on the occurrence of the search term in the items name, description, content, and additional properties. * `modified_at` returns the results ordered in descending order by date at which the item was last modified. (default: relevance, e.g. modified_at)
  --direction: string@direction-completer-1 # Defines the direction in which search results are ordered. This API defaults to returning items in descending (`DESC`) order unless this parameter is explicitly specified. When results are sorted by `relevance` the ordering is locked to returning items in descending order of relevance, and this parameter is ignored. (default: DESC, e.g. ASC)
  --limit: int # Defines the maximum number of items to return as part of a page of results. (format: int64, default: 30, e.g. 100)
  --include-recent-shared-links: oneof<nothing, bool> # Defines whether the search results should include any items that the user recently accessed through a shared link. Please note that when this parameter has been set to true, the format of the response of this API changes to return a list of [Search Results with Shared Links](r://search_results_with_shared_links) (default: false, e.g. true)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> any {
  http-request {
    method: get
    path: "/search"
    query: [{name: query, var: query}, {name: scope, var: scope}, {name: file_extensions, var: file_extensions, style: csv}, {name: created_at_range, var: created_at_range, style: csv}, {name: updated_at_range, var: updated_at_range, style: csv}, {name: size_range, var: size_range, style: csv}, {name: owner_user_ids, var: owner_user_ids, style: csv}, {name: recent_updater_user_ids, var: recent_updater_user_ids, style: csv}, {name: ancestor_folder_ids, var: ancestor_folder_ids, style: csv}, {name: content_types, var: content_types, style: csv}, {name: type, var: type}, {name: trash_content, var: trash_content}, {name: mdfilters, var: mdfilters, style: multi}, {name: sort, var: sort}, {name: direction, var: direction}, {name: limit, var: limit}, {name: include_recent_shared_links, var: include_recent_shared_links}, {name: fields, var: fields, style: csv}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, scope: $scope, file_extensions: $file_extensions, created_at_range: $created_at_range, updated_at_range: $updated_at_range, size_range: $size_range, owner_user_ids: $owner_user_ids, recent_updater_user_ids: $recent_updater_user_ids, ancestor_folder_ids: $ancestor_folder_ids, content_types: $content_types, type: $type, trash_content: $trash_content, mdfilters: $mdfilters, sort: $sort, direction: $direction, limit: $limit, include_recent_shared_links: $include_recent_shared_links, fields: $fields, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find file for shared link
#
# GET /shared_items
# Returns: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_shared_items
export def "get-shared-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link. The format for this header is as follows. `shared_link=[link]&shared_link_password=[password]` (required, e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shared_items"
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-none-match, var: if_none_match}, {name: boxapi, var: boxapi, required: true}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fields: $fields, if_none_match: $if_none_match, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find folder for shared link
#
# GET /shared_items
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: get_shared_items#folders
export def "get-shared-itemsfolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link. The format for this header is as follows. `shared_link=[link]&shared_link_password=[password]` (required, e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shared_items"
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-none-match, var: if_none_match}, {name: boxapi, var: boxapi, required: true}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fields: $fields, if_none_match: $if_none_match, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find web link for shared link
#
# GET /shared_items
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: get_shared_items#web_links
export def "get-shared-itemsweb-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --if-none-match: string # Ensures an item is only returned if it has changed. Pass in the item's last observed `etag` value into this header and the endpoint will fail with a `304 Not Modified` if the item has not changed since. (e.g. 1)
  --boxapi: string # A header containing the shared link and optional password for the shared link. The format for this header is as follows. `shared_link=[link]&shared_link_password=[password]` (required, e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shared_items"
    query: [{name: fields, var: fields, style: csv}]
    header: [{name: if-none-match, var: if_none_match}, {name: boxapi, var: boxapi, required: true}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    fields: $fields, if_none_match: $if_none_match, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shield information barrier reports
#
# GET /shield_information_barrier_reports
# Returns: record<entries: table<id: string, type: string, created_at: string, created_by: record, details: record, shield_information_barrier: record, status: string, updated_at: string>, limit: int, next_marker: string>
# operationId: get_shield_information_barrier_reports
export def "get-shield-information-barrier-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-id: string # The ID of the shield information barrier. (required, e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shield_information_barrier_reports"
    query: [{name: shield_information_barrier_id, var: shield_information_barrier_id, required: true}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_id: $shield_information_barrier_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shield information barrier report
#
# POST /shield_information_barrier_reports
# Returns: record<id: string, type: string, created_at: string, created_by: record<id: string, type: string>, details: record<details: record<folder_id: string>>, shield_information_barrier: record<shield_information_barrier: record<id: string, type: string>>, status: string, updated_at: string>
# operationId: post_shield_information_barrier_reports
export def "post-shield-information-barrier-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barrier_reports"
    body: {content_type: "application/json", kind: json, fields: [{name: shield_information_barrier, var: shield_information_barrier}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    shield_information_barrier: $shield_information_barrier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shield information barrier report by ID
#
# GET /shield_information_barrier_reports/{shield_information_barrier_report_id}
# Returns: record<id: string, type: string, created_at: string, created_by: record<id: string, type: string>, details: record<details: record<folder_id: string>>, shield_information_barrier: record<shield_information_barrier: record<id: string, type: string>>, status: string, updated_at: string>
# operationId: get_shield_information_barrier_reports_id
export def "get-shield-information-barrier-reports-id" [
  shield_information_barrier_report_id: string
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
    path: "/shield_information_barrier_reports/{shield_information_barrier_report_id}"
    path_params: [{name: shield_information_barrier_report_id, var: shield_information_barrier_report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_report_id: $shield_information_barrier_report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shield information barrier segment members
#
# GET /shield_information_barrier_segment_members
# Returns: record<entries: table<id: string, type: string, user: record, created_at: string, created_by: record, shield_information_barrier: record, shield_information_barrier_segment: record, updated_at: string, updated_by: record>, limit: int, next_marker: string>
# operationId: get_shield_information_barrier_segment_members
export def "get-shield-information-barrier-segment-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (required, e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shield_information_barrier_segment_members"
    query: [{name: shield_information_barrier_segment_id, var: shield_information_barrier_segment_id, required: true}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_id: $shield_information_barrier_segment_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shield information barrier segment member
#
# POST /shield_information_barrier_segment_members
# Returns: record<id: string, type: string, user: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: post_shield_information_barrier_segment_members
export def "post-shield-information-barrier-segment-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  --type: string@type-completer-3 # -| A type of the shield barrier segment member. (e.g. shield_information_barrier_segment_member)
  user: record # A mini representation of a user, used when nested within another resource. — shape: {id?: string, type: "user"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barrier_segment_members"
    body: {content_type: "application/json", kind: json, fields: [{name: shield_information_barrier, var: shield_information_barrier}, {name: shield_information_barrier_segment, var: shield_information_barrier_segment}, {name: type, var: type}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    shield_information_barrier: $shield_information_barrier, shield_information_barrier_segment: $shield_information_barrier_segment, type: $type, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete shield information barrier segment member by ID
#
# DELETE /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# operationId: delete_shield_information_barrier_segment_members_id
export def "delete-shield-information-barrier-segment-members-id" [
  shield_information_barrier_segment_member_id: string
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
    path: "/shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}"
    path_params: [{name: shield_information_barrier_segment_member_id, var: shield_information_barrier_segment_member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shield_information_barrier_segment_member_id: $shield_information_barrier_segment_member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shield information barrier segment member by ID
#
# GET /shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}
# Returns: record<id: string, type: string, user: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: get_shield_information_barrier_segment_members_id
export def "get-shield-information-barrier-segment-members-id" [
  shield_information_barrier_segment_member_id: string
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
    path: "/shield_information_barrier_segment_members/{shield_information_barrier_segment_member_id}"
    path_params: [{name: shield_information_barrier_segment_member_id, var: shield_information_barrier_segment_member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_member_id: $shield_information_barrier_segment_member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shield information barrier segment restrictions
#
# GET /shield_information_barrier_segment_restrictions
# Returns: record<entries: table<id: string, type: string, restricted_segment: record, shield_information_barrier_segment: record, created_at: string, created_by: record, shield_information_barrier: record, updated_at: string, updated_by: record>, limit: int, next_marker: string>
# operationId: get_shield_information_barrier_segment_restrictions
export def "get-shield-information-barrier-segment-restrictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-segment-id: string # The ID of the shield information barrier segment. (required, e.g. 3423)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shield_information_barrier_segment_restrictions"
    query: [{name: shield_information_barrier_segment_id, var: shield_information_barrier_segment_id, required: true}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_id: $shield_information_barrier_segment_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shield information barrier segment restriction
#
# POST /shield_information_barrier_segment_restrictions
# Returns: record<id: string, type: string, restricted_segment: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: post_shield_information_barrier_segment_restrictions
export def "post-shield-information-barrier-segment-restrictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  restricted_segment: record # The `type` and `id` of the restricted shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  --shield-information-barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
  shield_information_barrier_segment: record # The `type` and `id` of the requested shield information barrier segment. — shape: {id?: string, type?: "shield_information_barrier_segment"}
  type: string@type-completer-4 # The type of the shield barrier segment restriction for this member. (e.g. shield_information_barrier_segment_restriction)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barrier_segment_restrictions"
    body: {content_type: "application/json", kind: json, fields: [{name: restricted_segment, var: restricted_segment}, {name: shield_information_barrier, var: shield_information_barrier}, {name: shield_information_barrier_segment, var: shield_information_barrier_segment}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    restricted_segment: $restricted_segment, shield_information_barrier: $shield_information_barrier, shield_information_barrier_segment: $shield_information_barrier_segment, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete shield information barrier segment restriction by ID
#
# DELETE /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# operationId: delete_shield_information_barrier_segment_restrictions_id
export def "delete-shield-information-barrier-segment-restrictions-id" [
  shield_information_barrier_segment_restriction_id: string
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
    path: "/shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}"
    path_params: [{name: shield_information_barrier_segment_restriction_id, var: shield_information_barrier_segment_restriction_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shield_information_barrier_segment_restriction_id: $shield_information_barrier_segment_restriction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shield information barrier segment restriction by ID
#
# GET /shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}
# Returns: record<id: string, type: string, restricted_segment: record<id: string, type: string>, shield_information_barrier_segment: record<id: string, type: string>, created_at: string, created_by: record<id: string, type: string>, shield_information_barrier: record<id: string, type: string>, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: get_shield_information_barrier_segment_restrictions_id
export def "get-shield-information-barrier-segment-restrictions-id" [
  shield_information_barrier_segment_restriction_id: string
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
    path: "/shield_information_barrier_segment_restrictions/{shield_information_barrier_segment_restriction_id}"
    path_params: [{name: shield_information_barrier_segment_restriction_id, var: shield_information_barrier_segment_restriction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_restriction_id: $shield_information_barrier_segment_restriction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shield information barrier segments
#
# GET /shield_information_barrier_segments
# Returns: record<entries: table<created_at: string, created_by: record, description: string, id: string, name: string, shield_information_barrier: record, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string>
# operationId: get_shield_information_barrier_segments
export def "get-shield-information-barrier-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shield-information-barrier-id: string # The ID of the shield information barrier. (required, e.g. 1910967)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shield_information_barrier_segments"
    query: [{name: shield_information_barrier_id, var: shield_information_barrier_id, required: true}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_id: $shield_information_barrier_id, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shield information barrier segment
#
# POST /shield_information_barrier_segments
# Returns: record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: post_shield_information_barrier_segments
export def "post-shield-information-barrier-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the shield information barrier segment (e.g. 'Corporate division that engages in  advisory_based financial transactions on behalf of individuals, corporations, and governments.')
  name: string # Name of the shield information barrier segment (e.g. Investment Banking)
  shield_information_barrier: record # A base representation of a shield information barrier object — shape: {id?: string, type?: "shield_information_barrier"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barrier_segments"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: shield_information_barrier, var: shield_information_barrier}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, name: $name, shield_information_barrier: $shield_information_barrier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete shield information barrier segment
#
# DELETE /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# operationId: delete_shield_information_barrier_segments_id
export def "delete-shield-information-barrier-segments-id" [
  shield_information_barrier_segment_id: string
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
    path: "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"
    path_params: [{name: shield_information_barrier_segment_id, var: shield_information_barrier_segment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shield_information_barrier_segment_id: $shield_information_barrier_segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shield information barrier segment with specified ID
#
# GET /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: get_shield_information_barrier_segments_id
export def "get-shield-information-barrier-segments-id" [
  shield_information_barrier_segment_id: string
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
    path: "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"
    path_params: [{name: shield_information_barrier_segment_id, var: shield_information_barrier_segment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_id: $shield_information_barrier_segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update shield information barrier segment with specified ID
#
# PUT /shield_information_barrier_segments/{shield_information_barrier_segment_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string>, description: string, id: string, name: string, shield_information_barrier: record<id: string, type: string>, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: put_shield_information_barrier_segments_id
export def "put-shield-information-barrier-segments-id" [
  shield_information_barrier_segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The updated description for the shield information barrier segment. (nullable, e.g. 'Corporate division that engages in advisory_based financial transactions on behalf of individuals, corporations, and governments.')
  --name: string # The updated name for the shield information barrier segment. (e.g. Investment Banking)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/shield_information_barrier_segments/{shield_information_barrier_segment_id}"
    path_params: [{name: shield_information_barrier_segment_id, var: shield_information_barrier_segment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_segment_id: $shield_information_barrier_segment_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List shield information barriers
#
# GET /shield_information_barriers
# Returns: record<entries: table<created_at: string, created_by: record, enabled_at: string, enabled_by: record, enterprise: record, id: string, status: string, type: string, updated_at: string, updated_by: record>, limit: int, next_marker: string>
# operationId: get_shield_information_barriers
export def "get-shield-information-barriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shield_information_barriers"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create shield information barrier
#
# POST /shield_information_barriers
# Returns: record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: post_shield_information_barriers
export def "post-shield-information-barriers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # ISO date time string when this shield information barrier object was created. (format: date-time, e.g. 2020-06-26T18:44:45.869Z)
  --created-by: record # A mini representation of a user, used when nested within another resource. — shape: {id?: string, type: "user"}
  --enabled-at: string # ISO date time string when this shield information barrier was enabled. (format: date-time, e.g. 2020-07-26T18:44:45.869Z)
  --enabled-by: record # A mini representation of a user, used when nested within another resource. — shape: {id?: string, type: "user"}
  --enterprise: record # A mini representation of a enterprise, used when nested within another resource. — shape: {id?: string, type?: "enterprise"}
  --id: string # The unique identifier for the shield information barrier (e.g. 11446498)
  --status: string@status-completer-3 # Status of the shield information barrier (e.g. draft)
  --type: string@type-completer-5 # The type of the shield information barrier (e.g. shield_information_barrier)
  --updated-at: string # ISO date time string when this shield information barrier was updated. (format: date-time, e.g. 2020-07-26T18:44:45.869Z)
  --updated-by: record # A mini representation of a user, used when nested within another resource. — shape: {id?: string, type: "user"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barriers"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: created_by, var: created_by}, {name: enabled_at, var: enabled_at}, {name: enabled_by, var: enabled_by}, {name: enterprise, var: enterprise}, {name: id, var: id}, {name: status, var: status}, {name: type, var: type}, {name: updated_at, var: updated_at}, {name: updated_by, var: updated_by}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    created_at: $created_at, created_by: $created_by, enabled_at: $enabled_at, enabled_by: $enabled_by, enterprise: $enterprise, id: $id, status: $status, type: $type, updated_at: $updated_at, updated_by: $updated_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add changed status of shield information barrier with specified ID
#
# POST /shield_information_barriers/change_status
# Returns: record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: post_shield_information_barriers_change_status
export def "post-shield-information-barriers-change-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # The ID of the shield information barrier. (e.g. 1910967)
  status: string@status-completer-4 # The desired status for the shield information barrier. (e.g. pending)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shield_information_barriers/change_status"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shield information barrier with specified ID
#
# GET /shield_information_barriers/{shield_information_barrier_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string>, enabled_at: string, enabled_by: record<id: string, type: string>, enterprise: record<id: string, type: string>, id: string, status: string, type: string, updated_at: string, updated_by: record<id: string, type: string>>
# operationId: get_shield_information_barriers_id
export def "get-shield-information-barriers-id" [
  shield_information_barrier_id: string
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
    path: "/shield_information_barriers/{shield_information_barrier_id}"
    path_params: [{name: shield_information_barrier_id, var: shield_information_barrier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    shield_information_barrier_id: $shield_information_barrier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sign requests
#
# GET /sign_requests
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record, prefill_tags: list, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record, signature_color: string, signers: list, signing_log: record, source_files: list, status: string, type: string>>
# operationId: get_sign_requests
export def "get-sign-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sign_requests"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create sign request
#
# POST /sign_requests
# Returns: record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>
# operationId: post_sign_requests
export def "post-sign-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --are-reminders-enabled: oneof<nothing, bool> # Reminds signers to sign a document on day 3, 8, 13 and 18. Reminders are only sent to outstanding signers. (e.g. true)
  --are-text-signatures-enabled: oneof<nothing, bool> # Disables the usage of signatures generated by typing (text). (default: true, e.g. true)
  --days-valid: int # Number of days after which this request will automatically expire if not completed. (nullable, e.g. 2)
  --declined-redirect-url: string # The uri that a signer will be redirected to after declining to sign a document. (nullable, e.g. https://declined-redirect.com)
  --email-message: string # Message to include in sign request email. The field is cleaned through sanitization of specific characters. However, some html tags are allowed. Links included in the message are also converted to hyperlinks in the email. The message may contain the following html tags including `a`, `abbr`, `acronym`, `b`, `blockquote`, `code`, `em`, `i`, `ul`, `li`, `ol`, and `strong`. Be aware that when the text to html ratio is too high, the email may end up in spam filters. Custom styles on these tags are not allowed. If this field is not passed, a default message will be used. (nullable, e.g. Hello! Please sign the document below)
  --email-subject: string # Subject of sign request email. This is cleaned by sign request. If this field is not passed, a default subject will be used. (nullable, e.g. Sign Request from Acme)
  --external-id: string # This can be used to reference an ID in an external system that the sign request is related to. (nullable, e.g. 123)
  --is-document-preparation-needed: oneof<nothing, bool> # Indicates if the sender should receive a `prepare_url` in the response to complete document preparation via UI. (e.g. true)
  --is-phone-verification-required-to-view: oneof<nothing, bool> # Forces signers to verify a text message prior to viewing the document. You must specify the phone number of signers to have this setting apply to them. (nullable, e.g. true)
  --name: string # Name of the sign request. (e.g. name)
  parent_folder: record # A mini representation of a file version, used when nested under another resource. — shape: {etag?: string, id: string, type: "folder", name?: string, sequence_id?: string}
  --prefill-tags: list # When a document contains sign related tags in the content, you can prefill them using this `prefill_tags` by referencing the 'id' of the tag as the `external_id` field of the prefill tag. — item shape: {checkbox_value?: bool, date_value?: string, document_tag_id?: string, text_value?: string}
  --redirect-url: string # When specified, signature request will be redirected to this url when a document is signed. (nullable, e.g. https://www.example.com)
  --signature-color: string@signature-color-completer # Force a specific signature color (blue, black, or red). (nullable, e.g. blue)
  signers: list # Array of signers for the sign request. 35 is the max number of signers permitted. — item shape: {declined_redirect_url?: string, email: string, embed_url_external_user_id?: string, is_in_person?: bool, login_required?: bool, order?: int, password?: string, redirect_url?: string, role?: "signer"|"approver"|"final_copy_reader", verification_phone_number?: string}
  source_files: list # List of files to create a signing document from. This is currently limited to 10 files. Only the ID and type fields are required for each file. The array will be empty if the `source_files` are deleted. — item shape: {etag?: string, id: string, type: "file", file_version?: record, name?: string, sequence_id: string, sha1: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sign_requests"
    body: {content_type: "application/json", kind: json, fields: [{name: are_reminders_enabled, var: are_reminders_enabled}, {name: are_text_signatures_enabled, var: are_text_signatures_enabled}, {name: days_valid, var: days_valid}, {name: declined_redirect_url, var: declined_redirect_url}, {name: email_message, var: email_message}, {name: email_subject, var: email_subject}, {name: external_id, var: external_id}, {name: is_document_preparation_needed, var: is_document_preparation_needed}, {name: is_phone_verification_required_to_view, var: is_phone_verification_required_to_view}, {name: name, var: name}, {name: parent_folder, var: parent_folder}, {name: prefill_tags, var: prefill_tags}, {name: redirect_url, var: redirect_url}, {name: signature_color, var: signature_color}, {name: signers, var: signers}, {name: source_files, var: source_files}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    are_reminders_enabled: $are_reminders_enabled, are_text_signatures_enabled: $are_text_signatures_enabled, days_valid: $days_valid, declined_redirect_url: $declined_redirect_url, email_message: $email_message, email_subject: $email_subject, external_id: $external_id, is_document_preparation_needed: $is_document_preparation_needed, is_phone_verification_required_to_view: $is_phone_verification_required_to_view, name: $name, parent_folder: $parent_folder, prefill_tags: $prefill_tags, redirect_url: $redirect_url, signature_color: $signature_color, signers: $signers, source_files: $source_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sign request by ID
#
# GET /sign_requests/{sign_request_id}
# Returns: record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>
# operationId: get_sign_requests_id
export def "get-sign-requests-id" [
  sign_request_id: string
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
    path: "/sign_requests/{sign_request_id}"
    path_params: [{name: sign_request_id, var: sign_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sign_request_id: $sign_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel sign request
#
# POST /sign_requests/{sign_request_id}/cancel
# Returns: record<are_reminders_enabled: bool, are_text_signatures_enabled: bool, days_valid: int, declined_redirect_url: string, email_message: string, email_subject: string, external_id: string, is_document_preparation_needed: bool, is_phone_verification_required_to_view: bool, name: string, parent_folder: record<etag: string, id: string, type: string, name: string, sequence_id: string>, prefill_tags: table<checkbox_value: bool, date_value: string, document_tag_id: string, text_value: string>, redirect_url: string, auto_expire_at: string, id: string, prepare_url: string, sign_files: record<files: list<record>, is_ready_for_download: bool>, signature_color: string, signers: table<declined_redirect_url: string, email: string, embed_url_external_user_id: string, is_in_person: bool, login_required: bool, order: int, password: string, redirect_url: string, role: string, verification_phone_number: string, embed_url: string, has_viewed_document: bool, inputs: list, signer_decision: record>, signing_log: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, source_files: table<etag: string, id: string, type: string, file_version: record, name: string, sequence_id: string, sha1: string>, status: string, type: string>
# operationId: post_sign_requests_id_cancel
export def "post-sign-requests-id-cancel" [
  sign_request_id: string
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
    path: "/sign_requests/{sign_request_id}/cancel"
    path_params: [{name: sign_request_id, var: sign_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sign_request_id: $sign_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend sign request
#
# POST /sign_requests/{sign_request_id}/resend
# operationId: post_sign_requests_id_resend
export def "post-sign-requests-id-resend" [
  sign_request_id: string
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
    path: "/sign_requests/{sign_request_id}/resend"
    path_params: [{name: sign_request_id, var: sign_request_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    sign_request_id: $sign_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update all Box Skill cards on file
#
# PUT /skill_invocations/{skill_id}
# operationId: put_skill_invocations_id
export def "put-skill-invocations-id" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: record # The file to assign the cards to. — shape: {id?: string, type?: "file"}
  --file-version: record # The optional file version to assign the cards to. — shape: {id?: string, type?: "file_version"}
  metadata: record # The metadata to set for this skill. This is a list of Box Skills cards. These cards will overwrite any existing Box skill cards on the file. — shape: {cards?: list}
  status: string@status-completer-5 # Defines the status of this invocation. Set this to `success` when setting Skill cards. (e.g. success)
  --usage: record # A descriptor that defines what items are affected by this call. Set this to the default values when setting a card to a `success` state, and leave it out in most other situations. — shape: {unit?: string, value?: float}
]: any -> any {
  $in | http-request {
    method: put
    path: "/skill_invocations/{skill_id}"
    path_params: [{name: skill_id, var: skill_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}, {name: file_version, var: file_version}, {name: metadata, var: metadata}, {name: status, var: status}, {name: usage, var: usage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skill_id: $skill_id, file: $file, file_version: $file_version, metadata: $metadata, status: $status, usage: $usage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List storage policies
#
# GET /storage_policies
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, type: string, name: string>>
# operationId: get_storage_policies
export def "get-storage-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage_policies"
    query: [{name: fields, var: fields, style: csv}, {name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields, marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get storage policy
#
# GET /storage_policies/{storage_policy_id}
# Returns: record<id: string, type: string, name: string>
# operationId: get_storage_policies_id
export def "get-storage-policies-id" [
  storage_policy_id: string
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
    path: "/storage_policies/{storage_policy_id}"
    path_params: [{name: storage_policy_id, var: storage_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_policy_id: $storage_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List storage policy assignments
#
# GET /storage_policy_assignments
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<assigned_to: record, storage_policy: record>>
# operationId: get_storage_policy_assignments
export def "get-storage-policy-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --resolved-for-type: string@resolved-for-type-completer # The target type to return assignments for (required, e.g. user)
  --resolved-for-id: string # The ID of the user or enterprise to return assignments for (required, e.g. 984322)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage_policy_assignments"
    query: [{name: marker, var: marker}, {name: resolved_for_type, var: resolved_for_type, required: true}, {name: resolved_for_id, var: resolved_for_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, resolved_for_type: $resolved_for_type, resolved_for_id: $resolved_for_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign storage policy
#
# POST /storage_policy_assignments
# Returns: record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>
# operationId: post_storage_policy_assignments
export def "post-storage-policy-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assigned_to: record # The user or enterprise to assign the storage policy to. — shape: {id: string, type: "user"|"enterprise"}
  storage_policy: record # The storage policy to assign to the user or enterprise — shape: {id: string, type: "storage_policy"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/storage_policy_assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: assigned_to, var: assigned_to}, {name: storage_policy, var: storage_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assigned_to: $assigned_to, storage_policy: $storage_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign storage policy
#
# DELETE /storage_policy_assignments/{storage_policy_assignment_id}
# operationId: delete_storage_policy_assignments_id
export def "delete-storage-policy-assignments-id" [
  storage_policy_assignment_id: string
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
    path: "/storage_policy_assignments/{storage_policy_assignment_id}"
    path_params: [{name: storage_policy_assignment_id, var: storage_policy_assignment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    storage_policy_assignment_id: $storage_policy_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get storage policy assignment
#
# GET /storage_policy_assignments/{storage_policy_assignment_id}
# Returns: record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>
# operationId: get_storage_policy_assignments_id
export def "get-storage-policy-assignments-id" [
  storage_policy_assignment_id: string
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
    path: "/storage_policy_assignments/{storage_policy_assignment_id}"
    path_params: [{name: storage_policy_assignment_id, var: storage_policy_assignment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_policy_assignment_id: $storage_policy_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update storage policy assignment
#
# PUT /storage_policy_assignments/{storage_policy_assignment_id}
# Returns: record<assigned_to: record<id: string, type: string>, storage_policy: record<id: string, type: string>>
# operationId: put_storage_policy_assignments_id
export def "put-storage-policy-assignments-id" [
  storage_policy_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  storage_policy: record # The storage policy to assign to the user or enterprise — shape: {id: string, type: "storage_policy"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/storage_policy_assignments/{storage_policy_assignment_id}"
    path_params: [{name: storage_policy_assignment_id, var: storage_policy_assignment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: storage_policy, var: storage_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_policy_assignment_id: $storage_policy_assignment_id, storage_policy: $storage_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign task
#
# POST /task_assignments
# Returns: record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>
# operationId: post_task_assignments
export def "post-task-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assign_to: record # The user to assign the task to. — shape: {id?: string, login?: string}
  task: record # The task to assign to a user. — shape: {id: string, type: "task"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/task_assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: assign_to, var: assign_to}, {name: task, var: task}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    assign_to: $assign_to, task: $task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign task
#
# DELETE /task_assignments/{task_assignment_id}
# operationId: delete_task_assignments_id
export def "delete-task-assignments-id" [
  task_assignment_id: string
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
    path: "/task_assignments/{task_assignment_id}"
    path_params: [{name: task_assignment_id, var: task_assignment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    task_assignment_id: $task_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task assignment
#
# GET /task_assignments/{task_assignment_id}
# Returns: record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>
# operationId: get_task_assignments_id
export def "get-task-assignments-id" [
  task_assignment_id: string
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
    path: "/task_assignments/{task_assignment_id}"
    path_params: [{name: task_assignment_id, var: task_assignment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_assignment_id: $task_assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update task assignment
#
# PUT /task_assignments/{task_assignment_id}
# Returns: record<assigned_at: string, assigned_by: record<id: string, type: string, login: string, name: string>, assigned_to: record<id: string, type: string, login: string, name: string>, completed_at: string, id: string, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, reminded_at: string, resolution_state: string, type: string>
# operationId: put_task_assignments_id
export def "put-task-assignments-id" [
  task_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # An optional message by the assignee that can be added to the task. (e.g. Looks good to me)
  --resolution-state: string@resolution-state-completer # The state of the task assigned to the user. * For a task with an `action` value of `complete` this can be `incomplete` or `completed`. * For a task with an `action` of `review` this can be `incomplete`, `approved`, or `rejected`. (e.g. completed)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/task_assignments/{task_assignment_id}"
    path_params: [{name: task_assignment_id, var: task_assignment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: resolution_state, var: resolution_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_assignment_id: $task_assignment_id, message: $message, resolution_state: $resolution_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create task
#
# POST /tasks
# Returns: record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>
# operationId: post_tasks
export def "post-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be * `review` defines an approval task that can be approved or rejected * `complete` defines a general task which can be completed (default: review, e.g. review)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed. * `all_assignees` (default) requires all assignees to review or approve the the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the the task in order for it to be considered completed. (default: all_assignees, e.g. all_assignees)
  --due-at: string # Defines when the task is due. Defaults to `null` if not provided. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  item: record # The file to attach the task to. — shape: {id: string, type: "file"}
  --message: string # An optional message to include with the task. (default: "", e.g. Please review)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: completion_rule, var: completion_rule}, {name: due_at, var: due_at}, {name: item, var: item}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    action: $action, completion_rule: $completion_rule, due_at: $due_at, item: $item, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove task
#
# DELETE /tasks/{task_id}
# operationId: delete_tasks_id
export def "delete-tasks-id" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/tasks/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task
#
# GET /tasks/{task_id}
# Returns: record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>
# operationId: get_tasks_id
export def "get-tasks-id" [
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
    path: "/tasks/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update task
#
# PUT /tasks/{task_id}
# Returns: record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>
# operationId: put_tasks_id
export def "put-tasks-id" [
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
  --action: string@action-completer # The action the task assignee will be prompted to do. Must be * `review` defines an approval task that can be approved or rejected * `complete` defines a general task which can be completed (e.g. review)
  --completion-rule: string@completion-rule-completer # Defines which assignees need to complete this task before the task is considered completed. * `all_assignees` (default) requires all assignees to review or approve the the task in order for it to be considered completed. * `any_assignee` accepts any one assignee to review or approve the the task in order for it to be considered completed. (e.g. all_assignees)
  --due-at: string # When the task is due at. (format: date-time, e.g. 2012-12-12T10:53:43-08:00)
  --message: string # The message included with the task. (e.g. Please review)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: completion_rule, var: completion_rule}, {name: due_at, var: due_at}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, action: $action, completion_rule: $completion_rule, due_at: $due_at, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List task assignments
#
# GET /tasks/{task_id}/assignments
# Returns: record<entries: table<assigned_at: string, assigned_by: record, assigned_to: record, completed_at: string, id: string, item: record, message: string, reminded_at: string, resolution_state: string, type: string>, total_count: int>
# operationId: get_tasks_id_assignments
export def "get-tasks-id-assignments" [
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
    path: "/tasks/{task_id}/assignments"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List terms of service user statuses
#
# GET /terms_of_service_user_statuses
# Returns: record<entries: table<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record, type: string, user: record>, total_count: int>
# operationId: get_terms_of_service_user_statuses
export def "get-terms-of-service-user-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tos-id: string # The ID of the terms of service. (required, e.g. 324234)
  --user-id: string # Limits results to the given user ID. (e.g. 123334)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/terms_of_service_user_statuses"
    query: [{name: tos_id, var: tos_id, required: true}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tos_id: $tos_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create terms of service status for new user
#
# POST /terms_of_service_user_statuses
# Returns: record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record<id: string, type: string, login: string, name: string>>
# operationId: post_terms_of_service_user_statuses
export def "post-terms-of-service-user-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-accepted: oneof<nothing, bool> # Whether the user has accepted the terms. (e.g. true)
  tos: record # The terms of service to set the status for. — shape: {id: string, type: "terms_of_service"}
  user: record # The user to set the status for. — shape: {id: string, type: "user"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/terms_of_service_user_statuses"
    body: {content_type: "application/json", kind: json, fields: [{name: is_accepted, var: is_accepted, required: true}, {name: tos, var: tos}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    is_accepted: $is_accepted, tos: $tos, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terms of service status for existing user
#
# PUT /terms_of_service_user_statuses/{terms_of_service_user_status_id}
# Returns: record<created_at: string, id: string, is_accepted: bool, modified_at: string, tos: record<id: string, type: string>, type: string, user: record<id: string, type: string, login: string, name: string>>
# operationId: put_terms_of_service_user_statuses_id
export def "put-terms-of-service-user-statuses-id" [
  terms_of_service_user_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-accepted: oneof<nothing, bool> # Whether the user has accepted the terms. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/terms_of_service_user_statuses/{terms_of_service_user_status_id}"
    path_params: [{name: terms_of_service_user_status_id, var: terms_of_service_user_status_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_accepted, var: is_accepted, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    terms_of_service_user_status_id: $terms_of_service_user_status_id, is_accepted: $is_accepted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List terms of services
#
# GET /terms_of_services
# Returns: record<entries: table<id: string, type: string, created_at: string, enterprise: record, modified_at: string, status: string, text: string, tos_type: string>, total_count: int>
# operationId: get_terms_of_services
export def "get-terms-of-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tos-type: string@tos-type-completer # Limits the results to the terms of service of the given type. (e.g. managed)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/terms_of_services"
    query: [{name: tos_type, var: tos_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tos_type: $tos_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create terms of service
#
# POST /terms_of_services
# Returns: record<action: string, completion_rule: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, due_at: string, id: string, is_completed: bool, item: record<etag: string, id: string, type: string, file_version: record<id: string, type: string, sha1: string>, name: string, sequence_id: string, sha1: string>, message: string, task_assignment_collection: record<entries: list<record>, total_count: int>, type: string>
# operationId: post_terms_of_services
export def "post-terms-of-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  text: string # The terms of service text to display to users. The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
  --tos-type: string@tos-type-completer # The type of user to set the terms of service for. (e.g. managed)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/terms_of_services"
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}, {name: text, var: text}, {name: tos_type, var: tos_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, text: $text, tos_type: $tos_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get terms of service
#
# GET /terms_of_services/{terms_of_service_id}
# Returns: record<id: string, type: string, created_at: string, enterprise: record<id: string, name: string, type: string>, modified_at: string, status: string, text: string, tos_type: string>
# operationId: get_terms_of_services_id
export def "get-terms-of-services-id" [
  terms_of_service_id: string
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
    path: "/terms_of_services/{terms_of_service_id}"
    path_params: [{name: terms_of_service_id, var: terms_of_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    terms_of_service_id: $terms_of_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update terms of service
#
# PUT /terms_of_services/{terms_of_service_id}
# Returns: record<id: string, type: string, created_at: string, enterprise: record<id: string, name: string, type: string>, modified_at: string, status: string, text: string, tos_type: string>
# operationId: put_terms_of_services_id
export def "put-terms-of-services-id" [
  terms_of_service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-6 # Whether this terms of service is active. (e.g. enabled)
  text: string # The terms of service text to display to users. The text can be set to empty if the `status` is set to `disabled`. (e.g. By collaborating on this file you are accepting...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/terms_of_services/{terms_of_service_id}"
    path_params: [{name: terms_of_service_id, var: terms_of_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    terms_of_service_id: $terms_of_service_id, status: $status, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List enterprise users
#
# GET /users
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record, phone: string, space_amount: int, space_used: int, status: string, timezone: string>>
# operationId: get_users
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-term: string # Limits the results to only users who's `name` or `login` start with the search term. For externally managed users, the search term needs to completely match the in order to find the user, and it will only return one user at a time. (e.g. john)
  --user-type: string@user-type-completer # Limits the results to the kind of user specified. * `all` returns every kind of user for whom the `login` or `name` partially matches the `filter_term`. It will only return an external user if the login matches the `filter_term` completely, and in that case it will only return that user. * `managed` returns all managed and app users for whom the `login` or `name` partially matches the `filter_term`. * `external` returns all external users for whom the `login` matches the `filter_term` exactly. (e.g. managed)
  --external-app-user-id: string # Limits the results to app users with the given `external_app_user_id` value. When creating an app user, an `external_app_user_id` value can be set. This value can then be used in this endpoint to find any users that match that `external_app_user_id` value. (e.g. my-user-1234)
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --usemarker: oneof<nothing, bool> # Specifies whether to use marker-based pagination instead of offset-based pagination. Only one pagination method can be used at a time. By setting this value to true, the API will return a `marker` field that can be passed as a parameter to this endpoint to get the next page of the response. (e.g. true)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: filter_term, var: filter_term}, {name: user_type, var: user_type}, {name: external_app_user_id, var: external_app_user_id}, {name: fields, var: fields, style: csv}, {name: offset, var: offset}, {name: limit, var: limit}, {name: usemarker, var: usemarker}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_term: $filter_term, user_type: $user_type, external_app_user_id: $external_app_user_id, fields: $fields, offset: $offset, limit: $limit, usemarker: $usemarker, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user
#
# POST /users
# Returns: record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>
# operationId: post_users
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --address: string # The user’s address (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --can-see-managed-users: oneof<nothing, bool> # Whether the user can see other enterprise users in their contact list (e.g. true)
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users. (e.g. my-user-1234)
  --is-exempt-from-device-limits: oneof<nothing, bool> # Whether to exempt the user from enterprise device limits (e.g. true)
  --is-exempt-from-login-verification: oneof<nothing, bool> # Whether the user must use two-factor authentication (e.g. true)
  --is-external-collab-restricted: oneof<nothing, bool> # Whether the user is allowed to collaborate with users outside their enterprise (e.g. true)
  --is-platform-access-only: oneof<nothing, bool> # Specifies that the user is an app user. (e.g. true)
  --is-sync-enabled: oneof<nothing, bool> # Whether the user can use Box Sync (e.g. true)
  --job-title: string # The user’s job title (e.g. CEO)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](/guides/api-calls/language-codes) format. (e.g. en)
  --login: string # The email address the user uses to log in Required, unless `is_platform_access_only` is set to `true`. (e.g. boss@box.com)
  name: string # The name of the user (e.g. Aaron Levie)
  --phone: string # The user’s phone number (e.g. 6509241374)
  --role: string@role-completer-3 # The user’s enterprise role (e.g. user)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --status: string@status-completer-7 # The user's account status (e.g. active)
  --timezone: string # The user's timezone (format: timezone, e.g. Africa/Bujumbura)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {name?: string, type?: "tracking_code", value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: can_see_managed_users, var: can_see_managed_users}, {name: external_app_user_id, var: external_app_user_id}, {name: is_exempt_from_device_limits, var: is_exempt_from_device_limits}, {name: is_exempt_from_login_verification, var: is_exempt_from_login_verification}, {name: is_external_collab_restricted, var: is_external_collab_restricted}, {name: is_platform_access_only, var: is_platform_access_only}, {name: is_sync_enabled, var: is_sync_enabled}, {name: job_title, var: job_title}, {name: language, var: language}, {name: login, var: login}, {name: name, var: name}, {name: phone, var: phone}, {name: role, var: role}, {name: space_amount, var: space_amount}, {name: status, var: status}, {name: timezone, var: timezone}, {name: tracking_codes, var: tracking_codes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    fields: $fields, address: $address, can_see_managed_users: $can_see_managed_users, external_app_user_id: $external_app_user_id, is_exempt_from_device_limits: $is_exempt_from_device_limits, is_exempt_from_login_verification: $is_exempt_from_login_verification, is_external_collab_restricted: $is_external_collab_restricted, is_platform_access_only: $is_platform_access_only, is_sync_enabled: $is_sync_enabled, job_title: $job_title, language: $language, login: $login, name: $name, phone: $phone, role: $role, space_amount: $space_amount, status: $status, timezone: $timezone, tracking_codes: $tracking_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current user
#
# GET /users/me
# Returns: record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>
# operationId: get_users_me
export def "get-users-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me"
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create jobs to terminate users session
#
# POST /users/terminate_sessions
# Returns: record<message: string>
# operationId: post_users_terminate_sessions
export def "post-users-terminate-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list<string> # A list of user IDs (e.g. [123456, 456789])
  user_logins: list<string> # A list of user logins (e.g. [user@sample.com, user2@sample.com])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/terminate_sessions"
    body: {content_type: "application/json", kind: json, fields: [{name: user_ids, var: user_ids}, {name: user_logins, var: user_logins}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    user_ids: $user_ids, user_logins: $user_logins
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /users/{user_id}
# operationId: delete_users_id
export def "delete-users-id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Whether the user will receive email notification of the deletion (e.g. true)
  --force: oneof<nothing, bool> # Whether the user should be deleted even if this user still own files (e.g. true)
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: notify, var: notify}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, notify: $notify, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /users/{user_id}
# Returns: record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>
# operationId: get_users_id
export def "get-users-id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PUT /users/{user_id}
# Returns: record<id: string, type: string, login: string, name: string, address: string, avatar_url: string, created_at: string, job_title: string, language: string, max_upload_size: int, modified_at: string, notification_email: record<email: string, is_confirmed: bool>, phone: string, space_amount: int, space_used: int, status: string, timezone: string>
# operationId: put_users_id
export def "put-users-id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --address: string # The user’s address (e.g. 900 Jefferson Ave, Redwood City, CA 94063)
  --can-see-managed-users: oneof<nothing, bool> # Whether the user can see other enterprise users in their contact list (e.g. true)
  --enterprise: string # Set this to `null` to roll the user out of the enterprise and make them a free user (nullable)
  --external-app-user-id: string # An external identifier for an app user, which can be used to look up the user. This can be used to tie user IDs from external identity providers to Box users. Note: In order to update this field, you need to request a token using the application that created the app user. (e.g. my-user-1234)
  --is-exempt-from-device-limits: oneof<nothing, bool> # Whether to exempt the user from enterprise device limits (e.g. true)
  --is-exempt-from-login-verification: oneof<nothing, bool> # Whether the user must use two-factor authentication (e.g. true)
  --is-external-collab-restricted: oneof<nothing, bool> # Whether the user is allowed to collaborate with users outside their enterprise (e.g. true)
  --is-password-reset-required: oneof<nothing, bool> # Whether the user is required to reset their password (e.g. true)
  --is-sync-enabled: oneof<nothing, bool> # Whether the user can use Box Sync (e.g. true)
  --job-title: string # The user’s job title (e.g. CEO)
  --language: string # The language of the user, formatted in modified version of the [ISO 639-1](/guides/api-calls/language-codes) format. (e.g. en)
  --login: string # The email address the user uses to log in Note: If the target user's email is not confirmed, then the primary login address cannot be changed. (e.g. somename@box.com)
  --name: string # The name of the user (e.g. Aaron Levie)
  --notification-email: record # An alternate notification email address to which email notifications are sent. When it's confirmed, this will be the email address to which notifications are sent instead of to the primary email address. Set this value to `null` to remove the notification email. (nullable) — shape: {email?: string}
  --notify: oneof<nothing, bool> # Whether the user should receive an email when they are rolled out of an enterprise (e.g. true)
  --phone: string # The user’s phone number (e.g. 6509241374)
  --role: string@role-completer-3 # The user’s enterprise role (e.g. user)
  --space-amount: int # The user’s total available space in bytes. Set this to `-1` to indicate unlimited storage. (format: int64, e.g. 11345156112)
  --status: string@status-completer-7 # The user's account status (e.g. active)
  --timezone: string # The user's timezone (format: timezone, e.g. Africa/Bujumbura)
  --tracking-codes: list # Tracking codes allow an admin to generate reports from the admin console and assign an attribute to a specific group of users. This setting must be enabled for an enterprise before it can be used. — item shape: {name?: string, type?: "tracking_code", value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: can_see_managed_users, var: can_see_managed_users}, {name: enterprise, var: enterprise}, {name: external_app_user_id, var: external_app_user_id}, {name: is_exempt_from_device_limits, var: is_exempt_from_device_limits}, {name: is_exempt_from_login_verification, var: is_exempt_from_login_verification}, {name: is_external_collab_restricted, var: is_external_collab_restricted}, {name: is_password_reset_required, var: is_password_reset_required}, {name: is_sync_enabled, var: is_sync_enabled}, {name: job_title, var: job_title}, {name: language, var: language}, {name: login, var: login}, {name: name, var: name}, {name: notification_email, var: notification_email}, {name: notify, var: notify}, {name: phone, var: phone}, {name: role, var: role}, {name: space_amount, var: space_amount}, {name: status, var: status}, {name: timezone, var: timezone}, {name: tracking_codes, var: tracking_codes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, fields: $fields, address: $address, can_see_managed_users: $can_see_managed_users, enterprise: $enterprise, external_app_user_id: $external_app_user_id, is_exempt_from_device_limits: $is_exempt_from_device_limits, is_exempt_from_login_verification: $is_exempt_from_login_verification, is_external_collab_restricted: $is_external_collab_restricted, is_password_reset_required: $is_password_reset_required, is_sync_enabled: $is_sync_enabled, job_title: $job_title, language: $language, login: $login, name: $name, notification_email: $notification_email, notify: $notify, phone: $phone, role: $role, space_amount: $space_amount, status: $status, timezone: $timezone, tracking_codes: $tracking_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user avatar
#
# DELETE /users/{user_id}/avatar
# operationId: delete_users_id_avatar
export def "delete-users-id-avatar" [
  user_id: string
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
    path: "/users/{user_id}/avatar"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user avatar
#
# GET /users/{user_id}/avatar
# Returns: binary
# operationId: get_users_id_avatar
export def "get-users-id-avatar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/avatar"
    path_params: [{name: user_id, var: user_id}]
    accept: ["image/jpg", "application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add or update user avatar
#
# POST /users/{user_id}/avatar
# Returns: record<pic_urls: record<large: string, preview: string, small: string>>
# operationId: post_users_id_avatar
export def "post-users-id-avatar" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  pic: string # The image file to be uploaded to Box. Accepted file extensions are `.jpg` or `.png`. The maximum file size is 1MB. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/avatar"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: pic, var: pic}], files: [pic]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    user_id: $user_id, pic: $pic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user's email aliases
#
# GET /users/{user_id}/email_aliases
# Returns: record<entries: table<email: string, id: string, is_confirmed: bool, type: string>, total_count: int>
# operationId: get_users_id_email_aliases
export def "get-users-id-email-aliases" [
  user_id: string
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
    path: "/users/{user_id}/email_aliases"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create email alias
#
# POST /users/{user_id}/email_aliases
# Returns: record<email: string, id: string, is_confirmed: bool, type: string>
# operationId: post_users_id_email_aliases
export def "post-users-id-email-aliases" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address to add to the account as an alias. Note: The domain of the email alias needs to be registered to your enterprise. See the [domain verification guide]( https://support.box.com/hc/en-us/articles/4408619650579-Domain-Verification ) for steps to add a new domain. (e.g. alias@example.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/email_aliases"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove email alias
#
# DELETE /users/{user_id}/email_aliases/{email_alias_id}
# operationId: delete_users_id_email_aliases_id
export def "delete-users-id-email-aliases-id" [
  user_id: string
  email_alias_id: string
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
    path: "/users/{user_id}/email_aliases/{email_alias_id}"
    path_params: [{name: user_id, var: user_id}, {name: email_alias_id, var: email_alias_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, email_alias_id: $email_alias_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer owned folders
#
# PUT /users/{user_id}/folders/0
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, content_created_at: string, content_modified_at: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, folder_upload_email: record<access: string, email: string>, item_collection: record<limit: int, offset: int, order: list<record>, total_count: int, entries: list<any>>, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, size: int, trashed_at: string>
# operationId: put_users_id_folders_0
export def "put-users-id-folders-0" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --notify: oneof<nothing, bool> # Determines if users should receive email notification for the action performed. (e.g. true)
  owned_by: record # The user who the folder will be transferred to — shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{user_id}/folders/0"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: fields, var: fields, style: csv}, {name: notify, var: notify}]
    body: {content_type: "application/json", kind: json, fields: [{name: owned_by, var: owned_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, fields: $fields, notify: $notify, owned_by: $owned_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user's groups
#
# GET /users/{user_id}/memberships
# Returns: record<limit: int, offset: int, order: table<by: string, direction: string>, total_count: int, entries: table<created_at: string, group: record, id: string, modified_at: string, role: string, type: string, user: record>>
# operationId: get_users_id_memberships
export def "get-users-id-memberships" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --offset: int # The offset of the item at which to begin the response. Queries with offset parameter value exceeding 10000 will be rejected with a 400 response. (format: int64, default: 0, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/memberships"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create web link
#
# POST /web_links
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: post_web_links
export def "post-web-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the web link. (e.g. Cloud Content Management)
  --name: string # Name of the web link. Defaults to the URL if not set. (e.g. Box Website)
  parent: record # The parent folder to create the web link within. — shape: {id: string}
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
  url: string # The URL that this web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/web_links"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}, {name: shared_link, var: shared_link}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, name: $name, parent: $parent, shared_link: $shared_link, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove web link
#
# DELETE /web_links/{web_link_id}
# operationId: delete_web_links_id
export def "delete-web-links-id" [
  web_link_id: string
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
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    web_link_id: $web_link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get web link
#
# GET /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: get_web_links_id
export def "get-web-links-id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --boxapi: string # The URL, and optional password, for the shared link of this item. This header can be used to access items that have not been explicitly shared with a user. Use the format `shared_link=[link]` or if a password is required then use `shared_link=[link]&shared_link_password=[password]`. This header can be used on the file or folder shared, as well as on any files or folders nested within the item. (e.g. shared_link=[link]&shared_link_password=[password])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    header: [{name: boxapi, var: boxapi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, boxapi: $boxapi
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore web link
#
# POST /web_links/{web_link_id}
# Returns: record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, trashed_at: string, type: string, url: string>
# operationId: post_web_links_id
export def "post-web-links-id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
  --name: string # An optional new name for the web link. (e.g. Restored.docx)
  --parent: record # The parent for this item — shape: {id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent, var: parent}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields, name: $name, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update web link
#
# PUT /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: put_web_links_id
export def "put-web-links-id" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A new description of the web link. (e.g. Cloud Content Management)
  --name: string # A new name for the web link. Defaults to the URL if not set. (e.g. Box Website)
  --parent: record # The parent for this item — shape: {id?: string}
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, unshared_at?: string, vanity_name?: string}
  --url: string # The new URL that the web link links to. Must start with `"http://"` or `"https://"`. (e.g. https://box.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: parent, var: parent}, {name: shared_link, var: shared_link}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, description: $description, name: $name, parent: $parent, shared_link: $shared_link, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add shared link to web link
#
# PUT /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: put_web_links_id#add_shared_link
export def "put-web-links-idadd-shared-link" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to create on the web link. Use an empty object (`{}`) to use the default settings for shared links. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shared link for web link
#
# GET /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: get_web_links_id#get_shared_link
export def "get-web-links-idget-shared-link" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove shared link from web link
#
# PUT /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: put_web_links_id#remove_shared_link
export def "put-web-links-idremove-shared-link" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # By setting this value to `null`, the shared link is removed from the web link. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update shared link on web link
#
# PUT /web_links/{web_link_id}
# Returns: record<etag: string, id: string, type: string, name: string, sequence_id: string, url: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, shared_link: record<access: string, download_count: int, download_url: string, effective_access: string, effective_permission: string, is_password_enabled: bool, permissions: record<can_download: bool, can_edit: bool, can_preview: bool>, preview_count: int, unshared_at: string, url: string, vanity_name: string, vanity_url: string>, trashed_at: string>
# operationId: put_web_links_id#update_shared_link
export def "put-web-links-idupdate-shared-link" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Explicitly request the `shared_link` fields to be returned for this item. (required, e.g. shared_link)
  --shared-link: record # The settings for the shared link to update. — shape: {access?: "open"|"company"|"collaborators", password?: string, permissions?: record, unshared_at?: string, vanity_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/web_links/{web_link_id}"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shared_link, var: shared_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields, shared_link: $shared_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently remove web link
#
# DELETE /web_links/{web_link_id}/trash
# operationId: delete_web_links_id_trash
export def "delete-web-links-id-trash" [
  web_link_id: string
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
    path: "/web_links/{web_link_id}/trash"
    path_params: [{name: web_link_id, var: web_link_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    web_link_id: $web_link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trashed web link
#
# GET /web_links/{web_link_id}/trash
# Returns: record<created_at: string, created_by: record<id: string, type: string, login: string, name: string>, description: string, etag: string, id: string, item_status: string, modified_at: string, modified_by: record<id: string, type: string, login: string, name: string>, name: string, owned_by: record<id: string, type: string, login: string, name: string>, parent: record<etag: string, id: string, type: string, name: string, sequence_id: string>, path_collection: record<entries: list<record>, total_count: int>, purged_at: string, sequence_id: string, shared_link: string, trashed_at: string, type: string, url: string>
# operationId: get_web_links_id_trash
export def "get-web-links-id-trash" [
  web_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # A comma-separated list of attributes to include in the response. This can be used to request fields that are not normally returned in a standard response. Be aware that specifying this parameter will have the effect that none of the standard fields are returned in the response unless explicitly specified, instead only fields for the mini representation are returned, additional to the fields requested. (e.g. [id, type, name])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/web_links/{web_link_id}/trash"
    path_params: [{name: web_link_id, var: web_link_id}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    web_link_id: $web_link_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all webhooks
#
# GET /webhooks
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<id: string, target: record, type: string>>
# operationId: get_webhooks
export def "get-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: marker, var: marker}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create webhook
#
# POST /webhooks
# Returns: record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>
# operationId: post_webhooks
export def "post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The URL that is notified by this webhook (e.g. https://example.com/webhooks)
  target: record # The item that will trigger the webhook — shape: {id?: string, type?: "file"|"folder"}
  triggers: list<string> # An array of event names that this webhook is to be triggered for (e.g. [FILE.UPLOADED])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: target, var: target}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    address: $address, target: $target, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove webhook
#
# DELETE /webhooks/{webhook_id}
# operationId: delete_webhooks_id
export def "delete-webhooks-id" [
  webhook_id: string
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
    path: "/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhook
#
# GET /webhooks/{webhook_id}
# Returns: record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>
# operationId: get_webhooks_id
export def "get-webhooks-id" [
  webhook_id: string
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
    path: "/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update webhook
#
# PUT /webhooks/{webhook_id}
# Returns: record<id: string, target: record<id: string, type: string>, type: string, address: string, created_at: string, created_by: record<id: string, type: string, login: string, name: string>, triggers: list<string>>
# operationId: put_webhooks_id
export def "put-webhooks-id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The URL that is notified by this webhook (e.g. https://example.com/webhooks)
  --target: record # The item that will trigger the webhook — shape: {id?: string, type?: "file"|"folder"}
  --triggers: list<string> # An array of event names that this webhook is to be triggered for (e.g. [FILE.UPLOADED])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: target, var: target}, {name: triggers, var: triggers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, address: $address, target: $target, triggers: $triggers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List workflows
#
# GET /workflows
# Returns: record<limit: int, next_marker: int, prev_marker: int, entries: table<description: string, id: string, is_enabled: bool, name: string, type: string, flows: list>>
# operationId: get_workflows
export def "get-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --folder-id: string # The unique identifier that represent a folder. The ID for any folder can be determined by visiting this folder in the web application and copying the ID from the URL. For example, for the URL `https://*.app.box.com/folder/123` the `folder_id` is `123`. The root folder of a Box account is always represented by the ID `0`. (required, e.g. 12345)
  --trigger-type: string # Type of trigger to search for. (e.g. WORKFLOW_MANUAL_START)
  --limit: int # The maximum number of items to return per page. (format: int64, e.g. 1000)
  --marker: string # Defines the position marker at which to begin returning results. This is used when paginating using marker-based pagination. This requires `usemarker` to be set to `true`. (e.g. JV9IRGZmieiBasejOG9yDCRNgd2ymoZIbjsxbJMjIs3kioVii)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows"
    query: [{name: folder_id, var: folder_id, required: true}, {name: trigger_type, var: trigger_type}, {name: limit, var: limit}, {name: marker, var: marker}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, trigger_type: $trigger_type, limit: $limit, marker: $marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts workflow based on request body
#
# POST /workflows/{workflow_id}/start
# operationId: post_workflows_id_start
export def "post-workflows-id-start" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  files: list # The array of files for which the workflow should start. All files must be in the workflow's configured folder. — item shape: {id?: string, type?: "file"}
  flow: record # The flow that will be triggered — shape: {id?: string, type?: string}
  folder: record # The folder object for which the workflow is configured. — shape: {id?: string, type?: "folder"}
  --outcomes: list # A list of outcomes required to be configured at start time. — item shape: {id?: string, parameter?: string, type?: "outcome"}
  --type: string@type-completer-6 # The type of the parameters object (e.g. workflow_parameters)
]: any -> any {
  $in | http-request {
    method: post
    path: "/workflows/{workflow_id}/start"
    path_params: [{name: workflow_id, var: workflow_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: files, var: files}, {name: flow, var: flow}, {name: folder, var: folder}, {name: outcomes, var: outcomes}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workflow_id: $workflow_id, files: $files, flow: $flow, folder: $folder, outcomes: $outcomes, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create zip download
#
# POST /zip_downloads
# Returns: record<download_url: string, expires_at: string, name_conflicts: list<list<record>>, status_url: string>
# operationId: post_zip_downloads
export def "post-zip-downloads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --download-file-name: string # The optional name of the `zip` archive. This name will be appended by the `.zip` file extension, for example `January Financials.zip`. (e.g. January Financials)
  items: list # A list of items to add to the `zip` archive. These can be folders or files. — item shape: {id: string, type: "file"|"folder."}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/zip_downloads"
    body: {content_type: "application/json", kind: json, fields: [{name: download_file_name, var: download_file_name}, {name: items, var: items}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    download_file_name: $download_file_name, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download zip archive
#
# GET /zip_downloads/{zip_download_id}/content
# Returns: binary
# operationId: get_zip_downloads_id_content
export def "get-zip-downloads-id-content" [
  zip_download_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/zip_downloads/{zip_download_id}/content"
    path_params: [{name: zip_download_id, var: zip_download_id}]
    accept: ["application/octet-stream", "application/json"]
    ok: [200]
    base_url: "https://dl.boxcloud.com/2.0"
    auth: none
  } {
    zip_download_id: $zip_download_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get zip download status
#
# GET /zip_downloads/{zip_download_id}/status
# Returns: record<downloaded_file_count: int, skipped_file_count: int, skipped_folder_count: int, state: string, total_file_count: int>
# operationId: get_zip_downloads_id_status
export def "get-zip-downloads-id-status" [
  zip_download_id: string
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
    path: "/zip_downloads/{zip_download_id}/status"
    path_params: [{name: zip_download_id, var: zip_download_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    zip_download_id: $zip_download_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
