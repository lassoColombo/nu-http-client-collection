# Auto-generated client for redirection.io v1.1.0
# Source: https://api.apis.guru/v2/specs/redirection.io/1.1.0/swagger.json
# Auth: --token flag or $env.REDIRECTION_IO_TOKEN

const CLIENT = {
  base_url: "https://api.redirection.io"
  token_env_var: "REDIRECTION_IO_TOKEN"
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

def base-url-completer [] { ["https://api.redirection.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/ld+json" "text/csv" "text/html"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-agent-flush-aggregate-request-collection: "record<instanceName: any, instanceTime: any, logs: any>"
    post-agent-flush-requests: "record<instanceName: any, instanceTime: int, logs: list<string>>"
    post-instance-collection: "record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    put-instance-item: "record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    agent-legacy-complex-rule-collection: "table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    agent-legacy-straight-rule-collection: "table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    agent-rule-collection: "table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    get-aggregate-log-collection: "table<fixed: bool, id: any, lastOccurrenceAt: string, ruleId: string, source: any, statusCode: int, target: any, viewCount: int>"
    get-aggregate-log-item: "record<fixed: bool, id: any, lastOccurrenceAt: string, ruleId: string, source: any, statusCode: int, target: any, viewCount: int>"
    get-crawl-url-collection: "table<curlInfo: any, depth: any, description: any, error: any, id: any, redirectUrl: any, statusCode: any, title: any, url: any, urlsTo: string>"
    get-crawl-url-item: "record<curlInfo: any, depth: any, description: any, error: any, id: any, redirectUrl: any, statusCode: any, title: any, url: any, urlsTo: string>"
    get-crawl-collection: "table<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>"
    post-crawl-collection: "record<archived: bool, author: record<currentPassword: any, defaultOrganization: record<createdAt: string, id: string, name: string, projects: list, slug: string, updatedAt: string, userOrganizations: list>, email: string, id: string, name: string, newEmail: string, newEmailToken: string, newEmailTokenExpiredAt: string, password: string, plainPassword: string, plainPasswordRepeat: any, projectsFlattened: list<string>, superAdmin: bool, updatedAt: string, userOrganizations: list<record>, userProjects: list<string>>, createdAt: string, currentConcurrency: int, error: string, finishedAt: string, firstUrl: string, id: string, marking: list<string>, stats: list<string>, trigger: string, updatedAt: string>"
    get-crawl-item: "record<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>"
    cancel-crawl-item: "record<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>"
    post-explain-url-collection: "record<explain: any, id: string, project: string, url: string>"
    get-explain-url-item: "record<explain: any, id: string, project: string, url: string>"
    export-rule-collection: "table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    post-impact-rule-change-collection: "record<impact: any>"
    get-impact-rule-change-item: "record<impact: any>"
    post-impact-smart-list-collection: "record<impact: any, smartList: any>"
    get-impact-smart-list-item: "record<impact: any, smartList: any>"
    get-import-collection: "table<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>"
    post-import-collection: "record<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>"
    get-import-item: "record<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>"
    get-instance-collection: "table<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    get-instance-item: "record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    logging-instance-item: "record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    live-instance-item: "record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>"
    get-invitation-collection: "table<createdAt: string, email: string, id: string>"
    post-invitation-collection: "record<createdAt: string, email: string, id: string>"
    accept-invitation-item: "record<createdAt: string, email: string, id: string>"
    get-invitation-item: "record<createdAt: string, email: string, id: string>"
    get-log-collection: "table<createdAt: string, fixed: bool, fixedByVersions: list<string>, fromSmartList: bool, id: any, instanceName: any, method: any, notFixedByVersions: list<string>, proxy: string, referrer: any, ruleId: string, simplifiedUserAgent: any, smartList: string, source: any, statusCode: any, target: any, userAgent: any, userAgentType: any>"
    get-log-item: "record<createdAt: string, fixed: bool, fixedByVersions: list<string>, fromSmartList: bool, id: any, instanceName: any, method: any, notFixedByVersions: list<string>, proxy: string, referrer: any, ruleId: string, simplifiedUserAgent: any, smartList: string, source: any, statusCode: any, target: any, userAgent: any, userAgentType: any>"
    post-marker-collection: "record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>"
    get-marker-item: "record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>"
    put-marker-item: "record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>"
    post-matching-url-collection: "record<matching: any>"
    get-matching-url-item: "record<matching: any>"
    get-notification-collection: "table<createdAt: string, id: string, message: string, updatedAt: string>"
    get-notification-item: "record<createdAt: string, id: string, message: string, updatedAt: string>"
    post-organization-collection: "record<id: string, name: string, slug: string>"
    get-organization-item: "record<id: string, name: string, slug: string>"
    put-organization-item: "record<id: string, name: string, slug: string>"
    post-post-logs: "record<instanceName: any, instanceTime: int, logs: list<string>>"
    get-project-collection: "table<id: string, name: string, organization: record<name: string, slug: string>, slug: string, token: string>"
    post-project-collection: "record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>"
    get-project-item: "record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>"
    put-project-item: "record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>"
    get-publish-history-collection: "table<added: int, author: record<name: string>, createdAt: string, deleted: int, id: string, summary: string, type: string, updated: int, version: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>"
    get-publish-history-item: "record<added: int, author: record<name: string>, createdAt: string, deleted: int, id: string, summary: string, type: string, updated: int, version: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>"
    get-rule-change-collection: "table<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>"
    post-rule-change-collection: "record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>"
    get-rule-change-item: "record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>"
    get-rule-set-version-collection: "table<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>"
    get-rule-set-version-item: "record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>"
    clear-rule-set-version-item: "record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>"
    publish-rule-set-version-item: "record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>"
    get-rule-statistic-collection: "table<id: string, stats: string>"
    get-rule-statistic-item: "record<id: string, stats: string>"
    get-rule-collection: "table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    get-rule-item: "record<actions: list<string>, changes: table<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, currentChange: record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>"
    get-smart-list-collection: "table<defaultVersion: string, description: string, id: string, name: string, rules: string, versions: list<string>>"
    get-smart-list-item: "record<defaultVersion: string, description: string, id: string, name: string, rules: string, versions: list<string>>"
    post-user-organization-collection: "record<functionalRoles: list<string>, id: string, organization: string, user: string>"
    get-user-organization-item: "record<functionalRoles: list<string>, id: string, organization: string, user: string>"
    put-user-organization-item: "record<functionalRoles: list<string>, id: string, organization: string, user: string>"
    get-user-project-flattened-item: "record<functionalRoles: list<string>, user: string>"
    post-user-project-collection: "record<functionalRoles: list<string>, id: string, user: string>"
    get-user-project-item: "record<functionalRoles: list<string>, id: string, user: string>"
    put-user-project-item: "record<functionalRoles: list<string>, id: string, user: string>"
    get-user-collection: "table<email: string, id: string, name: string>"
    post-user-collection: "record<name: string>"
    post-forgot-password-request-collection: "record<email: string>"
    forgot-password-user-item: "record<name: string>"
    get-user-item: "record<name: string>"
    confirm-new-email-user-item: "record<name: string>"
    edit-email-user-item: "record<name: string>"
    edit-info-user-item: "record<name: string>"
    edit-password-user-item: "record<name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-agent-flush-aggregate-request-collection" "post-agent-flush-requests" "post-instance-collection" "put-instance-item" "agent-legacy-complex-rule-collection" "agent-legacy-straight-rule-collection" "agent-rule-collection" "get-aggregate-log-collection" "get-aggregate-log-item" "get-crawl-url-collection" "get-crawl-url-item" "get-crawl-collection" "post-crawl-collection" "get-crawl-item" "cancel-crawl-item" "post-explain-url-collection" "get-explain-url-item" "export-rule-collection" "post-impact-rule-change-collection" "get-impact-rule-change-item" "post-impact-smart-list-collection" "get-impact-smart-list-item" "get-import-collection" "post-import-collection" "get-import-item" "get-instance-collection" "get-instance-item" "logging-instance-item" "live-instance-item" "get-invitation-collection" "post-invitation-collection" "accept-invitation-item" "delete-invitation-item" "get-invitation-item" "get-log-collection" "get-log-item" "post-marker-collection" "delete-marker-item" "get-marker-item" "put-marker-item" "post-matching-url-collection" "get-matching-url-item" "get-notification-collection" "get-notification-item" "post-organization-collection" "delete-organization-item" "get-organization-item" "put-organization-item" "post-post-logs" "get-project-collection" "post-project-collection" "delete-project-item" "get-project-item" "put-project-item" "get-publish-history-collection" "get-publish-history-item" "get-rule-change-collection" "post-rule-change-collection" "delete-rule-change-item" "get-rule-change-item" "get-rule-set-version-collection" "get-rule-set-version-item" "clear-rule-set-version-item" "publish-rule-set-version-item" "get-rule-statistic-collection" "get-rule-statistic-item" "get-rule-collection" "get-rule-item" "get-smart-list-collection" "get-smart-list-item" "post-user-organization-collection" "delete-user-organization-item" "get-user-organization-item" "put-user-organization-item" "get-user-project-flattened-item" "post-user-project-collection" "delete-user-project-item" "get-user-project-item" "put-user-project-item" "get-user-collection" "post-user-collection" "post-forgot-password-request-collection" "forgot-password-user-item" "delete-user-item" "get-user-item" "confirm-new-email-user-item" "edit-email-user-item" "edit-info-user-item" "edit-password-user-item" "commands"] | sort) } | get name | first)
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

