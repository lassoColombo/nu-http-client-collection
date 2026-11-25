# Auto-generated client for CodeArtifact v2018-09-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codeartifact/2018-09-22/openapi.json
# Auth: --token flag or $env.CODEARTIFACT_TOKEN

const CLIENT = {
  base_url: "http://codeartifact.us-east-1.amazonaws.com"
  token_env_var: "CODEARTIFACT_TOKEN"
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

def base-url-completer [] { ["http://codeartifact.us-east-1.amazonaws.com" "http://codeartifact.us-east-2.amazonaws.com" "http://codeartifact.us-west-1.amazonaws.com" "http://codeartifact.us-west-2.amazonaws.com" "http://codeartifact.us-gov-west-1.amazonaws.com" "http://codeartifact.us-gov-east-1.amazonaws.com" "http://codeartifact.ca-central-1.amazonaws.com" "http://codeartifact.eu-north-1.amazonaws.com" "http://codeartifact.eu-west-1.amazonaws.com" "http://codeartifact.eu-west-2.amazonaws.com" "http://codeartifact.eu-west-3.amazonaws.com" "http://codeartifact.eu-central-1.amazonaws.com" "http://codeartifact.eu-south-1.amazonaws.com" "http://codeartifact.af-south-1.amazonaws.com" "http://codeartifact.ap-northeast-1.amazonaws.com" "http://codeartifact.ap-northeast-2.amazonaws.com" "http://codeartifact.ap-northeast-3.amazonaws.com" "http://codeartifact.ap-southeast-1.amazonaws.com" "http://codeartifact.ap-southeast-2.amazonaws.com" "http://codeartifact.ap-east-1.amazonaws.com" "http://codeartifact.ap-south-1.amazonaws.com" "http://codeartifact.sa-east-1.amazonaws.com" "http://codeartifact.me-south-1.amazonaws.com" "https://codeartifact.us-east-1.amazonaws.com" "https://codeartifact.us-east-2.amazonaws.com" "https://codeartifact.us-west-1.amazonaws.com" "https://codeartifact.us-west-2.amazonaws.com" "https://codeartifact.us-gov-west-1.amazonaws.com" "https://codeartifact.us-gov-east-1.amazonaws.com" "https://codeartifact.ca-central-1.amazonaws.com" "https://codeartifact.eu-north-1.amazonaws.com" "https://codeartifact.eu-west-1.amazonaws.com" "https://codeartifact.eu-west-2.amazonaws.com" "https://codeartifact.eu-west-3.amazonaws.com" "https://codeartifact.eu-central-1.amazonaws.com" "https://codeartifact.eu-south-1.amazonaws.com" "https://codeartifact.af-south-1.amazonaws.com" "https://codeartifact.ap-northeast-1.amazonaws.com" "https://codeartifact.ap-northeast-2.amazonaws.com" "https://codeartifact.ap-northeast-3.amazonaws.com" "https://codeartifact.ap-southeast-1.amazonaws.com" "https://codeartifact.ap-southeast-2.amazonaws.com" "https://codeartifact.ap-east-1.amazonaws.com" "https://codeartifact.ap-south-1.amazonaws.com" "https://codeartifact.sa-east-1.amazonaws.com" "https://codeartifact.me-south-1.amazonaws.com" "http://codeartifact.cn-north-1.amazonaws.com.cn" "http://codeartifact.cn-northwest-1.amazonaws.com.cn" "https://codeartifact.cn-north-1.amazonaws.com.cn" "https://codeartifact.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["generic" "maven" "npm" "nuget" "pypi"] }
def expected-status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }
def status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }
def sort-by-completer [] { ["PUBLISHED_TIME"] }
def origin-type-completer [] { ["EXTERNAL" "INTERNAL" "UNKNOWN"] }
def publish-completer [] { ["ALLOW" "BLOCK"] }
def upstream-completer [] { ["ALLOW" "BLOCK"] }
def target-status-completer [] { ["Archived" "Deleted" "Disposed" "Published" "Unfinished" "Unlisted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-external-connection: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    disassociate-external-connection: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    copy-package-versions: "record<successfulVersions: record, failedVersions: record>"
    create-domain: "record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>"
    delete-domain: "record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>"
    describe-domain: "record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>"
    create-repository: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    delete-repository: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    describe-repository: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    update-repository: "record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>"
    delete-domain-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    get-domain-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    delete-package: "record<deletedPackage: record<format: string, namespace: string, package: string, originConfiguration: record<restrictions: record>>>"
    describe-package: "record<package: record<format: string, namespace: string, name: string, originConfiguration: record<restrictions: record>>>"
    put-package-origin-configuration: "record<originConfiguration: record<restrictions: record<publish: string, upstream: string>>>"
    delete-package-versions: "record<successfulVersions: record, failedVersions: record>"
    delete-repository-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    describe-package-version: "record<packageVersion: record<format: string, namespace: string, packageName: string, displayName: string, version: string, summary: string, homePage: string, sourceCodeRepository: string, publishedTime: string, licenses: list<record>, revision: string, status: string, origin: record<domainEntryPoint: record, originType: string>>>"
    dispose-package-versions: "record<successfulVersions: record, failedVersions: record>"
    get-authorization-token: "record<authorizationToken: string, expiration: string>"
    get-package-version-asset: "record<asset: string>"
    get-package-version-readme: "record<format: string, namespace: string, package: string, version: string, versionRevision: string, readme: string>"
    get-repository-endpoint: "record<repositoryEndpoint: string>"
    get-repository-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    put-repository-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    list-domains: "record<domains: table<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string>, nextToken: string>"
    list-package-version-assets: "record<format: string, namespace: string, package: string, version: string, versionRevision: string, nextToken: string, assets: table<name: string, size: int, hashes: record>>"
    list-package-version-dependencies: "record<format: string, namespace: string, package: string, version: string, versionRevision: string, nextToken: string, dependencies: table<namespace: string, package: string, dependencyType: string, versionRequirement: string>>"
    list-package-versions: "record<defaultDisplayVersion: string, format: string, namespace: string, package: string, versions: table<version: string, revision: string, status: string, origin: record>, nextToken: string>"
    list-packages: "record<packages: table<format: string, namespace: string, package: string, originConfiguration: record>, nextToken: string>"
    list-repositories: "record<repositories: table<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, createdTime: string>, nextToken: string>"
    list-repositories-in-domain: "record<repositories: table<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, createdTime: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: table<key: string, value: string>>"
    publish-package-version: "record<format: string, namespace: string, package: string, version: string, versionRevision: string, status: string, asset: record<name: string, size: int, hashes: record>>"
    put-domain-permissions-policy: "record<policy: record<resourceArn: string, revision: string, document: string>>"
    tag-resource: "record"
    untag-resource: "record"
    update-package-versions-status: "record<successfulVersions: record, failedVersions: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-external-connection" "disassociate-external-connection" "copy-package-versions" "create-domain" "delete-domain" "describe-domain" "create-repository" "delete-repository" "describe-repository" "update-repository" "delete-domain-permissions-policy" "get-domain-permissions-policy" "delete-package" "describe-package" "put-package-origin-configuration" "delete-package-versions" "delete-repository-permissions-policy" "describe-package-version" "dispose-package-versions" "get-authorization-token" "get-package-version-asset" "get-package-version-readme" "get-repository-endpoint" "get-repository-permissions-policy" "put-repository-permissions-policy" "list-domains" "list-package-version-assets" "list-package-version-dependencies" "list-package-versions" "list-packages" "list-repositories" "list-repositories-in-domain" "list-tags-for-resource" "publish-package-version" "put-domain-permissions-policy" "tag-resource" "untag-resource" "update-package-versions-status" "commands"] | sort) } | get name | first)
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

