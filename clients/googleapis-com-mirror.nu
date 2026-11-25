# Auto-generated client for Google Mirror v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/mirror/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_MIRROR_TOKEN

const CLIENT = {
  base_url: "https://www.googleapis.com/mirror/v1"
  token_env_var: "GOOGLE_MIRROR_TOKEN"
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

def base-url-completer [] { ["https://www.googleapis.com/mirror/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def order-by-completer [] { ["displayTime" "writeTime"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    mirror-accounts-insert: "record<authTokens: table<authToken: string, type: string>, features: list<string>, password: string, userData: table<key: string, value: string>>"
    mirror-contacts-list: "record<items: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, kind: string>"
    mirror-contacts-insert: "record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>"
    mirror-contacts-get: "record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>"
    mirror-contacts-patch: "record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>"
    mirror-contacts-update: "record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>"
    mirror-locations-list: "record<items: table<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, kind: string>"
    mirror-locations-get: "record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>"
    mirror-settings-get: "record<id: string, kind: string, value: string>"
    mirror-subscriptions-list: "record<items: table<callbackUrl: string, collection: string, id: string, kind: string, notification: record, operation: list, updated: string, userToken: string, verifyToken: string>, kind: string>"
    mirror-subscriptions-insert: "record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string>"
    mirror-subscriptions-update: "record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string>"
    mirror-timeline-list: "record<items: table<attachments: list, bundleId: string, canonicalUrl: string, created: string, creator: record, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record, menuItems: list, notification: record, pinScore: int, recipients: list, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>, kind: string, nextPageToken: string>"
    mirror-timeline-insert: "record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>"
    mirror-timeline-get: "record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>"
    mirror-timeline-patch: "record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>"
    mirror-timeline-update: "record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>"
    mirror-timeline-attachments-list: "record<items: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, kind: string>"
    mirror-timeline-attachments-insert: "record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>"
    mirror-timeline-attachments-get: "record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["mirror-accounts-insert" "mirror-contacts-list" "mirror-contacts-insert" "mirror-contacts-delete" "mirror-contacts-get" "mirror-contacts-patch" "mirror-contacts-update" "mirror-locations-list" "mirror-locations-get" "mirror-settings-get" "mirror-subscriptions-list" "mirror-subscriptions-insert" "mirror-subscriptions-delete" "mirror-subscriptions-update" "mirror-timeline-list" "mirror-timeline-insert" "mirror-timeline-delete" "mirror-timeline-get" "mirror-timeline-patch" "mirror-timeline-update" "mirror-timeline-attachments-list" "mirror-timeline-attachments-insert" "mirror-timeline-attachments-delete" "mirror-timeline-attachments-get" "commands"] | sort) } | get name | first)
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

# Inserts a new account for a user
#
# POST /accounts/{userToken}/{accountType}/{accountName}
# Returns: record<authTokens: table<authToken: string, type: string>, features: list<string>, password: string, userData: table<key: string, value: string>>
# operationId: mirror.accounts.insert
export def "mirror-accounts-insert" [
  user_token: string
  account_type: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --auth-tokens: list # item shape: {authToken?: string, type?: string}
  --features: list<string>
  --password: string
  --user-data: list # item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{userToken}/{accountType}/{accountName}"
    path_params: [{name: userToken, var: user_token}, {name: accountType, var: account_type}, {name: accountName, var: account_name}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: authTokens, var: auth_tokens}, {name: features, var: features}, {name: password, var: password}, {name: userData, var: user_data}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_token: $user_token, account_type: $account_type, account_name: $account_name, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, auth_tokens: $auth_tokens, features: $features, password: $password, user_data: $user_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of contacts for the authenticated user.
#
# GET /contacts
# Returns: record<items: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, kind: string>
# operationId: mirror.contacts.list
export def "mirror-contacts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new contact.
#
# POST /contacts
# Returns: record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>
# operationId: mirror.contacts.insert
export def "mirror-contacts-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --id: string # An ID for this contact. This is generated by the application and is treated as an opaque token.
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptCommands, var: accept_commands}, {name: acceptTypes, var: accept_types}, {name: displayName, var: display_name}, {name: id, var: id}, {name: imageUrls, var: image_urls}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: priority, var: priority}, {name: sharingFeatures, var: sharing_features}, {name: source, var: source}, {name: speakableName, var: speakable_name}, {name: type, var: type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, accept_commands: $accept_commands, accept_types: $accept_types, display_name: $display_name, id: $id, image_urls: $image_urls, kind: $kind, phone_number: $phone_number, priority: $priority, sharing_features: $sharing_features, source: $source, speakable_name: $speakable_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a contact.
#
# DELETE /contacts/{id}
# operationId: mirror.contacts.delete
export def "mirror-contacts-delete" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single contact by ID.
#
# GET /contacts/{id}
# Returns: record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>
# operationId: mirror.contacts.get
export def "mirror-contacts-get" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a contact in place. This method supports patch semantics.
#
# PATCH /contacts/{id}
# Returns: record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>
# operationId: mirror.contacts.patch
export def "mirror-contacts-patch" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --body-id: string # An ID for this contact. This is generated by the application and is treated as an opaque token. (spec name: id)
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptCommands, var: accept_commands}, {name: acceptTypes, var: accept_types}, {name: displayName, var: display_name}, {name: id, var: body_id}, {name: imageUrls, var: image_urls}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: priority, var: priority}, {name: sharingFeatures, var: sharing_features}, {name: source, var: source}, {name: speakableName, var: speakable_name}, {name: type, var: type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, accept_commands: $accept_commands, accept_types: $accept_types, display_name: $display_name, body_id: $body_id, image_urls: $image_urls, kind: $kind, phone_number: $phone_number, priority: $priority, sharing_features: $sharing_features, source: $source, speakable_name: $speakable_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a contact in place.
#
# PUT /contacts/{id}
# Returns: record<acceptCommands: table<type: string>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>
# operationId: mirror.contacts.update
export def "mirror-contacts-update" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --accept-commands: list # A list of voice menu commands that a contact can handle. Glass shows up to three contacts for each voice menu command. If there are more than that, the three contacts with the highest priority are shown for that particular command. — item shape: {type?: string}
  --accept-types: list<string> # A list of MIME types that a contact supports. The contact will be shown to the user if any of its acceptTypes matches any of the types of the attachments on the item. If no acceptTypes are given, the contact will be shown for all items.
  --display-name: string # The name to display for this contact.
  --body-id: string # An ID for this contact. This is generated by the application and is treated as an opaque token. (spec name: id)
  --image-urls: list<string> # Set of image URLs to display for a contact. Most contacts will have a single image, but a "group" contact may include up to 8 image URLs and they will be resized and cropped into a mosaic on the client.
  --kind: string # The type of resource. This is always mirror#contact. (default: mirror#contact)
  --phone-number: string # Primary phone number for the contact. This can be a fully-qualified number, with country calling code and area code, or a local number.
  --priority: int # Priority for the contact to determine ordering in a list of contacts. Contacts with higher priorities will be shown before ones with lower priorities. (format: uint32)
  --sharing-features: list<string> # A list of sharing features that a contact can handle. Allowed values are: - ADD_CAPTION
  --source: string # The ID of the application that created this contact. This is populated by the API
  --speakable-name: string # Name of this contact as it should be pronounced. If this contact's name must be spoken as part of a voice disambiguation menu, this name is used as the expected pronunciation. This is useful for contact names with unpronounceable characters or whose display spelling is otherwise not phonetic.
  --type: string # The type for this contact. This is used for sorting in UIs. Allowed values are: - INDIVIDUAL - Represents a single person. This is the default. - GROUP - Represents more than a single person.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptCommands, var: accept_commands}, {name: acceptTypes, var: accept_types}, {name: displayName, var: display_name}, {name: id, var: body_id}, {name: imageUrls, var: image_urls}, {name: kind, var: kind}, {name: phoneNumber, var: phone_number}, {name: priority, var: priority}, {name: sharingFeatures, var: sharing_features}, {name: source, var: source}, {name: speakableName, var: speakable_name}, {name: type, var: type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, accept_commands: $accept_commands, accept_types: $accept_types, display_name: $display_name, body_id: $body_id, image_urls: $image_urls, kind: $kind, phone_number: $phone_number, priority: $priority, sharing_features: $sharing_features, source: $source, speakable_name: $speakable_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of locations for the user.
#
# GET /locations
# Returns: record<items: table<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, kind: string>
# operationId: mirror.locations.list
export def "mirror-locations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single location by ID.
#
# GET /locations/{id}
# Returns: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>
# operationId: mirror.locations.get
export def "mirror-locations-get" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single setting by ID.
#
# GET /settings/{id}
# Returns: record<id: string, kind: string, value: string>
# operationId: mirror.settings.get
export def "mirror-settings-get" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/settings/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of subscriptions for the authenticated user and service.
#
# GET /subscriptions
# Returns: record<items: table<callbackUrl: string, collection: string, id: string, kind: string, notification: record, operation: list, updated: string, userToken: string, verifyToken: string>, kind: string>
# operationId: mirror.subscriptions.list
export def "mirror-subscriptions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new subscription.
#
# POST /subscriptions
# Returns: record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string>
# operationId: mirror.subscriptions.insert
export def "mirror-subscriptions-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --callback-url: string # The URL where notifications should be delivered (must start with https://).
  --collection: string # The collection to subscribe to. Allowed values are: - timeline - Changes in the timeline including insertion, deletion, and updates. - locations - Location updates. - settings - Settings updates.
  --id: string # The ID of the subscription.
  --kind: string # The type of resource. This is always mirror#subscription. (default: mirror#subscription)
  --notification: record # A notification delivered by the API. — shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
  --operation: list<string> # A list of operations that should be subscribed to. An empty list indicates that all operations on the collection should be subscribed to. Allowed values are: - UPDATE - The item has been updated. - INSERT - A new item has been inserted. - DELETE - The item has been deleted. - MENU_ACTION - A custom menu item has been triggered by the user.
  --updated: string # The time at which this subscription was last modified, formatted according to RFC 3339. (format: date-time)
  --user-token: string # An opaque token sent to the subscriber in notifications so that it can determine the ID of the user.
  --verify-token: string # A secret token sent to the subscriber in notifications so that it can verify that the notification was generated by Google.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: callbackUrl, var: callback_url}, {name: collection, var: collection}, {name: id, var: id}, {name: kind, var: kind}, {name: notification, var: notification}, {name: operation, var: operation}, {name: updated, var: updated}, {name: userToken, var: user_token}, {name: verifyToken, var: verify_token}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, callback_url: $callback_url, collection: $collection, id: $id, kind: $kind, notification: $notification, operation: $operation, updated: $updated, user_token: $user_token, verify_token: $verify_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subscription.
#
# DELETE /subscriptions/{id}
# operationId: mirror.subscriptions.delete
export def "mirror-subscriptions-delete" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing subscription in place.
#
# PUT /subscriptions/{id}
# Returns: record<callbackUrl: string, collection: string, id: string, kind: string, notification: record<collection: string, itemId: string, operation: string, userActions: list<record>, userToken: string, verifyToken: string>, operation: list<string>, updated: string, userToken: string, verifyToken: string>
# operationId: mirror.subscriptions.update
export def "mirror-subscriptions-update" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --callback-url: string # The URL where notifications should be delivered (must start with https://).
  --collection: string # The collection to subscribe to. Allowed values are: - timeline - Changes in the timeline including insertion, deletion, and updates. - locations - Location updates. - settings - Settings updates.
  --body-id: string # The ID of the subscription. (spec name: id)
  --kind: string # The type of resource. This is always mirror#subscription. (default: mirror#subscription)
  --notification: record # A notification delivered by the API. — shape: {collection?: string, itemId?: string, operation?: string, userActions?: list, userToken?: string, verifyToken?: string}
  --operation: list<string> # A list of operations that should be subscribed to. An empty list indicates that all operations on the collection should be subscribed to. Allowed values are: - UPDATE - The item has been updated. - INSERT - A new item has been inserted. - DELETE - The item has been deleted. - MENU_ACTION - A custom menu item has been triggered by the user.
  --updated: string # The time at which this subscription was last modified, formatted according to RFC 3339. (format: date-time)
  --user-token: string # An opaque token sent to the subscriber in notifications so that it can determine the ID of the user.
  --verify-token: string # A secret token sent to the subscriber in notifications so that it can verify that the notification was generated by Google.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: callbackUrl, var: callback_url}, {name: collection, var: collection}, {name: id, var: body_id}, {name: kind, var: kind}, {name: notification, var: notification}, {name: operation, var: operation}, {name: updated, var: updated}, {name: userToken, var: user_token}, {name: verifyToken, var: verify_token}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, callback_url: $callback_url, collection: $collection, body_id: $body_id, kind: $kind, notification: $notification, operation: $operation, updated: $updated, user_token: $user_token, verify_token: $verify_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of timeline items for the authenticated user.
#
# GET /timeline
# Returns: record<items: table<attachments: list, bundleId: string, canonicalUrl: string, created: string, creator: record, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record, menuItems: list, notification: record, pinScore: int, recipients: list, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>, kind: string, nextPageToken: string>
# operationId: mirror.timeline.list
export def "mirror-timeline-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --bundle-id: string # If provided, only items with the given bundleId will be returned.
  --include-deleted: oneof<nothing, bool> # If true, tombstone records for deleted items will be returned.
  --max-results: int # The maximum number of items to include in the response, used for paging.
  --order-by: string@order-by-completer # Controls the order in which timeline items are returned.
  --page-token: string # Token for the page of results to return.
  --pinned-only: oneof<nothing, bool> # If true, only pinned items will be returned.
  --source-item-id: string # If provided, only items with the given sourceItemId will be returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/timeline"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: bundleId, var: bundle_id}, {name: includeDeleted, var: include_deleted}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: pinnedOnly, var: pinned_only}, {name: sourceItemId, var: source_item_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, bundle_id: $bundle_id, include_deleted: $include_deleted, max_results: $max_results, order_by: $order_by, page_token: $page_token, pinned_only: $pinned_only, source_item_id: $source_item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a new item into the timeline.
#
# POST /timeline
# Returns: record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>
# operationId: mirror.timeline.insert
export def "mirror-timeline-insert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/timeline"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "audio/1d-interleaved-parityfec", kind: opaque, accepts: scalar}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a timeline item.
#
# DELETE /timeline/{id}
# operationId: mirror.timeline.delete
export def "mirror-timeline-delete" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/timeline/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a single timeline item by ID.
#
# GET /timeline/{id}
# Returns: record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>
# operationId: mirror.timeline.get
export def "mirror-timeline-get" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/timeline/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a timeline item in place. This method supports patch semantics.
#
# PATCH /timeline/{id}
# Returns: record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>
# operationId: mirror.timeline.patch
export def "mirror-timeline-patch" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --attachments: list # A list of media attachments associated with this item. As a convenience, you can refer to attachments in your HTML payloads with the attachment or cid scheme. For example: - attachment: where attachment_index is the 0-based index of this array. - cid: where attachment_id is the ID of the attachment. — item shape: {contentType?: string, contentUrl?: string, id?: string, isProcessingContent?: bool}
  --bundle-id: string # The bundle ID for this item. Services can specify a bundleId to group many items together. They appear under a single top-level item on the device.
  --canonical-url: string # A canonical URL pointing to the canonical/high quality version of the data represented by the timeline item.
  --created: string # The time at which this item was created, formatted according to RFC 3339. (format: date-time)
  --creator: record # A person or group that can be used as a creator or a contact. — shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
  --display-time: string # The time that should be displayed when this item is viewed in the timeline, formatted according to RFC 3339. This user's timeline is sorted chronologically on display time, so this will also determine where the item is displayed in the timeline. If not set by the service, the display time defaults to the updated time. (format: date-time)
  --etag: string # ETag for this item.
  --html: string # HTML content for this item. If both text and html are provided for an item, the html will be rendered in the timeline. Allowed HTML elements - You can use these elements in your timeline cards. - Headers: h1, h2, h3, h4, h5, h6 - Images: img - Lists: li, ol, ul - HTML5 semantics: article, aside, details, figure, figcaption, footer, header, nav, section, summary, time - Structural: blockquote, br, div, hr, p, span - Style: b, big, center, em, i, u, s, small, strike, strong, style, sub, sup - Tables: table, tbody, td, tfoot, th, thead, tr Blocked HTML elements: These elements and their contents are removed from HTML payloads. - Document headers: head, title - Embeds: audio, embed, object, source, video - Frames: frame, frameset - Scripting: applet, script Other elements: Any elements that aren't listed are removed, but their contents are preserved.
  --body-id: string # The ID of the timeline item. This is unique within a user's timeline. (spec name: id)
  --in-reply-to: string # If this item was generated as a reply to another item, this field will be set to the ID of the item being replied to. This can be used to attach a reply to the appropriate conversation or post.
  --is-bundle-cover: oneof<nothing, bool> # Whether this item is a bundle cover. If an item is marked as a bundle cover, it will be the entry point to the bundle of items that have the same bundleId as that item. It will be shown only on the main timeline — not within the opened bundle. On the main timeline, items that are shown are: - Items that have isBundleCover set to true - Items that do not have a bundleId In a bundle sub-timeline, items that are shown are: - Items that have the bundleId in question AND isBundleCover set to false
  --is-deleted: oneof<nothing, bool> # When true, indicates this item is deleted, and only the ID property is set.
  --is-pinned: oneof<nothing, bool> # When true, indicates this item is pinned, which means it's grouped alongside "active" items like navigation and hangouts, on the opposite side of the home screen from historical (non-pinned) timeline items. You can allow the user to toggle the value of this property with the TOGGLE_PINNED built-in menu item.
  --kind: string # The type of resource. This is always mirror#timelineItem. (default: mirror#timelineItem)
  --location: record # A geographic location that can be associated with a timeline item. — shape: {accuracy?: float, address?: string, displayName?: string, id?: string, kind?: string, latitude?: float, longitude?: float, timestamp?: string}
  --menu-items: list # A list of menu items that will be presented to the user when this item is selected in the timeline. — item shape: {action?: string, contextual_command?: string, id?: string, payload?: string, removeWhenSelected?: bool, values?: list}
  --notification: record # Controls how notifications for a timeline item are presented to the user. — shape: {deliveryTime?: string, level?: string}
  --pin-score: int # For pinned items, this determines the order in which the item is displayed in the timeline, with a higher score appearing closer to the clock. Note: setting this field is currently not supported. (format: int32)
  --recipients: list # A list of users or groups that this item has been shared with. — item shape: {acceptCommands?: list, acceptTypes?: list<string>, displayName?: string, id?: string, imageUrls?: list<string>, kind?: string, phoneNumber?: string, priority?: int, sharingFeatures?: list<string>, source?: string, speakableName?: string, type?: string}
  --self-link: string # A URL that can be used to retrieve this item.
  --source-item-id: string # Opaque string you can use to map a timeline item to data in your own service.
  --speakable-text: string # The speakable version of the content of this item. Along with the READ_ALOUD menu item, use this field to provide text that would be clearer when read aloud, or to provide extended information to what is displayed visually on Glass. Glassware should also specify the speakableType field, which will be spoken before this text in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification.
  --speakable-type: string # A speakable description of the type of this item. This will be announced to the user prior to reading the content of the item in cases where the additional context is useful, for example when the user requests that the item be read aloud following a notification. This should be a short, simple noun phrase such as "Email", "Text message", or "Daily Planet News Update". Glassware are encouraged to populate this field for every timeline item, even if the item does not contain speakableText or text so that the user can learn the type of the item without looking at the screen.
  --text: string # Text content of this item.
  --title: string # The title of this item.
  --updated: string # The time at which this item was last modified, formatted according to RFC 3339. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/timeline/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: bundleId, var: bundle_id}, {name: canonicalUrl, var: canonical_url}, {name: created, var: created}, {name: creator, var: creator}, {name: displayTime, var: display_time}, {name: etag, var: etag}, {name: html, var: html}, {name: id, var: body_id}, {name: inReplyTo, var: in_reply_to}, {name: isBundleCover, var: is_bundle_cover}, {name: isDeleted, var: is_deleted}, {name: isPinned, var: is_pinned}, {name: kind, var: kind}, {name: location, var: location}, {name: menuItems, var: menu_items}, {name: notification, var: notification}, {name: pinScore, var: pin_score}, {name: recipients, var: recipients}, {name: selfLink, var: self_link}, {name: sourceItemId, var: source_item_id}, {name: speakableText, var: speakable_text}, {name: speakableType, var: speakable_type}, {name: text, var: text}, {name: title, var: title}, {name: updated, var: updated}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, attachments: $attachments, bundle_id: $bundle_id, canonical_url: $canonical_url, created: $created, creator: $creator, display_time: $display_time, etag: $etag, html: $html, body_id: $body_id, in_reply_to: $in_reply_to, is_bundle_cover: $is_bundle_cover, is_deleted: $is_deleted, is_pinned: $is_pinned, kind: $kind, location: $location, menu_items: $menu_items, notification: $notification, pin_score: $pin_score, recipients: $recipients, self_link: $self_link, source_item_id: $source_item_id, speakable_text: $speakable_text, speakable_type: $speakable_type, text: $text, title: $title, updated: $updated
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a timeline item in place.
#
# PUT /timeline/{id}
# Returns: record<attachments: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, bundleId: string, canonicalUrl: string, created: string, creator: record<acceptCommands: list<record>, acceptTypes: list<string>, displayName: string, id: string, imageUrls: list<string>, kind: string, phoneNumber: string, priority: int, sharingFeatures: list<string>, source: string, speakableName: string, type: string>, displayTime: string, etag: string, html: string, id: string, inReplyTo: string, isBundleCover: bool, isDeleted: bool, isPinned: bool, kind: string, location: record<accuracy: float, address: string, displayName: string, id: string, kind: string, latitude: float, longitude: float, timestamp: string>, menuItems: table<action: string, contextual_command: string, id: string, payload: string, removeWhenSelected: bool, values: list>, notification: record<deliveryTime: string, level: string>, pinScore: int, recipients: table<acceptCommands: list, acceptTypes: list, displayName: string, id: string, imageUrls: list, kind: string, phoneNumber: string, priority: int, sharingFeatures: list, source: string, speakableName: string, type: string>, selfLink: string, sourceItemId: string, speakableText: string, speakableType: string, text: string, title: string, updated: string>
# operationId: mirror.timeline.update
export def "mirror-timeline-update" [
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
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/timeline/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "audio/1d-interleaved-parityfec", kind: opaque, accepts: scalar}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of attachments for a timeline item.
#
# GET /timeline/{itemId}/attachments
# Returns: record<items: table<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>, kind: string>
# operationId: mirror.timeline.attachments.list
export def "mirror-timeline-attachments-list" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/timeline/{itemId}/attachments"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new attachment to a timeline item.
#
# POST /timeline/{itemId}/attachments
# Returns: record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>
# operationId: mirror.timeline.attachments.insert
export def "mirror-timeline-attachments-insert" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/timeline/{itemId}/attachments"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an attachment from a timeline item.
#
# DELETE /timeline/{itemId}/attachments/{attachmentId}
# operationId: mirror.timeline.attachments.delete
export def "mirror-timeline-attachments-delete" [
  item_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/timeline/{itemId}/attachments/{attachmentId}"
    path_params: [{name: itemId, var: item_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, attachment_id: $attachment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an attachment on a timeline item by item ID and attachment ID.
#
# GET /timeline/{itemId}/attachments/{attachmentId}
# Returns: record<contentType: string, contentUrl: string, id: string, isProcessingContent: bool>
# operationId: mirror.timeline.attachments.get
export def "mirror-timeline-attachments-get" [
  item_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response. (default: json)
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/timeline/{itemId}/attachments/{attachmentId}"
    path_params: [{name: itemId, var: item_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, attachment_id: $attachment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