# Creates a AgentFlushAggregateRequest resource.
#
# POST /agent-flush-aggregate-requests
# Returns: record<instanceName: any, instanceTime: any, logs: any>
# operationId: postAgentFlushAggregateRequestCollection
export def "post-agent-flush-aggregate-request-collection" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/agent-flush-aggregate-requests"
    body: {content_type: "application/json", kind: json}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a AgentFlushRequest resource.
#
# POST /agent-flush-requests
# Returns: record<instanceName: any, instanceTime: int, logs: list<string>>
export def "post-agent-flush-requests" [
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
  instance_time: int
  logs: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/agent-flush-requests"
    body: {content_type: "application/json", kind: json, fields: [{name: instanceTime, var: instance_time}, {name: logs, var: logs}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    instance_time: $instance_time, logs: $logs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Instance resource.
#
# POST /agent-instance-updates
# Returns: record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: postInstanceCollection
export def "post-instance-collection" [
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
  --agent-duration: int
  --message: string
  --rules-count: int
  --rules-hash: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/agent-instance-updates"
    body: {content_type: "application/json", kind: json, fields: [{name: agentDuration, var: agent_duration}, {name: message, var: message}, {name: rulesCount, var: rules_count}, {name: rulesHash, var: rules_hash}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    agent_duration: $agent_duration, message: $message, rules_count: $rules_count, rules_hash: $rules_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Instance resource.
#
# PUT /agent-instance-updates/{id}
# Returns: record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: putInstanceItem
export def "put-instance-item" [
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
  --accept: string@accept-completer # Response content type
  --agent-duration: int
  --message: string
  --rules-count: int
  --rules-hash: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/agent-instance-updates/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agentDuration, var: agent_duration}, {name: message, var: message}, {name: rulesCount, var: rules_count}, {name: rulesHash, var: rules_hash}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, agent_duration: $agent_duration, message: $message, rules_count: $rules_count, rules_hash: $rules_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Rule resources.
#
# GET /agent-rule-complexes
# Returns: table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: agent-legacy-complexRuleCollection
export def "agent-legacy-complex-rule-collection" [
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
  --project-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/agent-rule-complexes"
    query: [{name: projectId, var: project_id, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Rule resources.
#
# GET /agent-rule-straights
# Returns: table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: agent-legacy-straightRuleCollection
export def "agent-legacy-straight-rule-collection" [
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
  --project-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/agent-rule-straights"
    query: [{name: projectId, var: project_id, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Rule resources.
#
# GET /agent-rules
# Returns: table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: agentRuleCollection
export def "agent-rule-collection" [
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
  --project-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/agent-rules"
    query: [{name: projectId, var: project_id, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of AggregateLog resources.
#
# GET /aggregate-logs
# Returns: table<fixed: bool, id: any, lastOccurrenceAt: string, ruleId: string, source: any, statusCode: int, target: any, viewCount: int>
# operationId: getAggregateLogCollection
export def "get-aggregate-log-collection" [
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
  --page: int # The collection page number
  --project-id: string
  --created-at: string
  --source: string
  --target: string
  --status-code: string
  --referrer: string
  --user-agent: string
  --user-agent-type: string
  --simplified-user-agent: string
  --rule-id: string
  --instance-name: string
  --exclude-urls: string
  --exclude-empty-referrer: string
  --created-at-gt: string
  --created-at-gte: string
  --created-at-lt: string
  --created-at-lte: string
  --status-code-gt: string
  --status-code-gte: string
  --status-code-lt: string
  --status-code-lte: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/aggregate-logs"
    query: [{name: page, var: page}, {name: projectId, var: project_id}, {name: createdAt, var: created_at}, {name: source, var: source}, {name: target, var: target}, {name: statusCode, var: status_code}, {name: referrer, var: referrer}, {name: userAgent, var: user_agent}, {name: userAgentType, var: user_agent_type}, {name: simplifiedUserAgent, var: simplified_user_agent}, {name: ruleId, var: rule_id}, {name: instanceName, var: instance_name}, {name: excludeUrls, var: exclude_urls}, {name: excludeEmptyReferrer, var: exclude_empty_referrer}, {name: createdAt_gt, var: created_at_gt}, {name: createdAt_gte, var: created_at_gte}, {name: createdAt_lt, var: created_at_lt}, {name: createdAt_lte, var: created_at_lte}, {name: statusCode_gt, var: status_code_gt}, {name: statusCode_gte, var: status_code_gte}, {name: statusCode_lt, var: status_code_lt}, {name: statusCode_lte, var: status_code_lte}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    page: $page, project_id: $project_id, created_at: $created_at, source: $source, target: $target, status_code: $status_code, referrer: $referrer, user_agent: $user_agent, user_agent_type: $user_agent_type, simplified_user_agent: $simplified_user_agent, rule_id: $rule_id, instance_name: $instance_name, exclude_urls: $exclude_urls, exclude_empty_referrer: $exclude_empty_referrer, created_at_gt: $created_at_gt, created_at_gte: $created_at_gte, created_at_lt: $created_at_lt, created_at_lte: $created_at_lte, status_code_gt: $status_code_gt, status_code_gte: $status_code_gte, status_code_lt: $status_code_lt, status_code_lte: $status_code_lte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a AggregateLog resource.
#
# GET /aggregate-logs/{id}
# Returns: record<fixed: bool, id: any, lastOccurrenceAt: string, ruleId: string, source: any, statusCode: int, target: any, viewCount: int>
# operationId: getAggregateLogItem
export def "get-aggregate-log-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/aggregate-logs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of CrawlUrl resources.
#
# GET /crawl-urls
# Returns: table<curlInfo: any, depth: any, description: any, error: any, id: any, redirectUrl: any, statusCode: any, title: any, url: any, urlsTo: string>
# operationId: getCrawlUrlCollection
export def "get-crawl-url-collection" [
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
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/crawl-urls"
    query: [{name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a CrawlUrl resource.
#
# GET /crawl-urls/{id}
# Returns: record<curlInfo: any, depth: any, description: any, error: any, id: any, redirectUrl: any, statusCode: any, title: any, url: any, urlsTo: string>
# operationId: getCrawlUrlItem
export def "get-crawl-url-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crawl-urls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Crawl resources.
#
# GET /crawls
# Returns: table<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>
# operationId: getCrawlCollection
export def "get-crawl-collection" [
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
  --project-id: string # required
  --first-url: string
  --sort-created-at: string
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/crawls"
    query: [{name: projectId, var: project_id, required: true}, {name: firstUrl, var: first_url}, {name: "sort[createdAt]", var: sort_created_at}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, first_url: $first_url, sort_created_at: $sort_created_at, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Crawl resource.
#
# POST /crawls
# Returns: record<archived: bool, author: record<currentPassword: any, defaultOrganization: record<createdAt: string, id: string, name: string, projects: list, slug: string, updatedAt: string, userOrganizations: list>, email: string, id: string, name: string, newEmail: string, newEmailToken: string, newEmailTokenExpiredAt: string, password: string, plainPassword: string, plainPasswordRepeat: any, projectsFlattened: list<string>, superAdmin: bool, updatedAt: string, userOrganizations: list<record>, userProjects: list<string>>, createdAt: string, currentConcurrency: int, error: string, finishedAt: string, firstUrl: string, id: string, marking: list<string>, stats: list<string>, trigger: string, updatedAt: string>
# operationId: postCrawlCollection
export def "post-crawl-collection" [
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
  concurrency: int
  --headers: list<string>
  max_depth: int
  max_duration: int
  max_urls: int
  --other-domains: list<string>
  project: string
  --ssl-checking-disabled: oneof<nothing, bool>
  --subdomain-included: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crawls"
    body: {content_type: "application/json", kind: json, fields: [{name: concurrency, var: concurrency}, {name: headers, var: headers}, {name: maxDepth, var: max_depth}, {name: maxDuration, var: max_duration}, {name: maxUrls, var: max_urls}, {name: otherDomains, var: other_domains}, {name: project, var: project}, {name: sslCheckingDisabled, var: ssl_checking_disabled, required: true}, {name: subdomainIncluded, var: subdomain_included, required: true}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    concurrency: $concurrency, headers: $headers, max_depth: $max_depth, max_duration: $max_duration, max_urls: $max_urls, other_domains: $other_domains, project: $project, ssl_checking_disabled: $ssl_checking_disabled, subdomain_included: $subdomain_included
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Crawl resource.
#
# GET /crawls/{id}
# Returns: record<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>
# operationId: getCrawlItem
export def "get-crawl-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crawls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Crawl resource.
#
# POST /crawls/{id}/cancel
# Returns: record<archived: bool, author: record<name: string>, createdAt: string, error: string, finishedAt: string, firstUrl: string, id: string, stats: list<string>, trigger: string, updatedAt: string>
# operationId: cancelCrawlItem
export def "cancel-crawl-item" [
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
  --accept: string@accept-completer # Response content type
  --author: record # shape: {defaultOrganization?: record, email: string, name: string, newEmail?: string, newEmailToken?: string, newEmailTokenExpiredAt?: string, password?: string, plainPassword?: string, projectsFlattened?: list<string>, superAdmin?: bool, updatedAt?: string, userOrganizations?: list, userProjects?: list<string>}
  --current-concurrency: int
  --marking: list<string>
  --stats: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crawls/{id}/cancel"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: currentConcurrency, var: current_concurrency}, {name: marking, var: marking}, {name: stats, var: stats}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    id: $id, author: $author, current_concurrency: $current_concurrency, marking: $marking, stats: $stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a ExplainUrl resource.
#
# POST /explain-urls
# Returns: record<explain: any, id: string, project: string, url: string>
# operationId: postExplainUrlCollection
export def "post-explain-url-collection" [
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
  project: string
  url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/explain-urls"
    body: {content_type: "application/json", kind: json, fields: [{name: project, var: project}, {name: url, var: url}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    project: $project, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a ExplainUrl resource.
#
# GET /explain-urls/{id}
# Returns: record<explain: any, id: string, project: string, url: string>
# operationId: getExplainUrlItem
export def "get-explain-url-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/explain-urls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Rule resources.
#
# GET /export-rules
# Returns: table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: exportRuleCollection
export def "export-rule-collection" [
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
  --project-id: string # required
  --sort-id: string
  --sort-view-count: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/export-rules"
    query: [{name: projectId, var: project_id, required: true}, {name: "sort[id]", var: sort_id}, {name: "sort[viewCount]", var: sort_view_count}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, sort_id: $sort_id, sort_view_count: $sort_view_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a ImpactRuleChange resource.
#
# POST /impact-rule-changes
# Returns: record<impact: any>
# operationId: postImpactRuleChangeCollection
export def "post-impact-rule-change-collection" [
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
  project: string
  rule_change: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/impact-rule-changes"
    body: {content_type: "application/json", kind: json, fields: [{name: project, var: project}, {name: ruleChange, var: rule_change}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    project: $project, rule_change: $rule_change
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a ImpactRuleChange resource.
#
# GET /impact-rule-changes/{id}
# Returns: record<impact: any>
# operationId: getImpactRuleChangeItem
export def "get-impact-rule-change-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/impact-rule-changes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a ImpactSmartList resource.
#
# POST /impact-smart-lists
# Returns: record<impact: any, smartList: any>
# operationId: postImpactSmartListCollection
export def "post-impact-smart-list-collection" [
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
  project: string
  smart_list_id: string
  --smart-list-version: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/impact-smart-lists"
    body: {content_type: "application/json", kind: json, fields: [{name: project, var: project}, {name: smartListId, var: smart_list_id}, {name: smartListVersion, var: smart_list_version}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    project: $project, smart_list_id: $smart_list_id, smart_list_version: $smart_list_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a ImpactSmartList resource.
#
# GET /impact-smart-lists/{id}
# Returns: record<impact: any, smartList: any>
# operationId: getImpactSmartListItem
export def "get-impact-smart-list-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/impact-smart-lists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Import resources.
#
# GET /imports
# Returns: table<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>
# operationId: getImportCollection
export def "get-import-collection" [
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
  --project-id: string # required
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/imports"
    query: [{name: projectId, var: project_id, required: true}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Import resource.
#
# POST /imports
# Returns: record<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>
# operationId: postImportCollection
export def "post-import-collection" [
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
  project: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/imports"
    body: {content_type: "application/json", kind: json, fields: [{name: project, var: project}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Import resource.
#
# GET /imports/{id}
# Returns: record<author: string, completedAt: string, errorCount: int, id: string, importDuration: int, message: string, project: string, startedAt: string, statusAsText: any, successCount: int, updatedAt: string>
# operationId: getImportItem
export def "get-import-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/imports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Instance resources.
#
# GET /instances
# Returns: table<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: getInstanceCollection
export def "get-instance-collection" [
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
  --project-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/instances"
    query: [{name: projectId, var: project_id, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Instance resource.
#
# GET /instances/{id}
# Returns: record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: getInstanceItem
export def "get-instance-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/instances/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Instance resource.
#
# PUT /instances/{id}
# Returns: record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: loggingInstanceItem
export def "logging-instance-item" [
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
  --accept: string@accept-completer # Response content type
  --agent-duration: int
  --message: string
  --rules-count: int
  --rules-hash: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instances/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agentDuration, var: agent_duration}, {name: message, var: message}, {name: rulesCount, var: rules_count}, {name: rulesHash, var: rules_hash}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, agent_duration: $agent_duration, message: $message, rules_count: $rules_count, rules_hash: $rules_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Instance resource.
#
# PUT /instances/{id}/live
# Returns: record<agentDuration: int, agentVersion: string, agentVersionStatus: string, config: string, createdAt: string, gone: bool, id: string, lastCompletedAt: string, lastStartedAt: string, live: bool, logging: bool, logsLastFlushedAt: string, message: string, misconfigured: bool, name: string, rulesCount: int, rulesHash: string, stale: bool, status: int, updatedAt: string>
# operationId: liveInstanceItem
export def "live-instance-item" [
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
  --accept: string@accept-completer # Response content type
  --agent-duration: int
  --message: string
  --rules-count: int
  --rules-hash: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/instances/{id}/live"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agentDuration, var: agent_duration}, {name: message, var: message}, {name: rulesCount, var: rules_count}, {name: rulesHash, var: rules_hash}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, agent_duration: $agent_duration, message: $message, rules_count: $rules_count, rules_hash: $rules_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Invitation resources.
#
# GET /invitations
# Returns: table<createdAt: string, email: string, id: string>
# operationId: getInvitationCollection
export def "get-invitation-collection" [
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
  --target-id: string # required
  --target-type: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/invitations"
    query: [{name: targetId, var: target_id, required: true}, {name: targetType, var: target_type, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    target_id: $target_id, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Invitation resource.
#
# POST /invitations
# Returns: record<createdAt: string, email: string, id: string>
# operationId: postInvitationCollection
export def "post-invitation-collection" [
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
  email: string
  target: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invitations"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: target, var: target}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    email: $email, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Invitation resource.
#
# POST /invitations/accept/{token}
# Returns: record<createdAt: string, email: string, id: string>
# operationId: acceptInvitationItem
export def "accept-invitation-item" [
  token_arg: string
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
  --email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invitations/accept/{token}"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    token_arg: $token_arg, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the Invitation resource.
#
# DELETE /invitations/{id}
# operationId: deleteInvitationItem
export def "delete-invitation-item" [
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
    path: "/invitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Invitation resource.
#
# GET /invitations/{id}
# Returns: record<createdAt: string, email: string, id: string>
# operationId: getInvitationItem
export def "get-invitation-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Log resources.
#
# GET /logs
# Returns: table<createdAt: string, fixed: bool, fixedByVersions: list<string>, fromSmartList: bool, id: any, instanceName: any, method: any, notFixedByVersions: list<string>, proxy: string, referrer: any, ruleId: string, simplifiedUserAgent: any, smartList: string, source: any, statusCode: any, target: any, userAgent: any, userAgentType: any>
# operationId: getLogCollection
export def "get-log-collection" [
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
  --page: int # The collection page number
  --project-id: string
  --created-at: string
  --source: string
  --target: string
  --status-code: string
  --referrer: string
  --user-agent: string
  --user-agent-type: string
  --simplified-user-agent: string
  --rule-id: string
  --instance-name: string
  --exclude-urls: string
  --exclude-empty-referrer: string
  --created-at-gt: string
  --created-at-gte: string
  --created-at-lt: string
  --created-at-lte: string
  --status-code-gt: string
  --status-code-gte: string
  --status-code-lt: string
  --status-code-lte: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/logs"
    query: [{name: page, var: page}, {name: projectId, var: project_id}, {name: createdAt, var: created_at}, {name: source, var: source}, {name: target, var: target}, {name: statusCode, var: status_code}, {name: referrer, var: referrer}, {name: userAgent, var: user_agent}, {name: userAgentType, var: user_agent_type}, {name: simplifiedUserAgent, var: simplified_user_agent}, {name: ruleId, var: rule_id}, {name: instanceName, var: instance_name}, {name: excludeUrls, var: exclude_urls}, {name: excludeEmptyReferrer, var: exclude_empty_referrer}, {name: createdAt_gt, var: created_at_gt}, {name: createdAt_gte, var: created_at_gte}, {name: createdAt_lt, var: created_at_lt}, {name: createdAt_lte, var: created_at_lte}, {name: statusCode_gt, var: status_code_gt}, {name: statusCode_gte, var: status_code_gte}, {name: statusCode_lt, var: status_code_lt}, {name: statusCode_lte, var: status_code_lte}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    page: $page, project_id: $project_id, created_at: $created_at, source: $source, target: $target, status_code: $status_code, referrer: $referrer, user_agent: $user_agent, user_agent_type: $user_agent_type, simplified_user_agent: $simplified_user_agent, rule_id: $rule_id, instance_name: $instance_name, exclude_urls: $exclude_urls, exclude_empty_referrer: $exclude_empty_referrer, created_at_gt: $created_at_gt, created_at_gte: $created_at_gte, created_at_lt: $created_at_lt, created_at_lte: $created_at_lte, status_code_gt: $status_code_gt, status_code_gte: $status_code_gte, status_code_lt: $status_code_lt, status_code_lte: $status_code_lte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Log resource.
#
# GET /logs/{id}
# Returns: record<createdAt: string, fixed: bool, fixedByVersions: list<string>, fromSmartList: bool, id: any, instanceName: any, method: any, notFixedByVersions: list<string>, proxy: string, referrer: any, ruleId: string, simplifiedUserAgent: any, smartList: string, source: any, statusCode: any, target: any, userAgent: any, userAgentType: any>
# operationId: getLogItem
export def "get-log-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/logs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Marker resource.
#
# POST /markers
# Returns: record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>
# operationId: postMarkerCollection
export def "post-marker-collection" [
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
  --maximum-occurrence: int
  --minimum-occurrence: int
  name: string
  --options: list<string>
  --transformers: list<string>
  type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/markers"
    body: {content_type: "application/json", kind: json, fields: [{name: maximumOccurrence, var: maximum_occurrence}, {name: minimumOccurrence, var: minimum_occurrence}, {name: name, var: name}, {name: options, var: options}, {name: transformers, var: transformers}, {name: type, var: type}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    maximum_occurrence: $maximum_occurrence, minimum_occurrence: $minimum_occurrence, name: $name, options: $options, transformers: $transformers, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the Marker resource.
#
# DELETE /markers/{id}
# operationId: deleteMarkerItem
export def "delete-marker-item" [
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
    path: "/markers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Marker resource.
#
# GET /markers/{id}
# Returns: record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>
# operationId: getMarkerItem
export def "get-marker-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/markers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Marker resource.
#
# PUT /markers/{id}
# Returns: record<id: string, maximumOccurrence: int, minimumOccurrence: int, name: string, options: list<string>, regex: string, transformers: list<string>, type: string>
# operationId: putMarkerItem
export def "put-marker-item" [
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
  --accept: string@accept-completer # Response content type
  --body-id: string # (spec name: id)
  --maximum-occurrence: int
  --minimum-occurrence: int
  name: string
  --options: list<string>
  --regex: string
  --transformers: list<string>
  type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/markers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: body_id}, {name: maximumOccurrence, var: maximum_occurrence}, {name: minimumOccurrence, var: minimum_occurrence}, {name: name, var: name}, {name: options, var: options}, {name: regex, var: regex}, {name: transformers, var: transformers}, {name: type, var: type}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_id: $body_id, maximum_occurrence: $maximum_occurrence, minimum_occurrence: $minimum_occurrence, name: $name, options: $options, regex: $regex, transformers: $transformers, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a MatchingUrl resource.
#
# POST /matching-urls
# Returns: record<matching: any>
# operationId: postMatchingUrlCollection
export def "post-matching-url-collection" [
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
  --project: string
  --rule-change: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/matching-urls"
    body: {content_type: "application/json", kind: json, fields: [{name: project, var: project}, {name: ruleChange, var: rule_change}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    project: $project, rule_change: $rule_change
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a MatchingUrl resource.
#
# GET /matching-urls/{id}
# Returns: record<matching: any>
# operationId: getMatchingUrlItem
export def "get-matching-url-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/matching-urls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Notification resources.
#
# GET /notifications
# Returns: table<createdAt: string, id: string, message: string, updatedAt: string>
# operationId: getNotificationCollection
export def "get-notification-collection" [
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
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/notifications"
    query: [{name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Notification resource.
#
# GET /notifications/{id}
# Returns: record<createdAt: string, id: string, message: string, updatedAt: string>
# operationId: getNotificationItem
export def "get-notification-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/notifications/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Organization resource.
#
# POST /organizations
# Returns: record<id: string, name: string, slug: string>
# operationId: postOrganizationCollection
export def "post-organization-collection" [
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
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the Organization resource.
#
# DELETE /organizations/{id}
# operationId: deleteOrganizationItem
export def "delete-organization-item" [
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
    path: "/organizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Organization resource.
#
# GET /organizations/{id}
# Returns: record<id: string, name: string, slug: string>
# operationId: getOrganizationItem
export def "get-organization-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Organization resource.
#
# PUT /organizations/{id}
# Returns: record<id: string, name: string, slug: string>
# operationId: putOrganizationItem
export def "put-organization-item" [
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
  --accept: string@accept-completer # Response content type
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a AgentFlushRequest resource.
#
# POST /post-logs
# Returns: record<instanceName: any, instanceTime: int, logs: list<string>>
export def "post-post-logs" [
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
  instance_time: int
  logs: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/post-logs"
    body: {content_type: "application/json", kind: json, fields: [{name: instanceTime, var: instance_time}, {name: logs, var: logs}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    instance_time: $instance_time, logs: $logs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Project resources.
#
# GET /projects
# Returns: table<id: string, name: string, organization: record<name: string, slug: string>, slug: string, token: string>
# operationId: getProjectCollection
export def "get-project-collection" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a Project resource.
#
# POST /projects
# Returns: record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>
# operationId: postProjectCollection
export def "post-project-collection" [
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
  --ignore-project-types: list<string>
  name: string
  --onboarding-completed-demos: list<string>
  --organization: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreProjectTypes, var: ignore_project_types}, {name: name, var: name}, {name: onboardingCompletedDemos, var: onboarding_completed_demos}, {name: organization, var: organization}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    ignore_project_types: $ignore_project_types, name: $name, onboarding_completed_demos: $onboarding_completed_demos, organization: $organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the Project resource.
#
# DELETE /projects/{id}
# operationId: deleteProjectItem
export def "delete-project-item" [
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
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Project resource.
#
# GET /projects/{id}
# Returns: record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>
# operationId: getProjectItem
export def "get-project-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the Project resource.
#
# PUT /projects/{id}
# Returns: record<complexRulesCount: int, complexRulesUpdatedAt: string, configuration: list<string>, createdAt: string, currentVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>, id: string, ignoreProjectTypes: list<string>, isPublishing: bool, name: string, onboardingCompletedDemos: list<string>, organization: record<id: string, name: string, slug: string>, plan: int, rulesHash: string, slug: string, straightRulesCount: int, straightRulesUpdatedAt: string, token: string, updatedAt: string, userProjects: table<functionalRoles: list, id: string, user: string>, usersFlattened: table<functionalRoles: list, user: string>, workingVersion: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>
# operationId: putProjectItem
export def "put-project-item" [
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
  --accept: string@accept-completer # Response content type
  --ignore-project-types: list<string>
  name: string
  --onboarding-completed-demos: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreProjectTypes, var: ignore_project_types}, {name: name, var: name}, {name: onboardingCompletedDemos, var: onboarding_completed_demos}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ignore_project_types: $ignore_project_types, name: $name, onboarding_completed_demos: $onboarding_completed_demos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of PublishHistory resources.
#
# GET /publish-histories
# Returns: table<added: int, author: record<name: string>, createdAt: string, deleted: int, id: string, summary: string, type: string, updated: int, version: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>
# operationId: getPublishHistoryCollection
export def "get-publish-history-collection" [
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
  --project-id: string # required
  --created-at-before: string
  --created-at-strictly-before: string
  --created-at-after: string
  --created-at-strictly-after: string
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/publish-histories"
    query: [{name: projectId, var: project_id, required: true}, {name: "createdAt[before]", var: created_at_before}, {name: "createdAt[strictly_before]", var: created_at_strictly_before}, {name: "createdAt[after]", var: created_at_after}, {name: "createdAt[strictly_after]", var: created_at_strictly_after}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, created_at_before: $created_at_before, created_at_strictly_before: $created_at_strictly_before, created_at_after: $created_at_after, created_at_strictly_after: $created_at_strictly_after, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a PublishHistory resource.
#
# GET /publish-histories/{id}
# Returns: record<added: int, author: record<name: string>, createdAt: string, deleted: int, id: string, summary: string, type: string, updated: int, version: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>>
# operationId: getPublishHistoryItem
export def "get-publish-history-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/publish-histories/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of RuleChange resources.
#
# GET /rule-changes
# Returns: table<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>
# operationId: getRuleChangeCollection
export def "get-rule-change-collection" [
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
  --version-id: string # required
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rule-changes"
    query: [{name: versionId, var: version_id, required: true}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    version_id: $version_id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a RuleChange resource.
#
# POST /rule-changes
# Returns: record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>
# operationId: postRuleChangeCollection
export def "post-rule-change-collection" [
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
  action: string
  --actions: list<string>
  --examples: list<string>
  --formatted-source: string
  --markers: list # item shape: {maximumOccurrence?: int, minimumOccurrence?: int, name: string, options?: list<string>, transformers?: list<string>, type: string}
  --match-on-response-status: int
  rank: int
  --rule-id: string
  source: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rule-changes"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: actions, var: actions}, {name: examples, var: examples}, {name: formattedSource, var: formatted_source}, {name: markers, var: markers}, {name: matchOnResponseStatus, var: match_on_response_status}, {name: rank, var: rank}, {name: ruleId, var: rule_id}, {name: source, var: source}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    action: $action, actions: $actions, examples: $examples, formatted_source: $formatted_source, markers: $markers, match_on_response_status: $match_on_response_status, rank: $rank, rule_id: $rule_id, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the RuleChange resource.
#
# DELETE /rule-changes/{id}
# operationId: deleteRuleChangeItem
export def "delete-rule-change-item" [
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
    path: "/rule-changes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a RuleChange resource.
#
# GET /rule-changes/{id}
# Returns: record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>
# operationId: getRuleChangeItem
export def "get-rule-change-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rule-changes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of RuleSetVersion resources.
#
# GET /rule-set-versions
# Returns: table<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>
# operationId: getRuleSetVersionCollection
export def "get-rule-set-version-collection" [
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
  --project-id: string # required
  --sort-created-at: string
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rule-set-versions"
    query: [{name: projectId, var: project_id, required: true}, {name: "sort[createdAt]", var: sort_created_at}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, sort_created_at: $sort_created_at, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a RuleSetVersion resource.
#
# GET /rule-set-versions/{id}
# Returns: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>
# operationId: getRuleSetVersionItem
export def "get-rule-set-version-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rule-set-versions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clear a version
#
# POST /rule-set-versions/{id}/clear
# Returns: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>
# operationId: clearRuleSetVersionItem
export def "clear-rule-set-version-item" [
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
  --accept: string@accept-completer # Response content type
  --is-snapshot: oneof<nothing, bool>
  --merged-rules-count: int
  --name: string
  --published-at: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rule-set-versions/{id}/clear"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSnapshot, var: is_snapshot}, {name: mergedRulesCount, var: merged_rules_count}, {name: name, var: name}, {name: publishedAt, var: published_at}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    id: $id, is_snapshot: $is_snapshot, merged_rules_count: $merged_rules_count, name: $name, published_at: $published_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Publish a version
#
# POST /rule-set-versions/{id}/publish
# Returns: record<createdAt: string, current: bool, id: string, isSnapshot: bool, mergedRulesCount: int, name: string, publishedAt: string, working: bool>
# operationId: publishRuleSetVersionItem
export def "publish-rule-set-version-item" [
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
  --accept: string@accept-completer # Response content type
  --is-snapshot: oneof<nothing, bool>
  --merged-rules-count: int
  --name: string
  --published-at: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rule-set-versions/{id}/publish"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSnapshot, var: is_snapshot}, {name: mergedRulesCount, var: merged_rules_count}, {name: name, var: name}, {name: publishedAt, var: published_at}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    id: $id, is_snapshot: $is_snapshot, merged_rules_count: $merged_rules_count, name: $name, published_at: $published_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of RuleStatistic resources.
#
# GET /rule-statistics
# Returns: table<id: string, stats: string>
# operationId: getRuleStatisticCollection
export def "get-rule-statistic-collection" [
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
  --project-id: string # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rule-statistics"
    query: [{name: projectId, var: project_id, required: true}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a RuleStatistic resource.
#
# GET /rule-statistics/{id}
# Returns: record<id: string, stats: string>
# operationId: getRuleStatisticItem
export def "get-rule-statistic-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rule-statistics/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of Rule resources.
#
# GET /rules
# Returns: table<actions: list<string>, changes: list<record>, currentChange: record<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: getRuleCollection
export def "get-rule-collection" [
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
  --project-id: string # required
  --sort-id: string
  --sort-view-count: string
  --page: int # The collection page number
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rules"
    query: [{name: projectId, var: project_id, required: true}, {name: "sort[id]", var: sort_id}, {name: "sort[viewCount]", var: sort_view_count}, {name: page, var: page}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, sort_id: $sort_id, sort_view_count: $sort_view_count, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Rule resource.
#
# GET /rules/{id}
# Returns: record<actions: list<string>, changes: table<action: string, actions: list, author: record, createdAt: string, examples: list, formattedSource: string, id: string, markers: list, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, currentChange: record<action: string, actions: list<string>, author: record<name: string>, createdAt: string, examples: list<string>, formattedSource: string, id: string, markers: list<record>, matchOnResponseStatus: int, rank: int, ruleId: string, source: string>, examples: list<string>, formattedSource: string, id: string, markers: table<maximumOccurrence: int, minimumOccurrence: int, name: string, options: list, transformers: list, type: string>, matchOnResponseStatus: int, rank: int, source: string, updatedAt: string, viewCount: int>
# operationId: getRuleItem
export def "get-rule-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of SmartList resources.
#
# GET /smart-lists
# Returns: table<defaultVersion: string, description: string, id: string, name: string, rules: string, versions: list<string>>
# operationId: getSmartListCollection
export def "get-smart-list-collection" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/smart-lists"
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a SmartList resource.
#
# GET /smart-lists/{id}
# Returns: record<defaultVersion: string, description: string, id: string, name: string, rules: string, versions: list<string>>
# operationId: getSmartListItem
export def "get-smart-list-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/smart-lists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a UserOrganization resource.
#
# POST /user-organizations
# Returns: record<functionalRoles: list<string>, id: string, organization: string, user: string>
# operationId: postUserOrganizationCollection
export def "post-user-organization-collection" [
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
  functional_roles: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user-organizations"
    body: {content_type: "application/json", kind: json, fields: [{name: functionalRoles, var: functional_roles}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    functional_roles: $functional_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the UserOrganization resource.
#
# DELETE /user-organizations/{id}
# operationId: deleteUserOrganizationItem
export def "delete-user-organization-item" [
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
    path: "/user-organizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a UserOrganization resource.
#
# GET /user-organizations/{id}
# Returns: record<functionalRoles: list<string>, id: string, organization: string, user: string>
# operationId: getUserOrganizationItem
export def "get-user-organization-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user-organizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the UserOrganization resource.
#
# PUT /user-organizations/{id}
# Returns: record<functionalRoles: list<string>, id: string, organization: string, user: string>
# operationId: putUserOrganizationItem
export def "put-user-organization-item" [
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
  --accept: string@accept-completer # Response content type
  functional_roles: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user-organizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: functionalRoles, var: functional_roles}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, functional_roles: $functional_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a UserProjectFlattened resource.
#
# GET /user-project-flatteneds/{id}
# Returns: record<functionalRoles: list<string>, user: string>
# operationId: getUserProjectFlattenedItem
export def "get-user-project-flattened-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user-project-flatteneds/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a UserProject resource.
#
# POST /user-projects
# Returns: record<functionalRoles: list<string>, id: string, user: string>
# operationId: postUserProjectCollection
export def "post-user-project-collection" [
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
  functional_roles: list<string>
  project: string
  user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user-projects"
    body: {content_type: "application/json", kind: json, fields: [{name: functionalRoles, var: functional_roles}, {name: project, var: project}, {name: user, var: user}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    functional_roles: $functional_roles, project: $project, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the UserProject resource.
#
# DELETE /user-projects/{id}
# operationId: deleteUserProjectItem
export def "delete-user-project-item" [
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
    path: "/user-projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a UserProject resource.
#
# GET /user-projects/{id}
# Returns: record<functionalRoles: list<string>, id: string, user: string>
# operationId: getUserProjectItem
export def "get-user-project-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user-projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the UserProject resource.
#
# PUT /user-projects/{id}
# Returns: record<functionalRoles: list<string>, id: string, user: string>
# operationId: putUserProjectItem
export def "put-user-project-item" [
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
  --accept: string@accept-completer # Response content type
  functional_roles: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user-projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: functionalRoles, var: functional_roles}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, functional_roles: $functional_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the collection of User resources.
#
# GET /users
# Returns: table<email: string, id: string, name: string>
# operationId: getUserCollection
export def "get-user-collection" [
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
  --organization-id: string # required
  --search: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: organizationId, var: organization_id, required: true}, {name: search, var: search}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a User resource.
#
# POST /users
# Returns: record<name: string>
# operationId: postUserCollection
export def "post-user-collection" [
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
  email: string
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a ForgotPasswordRequest resource.
#
# POST /users/forgot-password-request
# Returns: record<email: string>
# operationId: postForgotPasswordRequestCollection
export def "post-forgot-password-request-collection" [
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
  email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/forgot-password-request"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [201]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the User resource.
#
# PUT /users/forgot-password/{resetToken}
# Returns: record<name: string>
# operationId: forgot_passwordUserItem
export def "forgot-password-user-item" [
  reset_token: string
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
  --plain-password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/forgot-password/{resetToken}"
    path_params: [{name: resetToken, var: reset_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: plainPassword, var: plain_password}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    reset_token: $reset_token, plain_password: $plain_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the User resource.
#
# DELETE /users/{id}
# operationId: deleteUserItem
export def "delete-user-item" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a User resource.
#
# GET /users/{id}
# Returns: record<name: string>
# operationId: getUserItem
export def "get-user-item" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a User resource.
#
# GET /users/{id}/confirm-new-email/{newEmailToken}
# Returns: record<name: string>
# operationId: confirm_new_emailUserItem
export def "confirm-new-email-user-item" [
  id: string
  new_email_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/confirm-new-email/{newEmailToken}"
    path_params: [{name: id, var: id}, {name: newEmailToken, var: new_email_token}]
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, new_email_token: $new_email_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the User resource.
#
# PUT /users/{id}/edit-email
# Returns: record<name: string>
# operationId: edit_emailUserItem
export def "edit-email-user-item" [
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
  --accept: string@accept-completer # Response content type
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}/edit-email"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the User resource.
#
# PUT /users/{id}/edit-info
# Returns: record<name: string>
# operationId: edit_infoUserItem
export def "edit-info-user-item" [
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
  --accept: string@accept-completer # Response content type
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}/edit-info"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replaces the User resource.
#
# PUT /users/{id}/edit-password
# Returns: record<name: string>
# operationId: edit_passwordUserItem
export def "edit-password-user-item" [
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
  --accept: string@accept-completer # Response content type
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id}/edit-password"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/ld+json", "application/json", "text/html", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