# Adds an existing external connection to a repository. One external connection is allowed per repository. A repository can have one or more upstream repositories, or an external connection.
#
# POST /v1/repository/external-connection
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: AssociateExternalConnection
export def "associate-external-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to which the external connection is added. (required)
  --external-connection: string # The name of the external connection to add to the repository. The following values are supported: public:npmjs - for the npm public repository. public:nuget-org - for the NuGet Gallery. public:pypi - for the Python Package Index. public:maven-central - for Maven Central. public:maven-googleandroid - for the Google Android repository. public:maven-gradleplugins - for the Gradle plugins repository. public:maven-commonsware - for the CommonsWare Android repository. public:maven-clojars - for the Clojars repository. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/repository/external-connection"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: external-connection, var: external_connection, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, external_connection: $external_connection, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing external connection from a repository.
#
# DELETE /v1/repository/external-connection
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: DisassociateExternalConnection
export def "disassociate-external-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository from which to remove the external repository. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository from which the external connection will be removed. (required)
  --external-connection: string # The name of the external connection to be removed from the repository. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/repository/external-connection"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: external-connection, var: external_connection, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, external_connection: $external_connection, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies package versions from one repository to another repository in the same domain. You must specify versions or versionRevisions. You cannot specify both.
#
# POST /v1/package/versions/copy
# Returns: record<successfulVersions: record, failedVersions: record>
# operationId: CopyPackageVersions
export def "copy-package-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the source and destination repositories. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --source-repository: string # The name of the repository that contains the package versions to be copied. (required)
  --destination-repository: string # The name of the repository into which package versions are copied. (required)
  --format: string@format-completer # The format of the package versions to be copied. (required)
  --namespace: string # The namespace of the package versions to be copied. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace is required when copying Maven package versions. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the versions to be copied. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --versions: list<string> # The versions of the package to be copied. You must specify versions or versionRevisions. You cannot specify both.
  --version-revisions: record # A list of key-value pairs. The keys are package versions and the values are package version revisions. A CopyPackageVersion operation succeeds if the specified versions in the source repository match the specified package version revision. You must specify versions or versionRevisions. You cannot specify both.
  --allow-overwrite: oneof<nothing, bool> # Set to true to overwrite a package version that already exists in the destination repository. If set to false and the package version already exists in the destination repository, the package version is returned in the failedVersions field of the response with an ALREADY_EXISTS error code.
  --include-from-upstream: oneof<nothing, bool> # Set to true to copy packages from repositories that are upstream from the source repository to the destination repository. The default setting is false. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package/versions/copy"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: source-repository, var: source_repository, required: true}, {name: destination-repository, var: destination_repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: versions, var: versions}, {name: versionRevisions, var: version_revisions}, {name: allowOverwrite, var: allow_overwrite}, {name: includeFromUpstream, var: include_from_upstream}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, source_repository: $source_repository, destination_repository: $destination_repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, versions: $versions, version_revisions: $version_revisions, allow_overwrite: $allow_overwrite, include_from_upstream: $include_from_upstream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a domain. CodeArtifact domains make it easier to manage multiple repositories across an organization. You can use a domain to apply permissions across many repositories owned by different Amazon Web Services accounts. An asset is stored only once in a domain, even if it's in multiple repositories. Although you can have multiple domains, we recommend a single production domain that contains all published artifacts so that your development teams can find and share packages. You can use a second pre-production domain to test changes to the production domain configuration.
#
# POST /v1/domain
# Returns: record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>
# operationId: CreateDomain
export def "create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to create. All domain names in an Amazon Web Services Region that are in the same Amazon Web Services account must be unique. The domain name is used as the prefix in DNS hostnames. Do not use sensitive information in a domain name because it is publicly discoverable. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --encryption-key: string # The encryption key for the domain. This is used to encrypt content stored in a domain. An encryption key can be a key ID, a key Amazon Resource Name (ARN), a key alias, or a key alias ARN. To specify an encryptionKey, your IAM role must have kms:DescribeKey and kms:CreateGrant permissions on the encryption key that is used. For more information, see DescribeKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestSyntax) in the Key Management Service API Reference and Key Management Service API Permissions Reference (https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html) in the Key Management Service Developer Guide. CodeArtifact supports only symmetric CMKs. Do not associate an asymmetric CMK with your domain. For more information, see Using symmetric and asymmetric keys (https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html) in the Key Management Service Developer Guide.
  --tags: list # One or more tag key-value pairs for the domain. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domain"
    query: [{name: domain, var: domain, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptionKey, var: encryption_key}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, encryption_key: $encryption_key, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a domain. You cannot delete a domain that contains repositories. If you want to delete a domain with repositories, first delete its repositories.
#
# DELETE /v1/domain
# Returns: record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>
# operationId: DeleteDomain
export def "delete-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to delete. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/domain"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a DomainDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DomainDescription.html) object that contains information about the requested domain.
#
# GET /v1/domain
# Returns: record<domain: record<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string, repositoryCount: int, assetSizeBytes: int, s3BucketArn: string>>
# operationId: DescribeDomain
export def "describe-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # A string that specifies the name of the requested domain. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domain"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a repository.
#
# POST /v1/repository
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: CreateRepository
export def "create-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the created repository. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to create. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the created repository.
  --upstreams: list # A list of upstream repositories to associate with the repository. The order of the upstream repositories in the list determines their priority order when CodeArtifact looks for a requested package version. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html). — item shape: {repositoryName: string}
  --tags: list # One or more tag key-value pairs for the repository. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/repository"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: upstreams, var: upstreams}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, upstreams: $upstreams, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a repository.
#
# DELETE /v1/repository
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: DeleteRepository
export def "delete-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository to delete. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to delete. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/repository"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a RepositoryDescription object that contains detailed information about the requested repository.
#
# GET /v1/repository
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: DescribeRepository
export def "describe-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository to describe. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # A string that specifies the name of the requested repository. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/repository"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the properties of a repository.
#
# PUT /v1/repository
# Returns: record<repository: record<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, upstreams: list<record>, externalConnections: list<record>, createdTime: string>>
# operationId: UpdateRepository
export def "update-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain associated with the repository to update. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to update. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An updated repository description.
  --upstreams: list # A list of upstream repositories to associate with the repository. The order of the upstream repositories in the list determines their priority order when CodeArtifact looks for a requested package version. For more information, see Working with upstream repositories (https://docs.aws.amazon.com/codeartifact/latest/ug/repos-upstream.html). — item shape: {repositoryName: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/repository"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: upstreams, var: upstreams}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, upstreams: $upstreams
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the resource policy set on a domain.
#
# DELETE /v1/domain/permissions/policy
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: DeleteDomainPermissionsPolicy
export def "delete-domain-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain associated with the resource policy to be deleted. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --policy-revision: string # The current revision of the resource policy to be deleted. This revision is used for optimistic locking, which prevents others from overwriting your changes to the domain's resource policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/domain/permissions/policy"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: policy-revision, var: policy_revision}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, policy_revision: $policy_revision, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the resource policy attached to the specified domain. The policy is a resource-based policy, not an identity-based policy. For more information, see Identity-based policies and resource-based policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html) in the IAM User Guide.
#
# GET /v1/domain/permissions/policy
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: GetDomainPermissionsPolicy
export def "get-domain-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain to which the resource policy is attached. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domain/permissions/policy"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a package and all associated package versions. A deleted package cannot be restored. To delete one or more package versions, use the DeletePackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DeletePackageVersions.html) API.
#
# DELETE /v1/package
# Returns: record<deletedPackage: record<format: string, namespace: string, package: string, originConfiguration: record<restrictions: record>>>
# operationId: DeletePackage
export def "delete-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the package to delete. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package to delete. (required)
  --format: string@format-completer # The format of the requested package to delete. (required)
  --namespace: string # The namespace of the package to delete. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace is required when deleting Maven package versions. The namespace of an npm package is its scope. Python and NuGet packages do not contain corresponding components, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package to delete. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/package"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a PackageDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageDescription.html) object that contains information about the requested package.
#
# GET /v1/package
# Returns: record<package: record<format: string, namespace: string, name: string, originConfiguration: record<restrictions: record>>>
# operationId: DescribePackage
export def "describe-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package. (required)
  --format: string@format-completer # A format that specifies the type of the requested package. (required)
  --namespace: string # The namespace of the requested package. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace is required when requesting Maven packages. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the requested package. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/package"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the package origin configuration for a package. The package origin configuration determines how new versions of a package can be added to a repository. You can allow or block direct publishing of new package versions, or ingestion and retaining of new package versions from an external connection or upstream source. For more information about package origin controls and configuration, see Editing package origin controls (https://docs.aws.amazon.com/codeartifact/latest/ug/package-origin-controls.html) in the CodeArtifact User Guide. PutPackageOriginConfiguration can be called on a package that doesn't yet exist in the repository. When called on a package that does not exist, a package is created in the repository with no versions and the requested restrictions are set on the package. This can be used to preemptively block ingesting or retaining any versions from external connections or upstream repositories, or to block publishing any versions of the package into the repository before connecting any package managers or publishers to the repository.
#
# POST /v1/package
# Returns: record<originConfiguration: record<restrictions: record<publish: string, upstream: string>>>
# operationId: PutPackageOriginConfiguration
export def "put-package-origin-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package. (required)
  --format: string@format-completer # A format that specifies the type of the package to be updated. (required)
  --namespace: string # The namespace of the package to be updated. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package to be updated. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  restrictions: record # Details about the origin restrictions set on the package. The package origin restrictions determine how new versions of a package can be added to a specific repository. — shape: {publish?: "ALLOW"|"BLOCK", upstream?: "ALLOW"|"BLOCK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: restrictions, var: restrictions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, restrictions: $restrictions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more versions of a package. A deleted package version cannot be restored in your repository. If you want to remove a package version from your repository and be able to restore it later, set its status to Archived. Archived packages cannot be downloaded from a repository and don't show up with list package APIs (for example, ListPackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html)), but you can restore them using UpdatePackageVersionsStatus (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_UpdatePackageVersionsStatus.html).
#
# POST /v1/package/versions/delete
# Returns: record<successfulVersions: record, failedVersions: record>
# operationId: DeletePackageVersions
export def "delete-package-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the package to delete. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package versions to delete. (required)
  --format: string@format-completer # The format of the package versions to delete. (required)
  --namespace: string # The namespace of the package versions to be deleted. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace is required when deleting Maven package versions. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the versions to delete. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # An array of strings that specify the versions of the package to delete.
  --expected-status: string@expected-status-completer # The expected status of the package version to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package/versions/delete"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: versions, var: versions}, {name: expectedStatus, var: expected_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, versions: $versions, expected_status: $expected_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the resource policy that is set on a repository. After a resource policy is deleted, the permissions allowed and denied by the deleted policy are removed. The effect of deleting a resource policy might not be immediate. Use DeleteRepositoryPermissionsPolicy with caution. After a policy is deleted, Amazon Web Services users, roles, and accounts lose permissions to perform the repository actions granted by the deleted policy.
#
# DELETE /v1/repository/permissions/policies
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: DeleteRepositoryPermissionsPolicy
export def "delete-repository-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository associated with the resource policy to be deleted. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that is associated with the resource policy to be deleted (required)
  --policy-revision: string # The revision of the repository's resource policy to be deleted. This revision is used for optimistic locking, which prevents others from accidentally overwriting your changes to the repository's resource policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/repository/permissions/policies"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: policy-revision, var: policy_revision}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, policy_revision: $policy_revision, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a PackageVersionDescription (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionDescription.html) object that contains information about the requested package version.
#
# GET /v1/package/version
# Returns: record<packageVersion: record<format: string, namespace: string, packageName: string, displayName: string, version: string, summary: string, homePage: string, sourceCodeRepository: string, publishedTime: string, licenses: list<record>, revision: string, status: string, origin: record<domainEntryPoint: record, originType: string>>>
# operationId: DescribePackageVersion
export def "describe-package-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package version. (required)
  --format: string@format-completer # A format that specifies the type of the requested package version. (required)
  --namespace: string # The namespace of the requested package version. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the requested package version. (required)
  --version: string # A string that contains the package version (for example, 3.5.2). (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/package/version"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the assets in package versions and sets the package versions' status to Disposed. A disposed package version cannot be restored in your repository because its assets are deleted. To view all disposed package versions in a repository, use ListPackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html) and set the status (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_ListPackageVersions.html#API_ListPackageVersions_RequestSyntax) parameter to Disposed. To view information about a disposed package version, use DescribePackageVersion (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DescribePackageVersion.html).
#
# POST /v1/package/versions/dispose
# Returns: record<successfulVersions: record, failedVersions: record>
# operationId: DisposePackageVersions
export def "dispose-package-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository you want to dispose. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package versions you want to dispose. (required)
  --format: string@format-completer # A format that specifies the type of package versions you want to dispose. (required)
  --namespace: string # The namespace of the package versions to be disposed. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the versions you want to dispose. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # The versions of the package you want to dispose.
  --version-revisions: record # The revisions of the package versions you want to dispose.
  --expected-status: string@expected-status-completer # The expected status of the package version to dispose.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package/versions/dispose"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: versions, var: versions}, {name: versionRevisions, var: version_revisions}, {name: expectedStatus, var: expected_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, versions: $versions, version_revisions: $version_revisions, expected_status: $expected_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a temporary authorization token for accessing repositories in the domain. This API requires the codeartifact:GetAuthorizationToken and sts:GetServiceBearerToken permissions. For more information about authorization tokens, see CodeArtifact authentication and tokens (https://docs.aws.amazon.com/codeartifact/latest/ug/tokens-authentication.html). CodeArtifact authorization tokens are valid for a period of 12 hours when created with the login command. You can call login periodically to refresh the token. When you create an authorization token with the GetAuthorizationToken API, you can set a custom authorization period, up to a maximum of 12 hours, with the durationSeconds parameter. The authorization period begins after login or GetAuthorizationToken is called. If login or GetAuthorizationToken is called while assuming a role, the token lifetime is independent of the maximum session duration of the role. For example, if you call sts assume-role and specify a session duration of 15 minutes, then generate a CodeArtifact authorization token, the token will be valid for the full authorization period even though this is longer than the 15-minute session duration. See Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html) for more information on controlling session duration.
#
# POST /v1/authorization-token
# Returns: record<authorizationToken: string, expiration: string>
# operationId: GetAuthorizationToken
export def "get-authorization-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that is in scope for the generated authorization token. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --duration: int # The time, in seconds, that the generated authorization token is valid. Valid values are 0 and any number between 900 (15 minutes) and 43200 (12 hours). A value of 0 will set the expiration of the authorization token to the same expiration of the user's role's temporary credentials.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/authorization-token"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: duration, var: duration}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, duration: $duration, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an asset (or file) that is in a package. For example, for a Maven package version, use GetPackageVersionAsset to download a JAR file, a POM file, or any other assets in the package version.
#
# GET /v1/package/version/asset
# Returns: record<asset: string>
# operationId: GetPackageVersionAsset
export def "get-package-version-asset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version with the requested asset. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package version with the requested asset. (required)
  --format: string@format-completer # A format that specifies the type of the package version with the requested asset file. (required)
  --namespace: string # The namespace of the package version with the requested asset file. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the requested asset. (required)
  --version: string # A string that contains the package version (for example, 3.5.2). (required)
  --asset: string # The name of the requested asset. (required)
  --revision: string # The name of the package version revision that contains the requested asset.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/package/version/asset"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}, {name: asset, var: asset, required: true}, {name: revision, var: revision}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, asset: $asset, revision: $revision, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the readme file or descriptive text for a package version. The returned text might contain formatting. For example, it might contain formatting for Markdown or reStructuredText.
#
# GET /v1/package/version/readme
# Returns: record<format: string, namespace: string, package: string, version: string, versionRevision: string, readme: string>
# operationId: GetPackageVersionReadme
export def "get-package-version-readme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version with the requested readme file. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package with the requested readme file. (required)
  --format: string@format-completer # A format that specifies the type of the package version with the requested readme file. (required)
  --namespace: string # The namespace of the package version with the requested readme file. The package version component that specifies its namespace depends on its type. For example: The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace.
  --package: string # The name of the package version that contains the requested readme file. (required)
  --version: string # A string that contains the package version (for example, 3.5.2). (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/package/version/readme"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the endpoint of a repository for a specific package format. A repository has one endpoint for each package format: maven npm nuget pypi
#
# GET /v1/repository/endpoint
# Returns: record<repositoryEndpoint: string>
# operationId: GetRepositoryEndpoint
export def "get-repository-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain that contains the repository. It does not include dashes or spaces.
  --repository: string # The name of the repository. (required)
  --format: string@format-completer # Returns which endpoint of a repository to return. A repository has one endpoint for each package format. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/repository/endpoint"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the resource policy that is set on a repository.
#
# GET /v1/repository/permissions/policy
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: GetRepositoryPermissionsPolicy
export def "get-repository-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain containing the repository whose associated resource policy is to be retrieved. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository whose associated resource policy is to be retrieved. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/repository/permissions/policy"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the resource policy on a repository that specifies permissions to access it. When you call PutRepositoryPermissionsPolicy, the resource policy on the repository is ignored when evaluting permissions. This ensures that the owner of a repository cannot lock themselves out of the repository, which would prevent them from being able to update the resource policy.
#
# PUT /v1/repository/permissions/policy
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: PutRepositoryPermissionsPolicy
export def "put-repository-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain containing the repository to set the resource policy on. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository to set the resource policy on. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --policy-revision: string # Sets the revision of the resource policy that specifies permissions to access the repository. This revision is used for optimistic locking, which prevents others from overwriting your changes to the repository's resource policy.
  policy_document: string # A valid displayable JSON Aspen policy string to be set as the access control resource policy on the provided repository.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/repository/permissions/policy"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: policyRevision, var: policy_revision}, {name: policyDocument, var: policy_document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy_revision: $policy_revision, policy_document: $policy_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DomainSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionDescription.html) objects for all domains owned by the Amazon Web Services account that makes this call. Each returned DomainSummary object contains information about a domain.
#
# POST /v1/domains
# Returns: record<domains: table<name: string, owner: string, arn: string, status: string, createdTime: string, encryptionKey: string>, nextToken: string>
# operationId: ListDomains
export def "list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-max-results: int # The maximum number of results to return per page. (spec name: maxResults)
  --body-next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of AssetSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_AssetSummary.html) objects for assets in a package version.
#
# POST /v1/package/version/assets
# Returns: record<format: string, namespace: string, package: string, version: string, versionRevision: string, nextToken: string, assets: table<name: string, size: int, hashes: record>>
# operationId: ListPackageVersionAssets
export def "list-package-version-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository associated with the package version assets. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the package that contains the requested package version assets. (required)
  --format: string@format-completer # The format of the package that contains the requested package version assets. (required)
  --namespace: string # The namespace of the package version that contains the requested package version assets. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package that contains the requested package version assets. (required)
  --version: string # A string that contains the package version (for example, 3.5.2). (required)
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: maxResults)
  --qp-next-token: string # Pagination token (spec name: nextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/package/version/assets"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: maxResults, var: qp_max_results}, {name: nextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the direct dependencies for a package version. The dependencies are returned as PackageDependency (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageDependency.html) objects. CodeArtifact extracts the dependencies for a package version from the metadata file for the package format (for example, the package.json file for npm packages and the pom.xml file for Maven). Any package version dependencies that are not listed in the configuration file are not returned.
#
# POST /v1/package/version/dependencies
# Returns: record<format: string, namespace: string, package: string, version: string, versionRevision: string, nextToken: string, dependencies: table<namespace: string, package: string, dependencyType: string, versionRequirement: string>>
# operationId: ListPackageVersionDependencies
export def "list-package-version-dependencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested package version dependencies. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package version. (required)
  --format: string@format-completer # The format of the package with the requested dependencies. (required)
  --namespace: string # The namespace of the package version with the requested dependencies. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package versions' package. (required)
  --version: string # A string that contains the package version (for example, 3.5.2). (required)
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/package/version/dependencies"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}, {name: next-token, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of PackageVersionSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageVersionSummary.html) objects for package versions in a repository that match the request parameters. Package versions of all statuses will be returned by default when calling list-package-versions with no --status parameter.
#
# POST /v1/package/versions
# Returns: record<defaultDisplayVersion: string, format: string, namespace: string, package: string, versions: table<version: string, revision: string, status: string, origin: record>, nextToken: string>
# operationId: ListPackageVersions
export def "list-package-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested package versions. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested package versions. (required)
  --format: string@format-completer # The format of the package versions you want to list. (required)
  --namespace: string # The namespace of the package that contains the requested package versions. The package component that specifies its namespace depends on its type. For example: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package for which you want to request package versions. (required)
  --status: string@status-completer # A string that filters the requested package versions by status.
  --sort-by: string@sort-by-completer # How to sort the requested list of package versions.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --origin-type: string@origin-type-completer # The originType used to filter package versions. Only package versions with the provided originType will be returned.
  --qp-max-results: string # Pagination limit (spec name: maxResults)
  --qp-next-token: string # Pagination token (spec name: nextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/package/versions"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: status, var: status}, {name: sortBy, var: sort_by}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: originType, var: origin_type}, {name: maxResults, var: qp_max_results}, {name: nextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, status: $status, sort_by: $sort_by, max_results: $max_results, next_token: $next_token, origin_type: $origin_type, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of PackageSummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageSummary.html) objects for packages in a repository that match the request parameters.
#
# POST /v1/packages
# Returns: record<packages: table<format: string, namespace: string, package: string, originConfiguration: record>, nextToken: string>
# operationId: ListPackages
export def "list-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the requested packages. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that contains the requested packages. (required)
  --format: string@format-completer # The format used to filter requested packages. Only packages from the provided format will be returned.
  --namespace: string # The namespace prefix used to filter requested packages. Only packages with a namespace that starts with the provided string value are returned. Note that although this option is called --namespace and not --namespace-prefix, it has prefix-matching behavior. Each package format uses namespace as follows: The namespace of a Maven package is its groupId. The namespace of an npm package is its scope. Python and NuGet packages do not contain a corresponding component, packages of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package-prefix: string # A prefix used to filter requested packages. Only packages with names that start with packagePrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --publish: string@publish-completer # The value of the Publish package origin control restriction used to filter requested packages. Only packages with the provided restriction are returned. For more information, see PackageOriginRestrictions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageOriginRestrictions.html).
  --upstream: string@upstream-completer # The value of the Upstream package origin control restriction used to filter requested packages. Only packages with the provided restriction are returned. For more information, see PackageOriginRestrictions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_PackageOriginRestrictions.html).
  --qp-max-results: string # Pagination limit (spec name: maxResults)
  --qp-next-token: string # Pagination token (spec name: nextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/packages"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format}, {name: namespace, var: namespace}, {name: package-prefix, var: package_prefix}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: publish, var: publish}, {name: upstream, var: upstream}, {name: maxResults, var: qp_max_results}, {name: nextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package_prefix: $package_prefix, max_results: $max_results, next_token: $next_token, publish: $publish, upstream: $upstream, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of RepositorySummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_RepositorySummary.html) objects. Each RepositorySummary contains information about a repository in the specified Amazon Web Services account and that matches the input parameters.
#
# POST /v1/repositories
# Returns: record<repositories: table<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, createdTime: string>, nextToken: string>
# operationId: ListRepositories
export def "list-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository-prefix: string # A prefix used to filter returned repositories. Only repositories with names that start with repositoryPrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: maxResults)
  --qp-next-token: string # Pagination token (spec name: nextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/repositories"
    query: [{name: repository-prefix, var: repository_prefix}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: maxResults, var: qp_max_results}, {name: nextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repository_prefix: $repository_prefix, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of RepositorySummary (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_RepositorySummary.html) objects. Each RepositorySummary contains information about a repository in the specified domain and that matches the input parameters.
#
# POST /v1/domain/repositories
# Returns: record<repositories: table<name: string, administratorAccount: string, domainName: string, domainOwner: string, arn: string, description: string, createdTime: string>, nextToken: string>
# operationId: ListRepositoriesInDomain
export def "list-repositories-in-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the returned list of repositories. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --administrator-account: string # Filter the list of repositories to only include those that are managed by the Amazon Web Services account ID.
  --repository-prefix: string # A prefix used to filter returned repositories. Only repositories with names that start with repositoryPrefix are returned.
  --max-results: int # The maximum number of results to return per page.
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --qp-max-results: string # Pagination limit (spec name: maxResults)
  --qp-next-token: string # Pagination token (spec name: nextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/domain/repositories"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: administrator-account, var: administrator_account}, {name: repository-prefix, var: repository_prefix}, {name: max-results, var: max_results}, {name: next-token, var: next_token}, {name: maxResults, var: qp_max_results}, {name: nextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, administrator_account: $administrator_account, repository_prefix: $repository_prefix, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about Amazon Web Services tags for a specified Amazon Resource Name (ARN) in CodeArtifact.
#
# POST /v1/tags
# Returns: record<tags: table<key: string, value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to get tags for. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/tags"
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new package version containing one or more assets (or files). The unfinished flag can be used to keep the package version in the Unfinished state until all of its assets have been uploaded (see Package version status (https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html#package-version-status.html#package-version-status) in the CodeArtifact user guide). To set the package version’s status to Published, omit the unfinished flag when uploading the final asset, or set the status using UpdatePackageVersionStatus (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_UpdatePackageVersionsStatus.html). Once a package version’s status is set to Published, it cannot change back to Unfinished. Only generic packages can be published using this API. For more information, see Using generic packages (https://docs.aws.amazon.com/codeartifact/latest/ug/using-generic.html) in the CodeArtifact User Guide.
#
# POST /v1/package/version/publish
# Returns: record<format: string, namespace: string, package: string, version: string, versionRevision: string, status: string, asset: record<name: string, size: int, hashes: record>>
# operationId: PublishPackageVersion
export def "publish-package-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package version to publish. (required)
  --domain-owner: string # The 12-digit account number of the AWS account that owns the domain. It does not include dashes or spaces.
  --repository: string # The name of the repository that the package version will be published to. (required)
  --format: string@format-completer # A format that specifies the type of the package version with the requested asset file. (required)
  --namespace: string # The namespace of the package version to publish.
  --package: string # The name of the package version to publish. (required)
  --version: string # The package version to publish (for example, 3.5.2). (required)
  --asset: string # The name of the asset to publish. Asset names can include Unicode letters and numbers, and the following special characters: ~ ! @ ^ & ( ) - ` _ + [ ] { } ; , . ` (required)
  --unfinished: oneof<nothing, bool> # Specifies whether the package version should remain in the unfinished state. If omitted, the package version status will be set to Published (see Package version status (https://docs.aws.amazon.com/codeartifact/latest/ug/packages-overview.html#package-version-status) in the CodeArtifact User Guide). Valid values: unfinished
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --hdr-x-amz-content-sha256: string # The SHA256 hash of the assetContent to publish. This value must be calculated by the caller and provided with the request (see Publishing a generic package (https://docs.aws.amazon.com/codeartifact/latest/ug/using-generic.html#publishing-generic-packages) in the CodeArtifact User Guide). This value is used as an integrity check to verify that the assetContent has not changed after it was originally sent. (required) (spec name: x-amz-content-sha256)
  asset_content: string # The content of the asset to publish.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package/version/publish"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}, {name: version, var: version, required: true}, {name: asset, var: asset, required: true}, {name: unfinished, var: unfinished}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-content-sha256, var: hdr_x_amz_content_sha256, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetContent, var: asset_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, version: $version, asset: $asset, unfinished: $unfinished, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, hdr_x_amz_content_sha256: $hdr_x_amz_content_sha256, asset_content: $asset_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets a resource policy on a domain that specifies permissions to access it. When you call PutDomainPermissionsPolicy, the resource policy on the domain is ignored when evaluting permissions. This ensures that the owner of a domain cannot lock themselves out of the domain, which would prevent them from being able to update the resource policy.
#
# PUT /v1/domain/permissions/policy
# Returns: record<policy: record<resourceArn: string, revision: string, document: string>>
# operationId: PutDomainPermissionsPolicy
export def "put-domain-permissions-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain: string # The name of the domain on which to set the resource policy.
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --policy-revision: string # The current revision of the resource policy to be set. This revision is used for optimistic locking, which prevents others from overwriting your changes to the domain's resource policy.
  policy_document: string # A valid displayable JSON Aspen policy string to be set as the access control resource policy on the provided domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/domain/permissions/policy"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: domainOwner, var: domain_owner}, {name: policyRevision, var: policy_revision}, {name: policyDocument, var: policy_document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain: $domain, domain_owner: $domain_owner, policy_revision: $policy_revision, policy_document: $policy_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or updates tags for a resource in CodeArtifact.
#
# POST /v1/tag
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource that you want to add or update tags for. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # The tags you want to modify or add to the resource. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/tag"
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from a resource in CodeArtifact.
#
# POST /v1/untag
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource that you want to remove tags from. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tag_keys: list<string> # The tag key for each tag that you want to remove from the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/untag"
    query: [{name: resourceArn, var: resource_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of one or more versions of a package. Using UpdatePackageVersionsStatus, you can update the status of package versions to Archived, Published, or Unlisted. To set the status of a package version to Disposed, use DisposePackageVersions (https://docs.aws.amazon.com/codeartifact/latest/APIReference/API_DisposePackageVersions.html).
#
# POST /v1/package/versions/update_status
# Returns: record<successfulVersions: record, failedVersions: record>
# operationId: UpdatePackageVersionsStatus
export def "update-package-versions-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The name of the domain that contains the repository that contains the package versions with a status to be updated. (required)
  --domain-owner: string # The 12-digit account number of the Amazon Web Services account that owns the domain. It does not include dashes or spaces.
  --repository: string # The repository that contains the package versions with the status you want to update. (required)
  --format: string@format-completer # A format that specifies the type of the package with the statuses to update. (required)
  --namespace: string # The namespace of the package version to be updated. The package version component that specifies its namespace depends on its type. For example: The namespace of a Maven package version is its groupId. The namespace of an npm package version is its scope. Python and NuGet package versions do not contain a corresponding component, package versions of those formats do not have a namespace. The namespace of a generic package is its namespace.
  --package: string # The name of the package with the version statuses to update. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  versions: list<string> # An array of strings that specify the versions of the package with the statuses to update.
  --version-revisions: record # A map of package versions and package version revisions. The map key is the package version (for example, 3.5.2), and the map value is the package version revision.
  --expected-status: string@expected-status-completer # The package version’s expected status before it is updated. If expectedStatus is provided, the package version's status is updated only if its status at the time UpdatePackageVersionsStatus is called matches expectedStatus.
  target_status: string@target-status-completer # The status you want to change the package version status to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/package/versions/update_status"
    query: [{name: domain, var: domain, required: true}, {name: domain-owner, var: domain_owner}, {name: repository, var: repository, required: true}, {name: format, var: format, required: true}, {name: namespace, var: namespace}, {name: package, var: package, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: versions, var: versions}, {name: versionRevisions, var: version_revisions}, {name: expectedStatus, var: expected_status}, {name: targetStatus, var: target_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, domain_owner: $domain_owner, repository: $repository, format: $format, namespace: $namespace, package: $package, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, versions: $versions, version_revisions: $version_revisions, expected_status: $expected_status, target_status: $target_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
