# Auto-generated client for ID4i API v1.0.2
# Source: https://api.apis.guru/v2/specs/id4i.de/1.0.2/openapi.json
# Auth: --token flag or $env.ID4I_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//backend.id4i.de"
  token_env_var: "ID4I_API_TOKEN"
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

def base-url-completer [] { ["http://localhost//backend.id4i.de"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def type-completer [] { ["LABELLED_COLLECTION" "LOGISTIC_COLLECTION" "ROUTING_COLLECTION"] }
def physical-state-completer [] { ["ATTACHED" "DETACHED" "UNATTACHED"] }
def type-completer-1 [] { ["CREATED" "DELIVERY_REFUSED" "DESTROYED" "DISASSEMBLED" "DISPATCHED" "MAINTENANCE_CANCELLED" "MAINTENANCE_FINISHED" "MAINTENANCE_STARTED" "MAINTENANCE_STEP_CANCELLED" "MAINTENANCE_STEP_FINISHED" "MAINTENANCE_STEP_STARTED" "PACKAGED" "PRODUCTION_CANCELLED" "PRODUCTION_FINISHED" "PRODUCTION_STARTED" "PRODUCTION_STEP_CANCELLED" "PRODUCTION_STEP_FINISHED" "PRODUCTION_STEP_STARTED" "QUALITY_CHECK_PERFORMED" "RECEIVED" "RECYCLED" "REPROCESSING_CANCELLED" "REPROCESSING_FINISHED" "REPROCESSING_STARTED" "REPROCESSING_STEP_CANCELLED" "REPROCESSING_STEP_FINISHED" "REPROCESSING_STEP_STARTED" "RETRIEVED_FROM_STORAGE" "SHIPMENT_PREPARED" "STORED"] }
def alias-type-completer [] { ["article" "eclass" "gtin" "item" "mapp" "material" "product" "reference" "rfid" "tracking" "unspsc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    request-password-reset: "record<message: string>"
    verify-password-reset: "record<message: string>"
    register-user: "record<email: string, id: int, message: string, username: string>"
    list-all-api-keys-of-organization: "record<elements: table<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>, limit: int, offset: int, total: int>"
    create-new-api-key: "record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>"
    list-all-api-key-privileges: "record<elements: table<allowsBillableOperations: bool, helpText: string, id4nAssociated: bool, name: string>, limit: int, offset: int, total: int>"
    get-api-key: "record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>"
    list-api-key-privileges: "record<elements: table<id4nAssociated: bool, privilege: string>, limit: int, offset: int, total: int>"
    list-id4ns: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string>, limit: int, offset: int, total: int>"
    get-sum-for-organization: "record<listing: record>"
    get-positions-for-organization: "table<amount: int, count: float, description: string, service: string, singlePrice: float, sum: float, unit: string>"
    list-organization-change-log: "record<elements: table<id: string, message: string, messageProperties: record, timestamp: int>, limit: int, offset: int, total: int>"
    create-collection: "record<id4n: string>"
    find-collection: "record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>"
    update-collection: "record"
    list-elements-of-collection: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>"
    list-countries: "record<elements: table<code: string, name: string>, limit: int, offset: int, total: int>"
    list-all-documents: "record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>"
    list-documents: "record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>"
    create-document: "record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    put-document: "record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    read-document: "string"
    get-document: "record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    update-document-metadata: "record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    create-guid: "record<id4ns: list<string>>"
    get-guids-without-collection: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>"
    get-guid: "record<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>"
    update-guid: "record"
    filtered-list: "record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>"
    list: "record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>"
    retrieve-item: "record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    update-item: "record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    update-item-visibility: "record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    get-id4n: "record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string>"
    get-guid-aliases: "record"
    get-collections: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int>"
    get-properties: "record"
    application-info: "record<branch: string, commitTime: string, name: string, productionMode: bool, revision: string, version: string>"
    read-from-microstorage: "string"
    write-to-microstorage: "record"
    get-multiple-properties: "record<list: table<id4n: string, properties: record>>"
    create-organization: "record<id: int, logoURL: string, name: string, namespace: string>"
    find-organization: "record<id: int, logoURL: string, name: string, namespace: string>"
    update-organization: "record<id: int, logoURL: string, name: string, namespace: string>"
    find-organization-billing-address: "record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>"
    update-organization-billing-address: "record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>"
    find-organization-address: "record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>"
    update-organization-address: "record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>"
    get-all-collections-of-organization: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int>"
    set-organization-logo: "record<uri: string>"
    get-default-queue: "record<active: bool, id: string, waitingMessages: int>"
    get-partner-organizations: "record<elements: table<logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int>"
    get-organization-privileges: "list<string>"
    get-all-organization-roles: "record<elements: table<roles: list, user: record>, limit: int, offset: int, total: int>"
    get-users-of-organization: "record<elements: table<id: string, name: string>, limit: int, offset: int, total: int>"
    get-user-roles: "record<elements: list<string>, limit: int, offset: int, total: int>"
    list-all-public-documents: "record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>"
    read-public-document: "string"
    get-public-document: "record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>"
    list-public-history: "record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>"
    resolve-image-using-get: "string"
    read-organization-info: "record<id: int, logoURL: string, name: string, namespace: string>"
    get-routes: "table<params: record, priority: int, public: bool, type: string, validUntil: int>"
    list-all-roles: "record<elements: table<name: string, privileges: list>, limit: int, offset: int, total: int>"
    get-routing-file: "record<options: record<deleteOutdatedRoutes: bool>, routes: table<params: record, priority: int, public: bool, type: string, validUntil: int>>"
    get-route: "record<params: record, priority: int, public: bool, type: string, validUntil: int>"
    get-all-routes: "table<params: record, priority: int, public: bool, type: string, validUntil: int>"
    search-by-alias: "record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>"
    get-guid-alias-types: "list<string>"
    get-send-info: "record<holderOrganizationId: string, keepOwnership: bool, openForClaims: bool, ownerOrganizationId: string, recipientOrganizationIds: list<string>>"
    prepare: "record"
    get-organizations-of-user: "record<elements: table<id: int, logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int>"
    find-users: "record<elements: table<id: string, name: string>, limit: int, offset: int, total: int>"
    find-user-by-username: "record<id: string, name: string>"
    resolve-who-is-entry: "record<aliases: record, organization: record<id: int, logoURL: string, name: string, namespace: string>, organizationAddress: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["request-password-reset" "verify-password-reset" "register-user" "complete-registration" "verify-user-registration" "list-all-api-keys-of-organization" "create-new-api-key" "list-all-api-key-privileges" "delete-api-key" "get-api-key" "update-api-key" "remove-api-key-privilege" "list-api-key-privileges" "add-api-key-privilege" "remove-api-key-privilege-for-id4ns" "list-id4ns" "add-api-key-privilege-for-id4ns" "get-sum-for-organization" "get-positions-for-organization" "list-organization-change-log" "create-collection" "delete-collection" "find-collection" "update-collection" "remove-elements-from-collection" "list-elements-of-collection" "add-elements-to-collection" "list-countries" "list-all-documents" "list-documents" "create-document" "put-document" "delete-document" "read-document" "get-document" "update-document-metadata" "create-guid" "get-guids-without-collection" "get-guid" "update-guid" "filtered-list" "add-item" "list" "retrieve-item" "update-item" "update-item-visibility" "get-id4n" "get-guid-aliases" "remove-guid-alias" "add-guid-alias" "get-collections" "delete-properties" "get-properties" "patch-properties" "import-gs1-codes" "application-info" "read-from-microstorage" "write-to-microstorage" "get-multiple-properties" "create-organization" "delete-organization" "find-organization" "update-organization" "delete-organization-billing-address" "find-organization-billing-address" "update-organization-billing-address" "find-organization-address" "update-organization-address" "get-all-collections-of-organization" "delete-organization-logo" "set-organization-logo" "get-default-queue" "patch-default-queue" "enqueue-custom-message" "remove-partner-organization" "get-partner-organizations" "add-partner-organization" "get-organization-privileges" "get-all-organization-roles" "get-users-of-organization" "invite-users" "remove-user-roles" "get-user-roles" "add-user-roles" "list-all-public-documents" "read-public-document" "get-public-document" "list-public-history" "resolve-image-using-get" "read-organization-info" "get-routes" "list-all-roles" "get-routing-file" "update-routing-file" "get-route" "get-all-routes" "search-by-alias" "get-guid-alias-types" "receive" "get-send-info" "prepare" "get-organizations-of-user" "find-users" "find-user-by-username" "go" "login" "resolve-who-is-entry" "commands"] | sort) } | get name | first)
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

# Request password reset
#
# POST /account/password
# Returns: record<message: string>
# operationId: requestPasswordReset
export def "request-password-reset" [
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
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/password"
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Verify password reset
#
# PUT /account/password
# Returns: record<message: string>
# operationId: verifyPasswordReset
export def "verify-password-reset" [
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
  password: string
  --body-token: string # (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/password"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: token, var: body_token, required: true}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    password: $password, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register user
#
# POST /account/registration
# Returns: record<email: string, id: int, message: string, username: string>
# operationId: registerUser
export def "register-user" [
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
  password: string
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/registration"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    email: $email, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Complete registration
#
# PUT /account/registration
# operationId: completeRegistration
export def "complete-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
  username: string
  verification_token: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/account/registration"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}, {name: verificationToken, var: verification_token}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    password: $password, username: $username, verification_token: $verification_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify registration
#
# POST /account/verification
# operationId: verifyUserRegistration
export def "verify-user-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/verification"
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find API key by organization
#
# GET /api/v1/apikeys
# Returns: record<elements: table<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>, limit: int, offset: int, total: int>
# operationId: listAllApiKeysOfOrganization
export def "list-all-api-keys-of-organization" [
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
  --organization-id: string # The namespace of the organization to search in.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/apikeys"
    query: [{name: organizationId, var: organization_id}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create API key
#
# POST /api/v1/apikeys
# Returns: record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>
# operationId: createNewApiKey
export def "create-new-api-key" [
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
  label: string
  organization_id: string # e.g. de.acme
  secret: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/apikeys"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: organizationId, var: organization_id}, {name: secret, var: secret}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    label: $label, organization_id: $organization_id, secret: $secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all privileges
#
# GET /api/v1/apikeys/privileges
# Returns: record<elements: table<allowsBillableOperations: bool, helpText: string, id4nAssociated: bool, name: string>, limit: int, offset: int, total: int>
# operationId: listAllApiKeyPrivileges
export def "list-all-api-key-privileges" [
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
  --id4n-concerning: oneof<nothing, bool> # id4nConcerning
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/apikeys/privileges"
    query: [{name: id4nConcerning, var: id4n_concerning}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n_concerning: $id4n_concerning, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete API key
#
# DELETE /api/v1/apikeys/{key}
# operationId: deleteApiKey
export def "delete-api-key" [
  key: string
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
    path: "/api/v1/apikeys/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show API key
#
# GET /api/v1/apikeys/{key}
# Returns: record<active: bool, createdAt: int, createdBy: string, key: string, label: string, organizationId: string>
# operationId: getApiKey
export def "get-api-key" [
  key: string
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
    path: "/api/v1/apikeys/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update API keys
#
# PUT /api/v1/apikeys/{key}
# operationId: updateApiKey
export def "update-api-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  new_label: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/apikeys/{key}"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: newLabel, var: new_label}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    key: $key, active: $active, new_label: $new_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove privilege
#
# DELETE /api/v1/apikeys/{key}/privileges
# operationId: removeApiKeyPrivilege
export def "remove-api-key-privilege" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  privilege: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/apikeys/{key}/privileges"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: privilege, var: privilege}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, privilege: $privilege
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List privileges
#
# GET /api/v1/apikeys/{key}/privileges
# Returns: record<elements: table<id4nAssociated: bool, privilege: string>, limit: int, offset: int, total: int>
# operationId: listApiKeyPrivileges
export def "list-api-key-privileges" [
  key: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/apikeys/{key}/privileges"
    path_params: [{name: key, var: key}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    key: $key, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add privilege
#
# POST /api/v1/apikeys/{key}/privileges
# operationId: addApiKeyPrivilege
export def "add-api-key-privilege" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  privilege: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/apikeys/{key}/privileges"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: privilege, var: privilege}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    key: $key, privilege: $privilege
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove id4ns of a privilege
#
# DELETE /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# operationId: removeApiKeyPrivilegeForId4ns
export def "remove-api-key-privilege-for-id4ns" [
  key: string
  privilege: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns"
    path_params: [{name: key, var: key}, {name: privilege, var: privilege}]
    body: {content_type: "application/json", kind: json, fields: [{name: id4ns, var: id4ns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, privilege: $privilege, id4ns: $id4ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ID4ns of a privilege
#
# GET /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string>, limit: int, offset: int, total: int>
# operationId: listId4ns
export def "list-id4ns" [
  key: string
  privilege: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns"
    path_params: [{name: key, var: key}, {name: privilege, var: privilege}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    key: $key, privilege: $privilege, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add ID4ns of a privilege
#
# POST /api/v1/apikeys/{key}/privileges/{privilege}/id4ns
# operationId: addApiKeyPrivilegeForId4ns
export def "add-api-key-privilege-for-id4ns" [
  key: string
  privilege: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/apikeys/{key}/privileges/{privilege}/id4ns"
    path_params: [{name: key, var: key}, {name: privilege, var: privilege}]
    body: {content_type: "application/json", kind: json, fields: [{name: id4ns, var: id4ns}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    key: $key, privilege: $privilege, id4ns: $id4ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get billing amount of services for a given organization
#
# GET /api/v1/billing/{organizationId}
# Returns: record<listing: record>
# operationId: getSumForOrganization
export def "get-sum-for-organization" [
  organization_id: string
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
  --from-date: string # Billing start date (format: date-time)
  --to-date: string # Billing end date (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/billing/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, from_date: $from_date, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get billing positions for a given organization
#
# GET /api/v1/billing/{organizationId}/positions
# Returns: table<amount: int, count: float, description: string, service: string, singlePrice: float, sum: float, unit: string>
# operationId: getPositionsForOrganization
export def "get-positions-for-organization" [
  organization_id: string
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
  --from-date: string # Billing start date (format: date-time)
  --to-date: string # Billing end date (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/billing/{organizationId}/positions"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, from_date: $from_date, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List change log entries of an organization
#
# GET /api/v1/changelog/organization/{organizationId}/
# Returns: record<elements: table<id: string, message: string, messageProperties: record, timestamp: int>, limit: int, offset: int, total: int>
# operationId: listOrganizationChangeLog
export def "list-organization-change-log" [
  organization_id: string
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
  --message-mime-type: string # The Mime-type for the message format that should be returned. e.g. 'text/plain' or 'text/mustache' (default: text/mustache)
  --from-date: string # From date time as UTC Date-Time format (format: date-time)
  --to-date: string # To date time as UTC Date-Time format (format: date-time)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/changelog/organization/{organizationId}/"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: messageMimeType, var: message_mime_type}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, message_mime_type: $message_mime_type, from_date: $from_date, to_date: $to_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create collection
#
# POST /api/v1/collections
# Returns: record<id4n: string>
# operationId: createCollection
export def "create-collection" [
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
  --label: string
  length: int # format: int32
  organization_id: string # e.g. de.acme
  type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/collections"
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}, {name: length, var: length}, {name: organizationId, var: organization_id}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    label: $label, length: $length, organization_id: $organization_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete collection
#
# DELETE /api/v1/collections/{id4n}
# operationId: deleteCollection
export def "delete-collection" [
  id4n: string
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
    path: "/api/v1/collections/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id4n: $id4n
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find collection
#
# GET /api/v1/collections/{id4n}
# Returns: record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>
# operationId: findCollection
export def "find-collection" [
  id4n: string
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
    path: "/api/v1/collections/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update collection
#
# PATCH /api/v1/collections/{id4n}
# Returns: record
# operationId: updateCollection
export def "update-collection" [
  id4n: string
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
  --holder-organization-id: string # Organization namespace of the holder of the collection
  --label: string
  --physical-state: string@physical-state-completer # Physical attachment state of the collection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/collections/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: holderOrganizationId, var: holder_organization_id}, {name: label, var: label}, {name: physicalState, var: physical_state}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    id4n: $id4n, holder_organization_id: $holder_organization_id, label: $label, physical_state: $physical_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove elements from collection
#
# DELETE /api/v1/collections/{id4n}/elements
# operationId: removeElementsFromCollection
export def "remove-elements-from-collection" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/collections/{id4n}/elements"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: id4ns, var: id4ns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id4n: $id4n, id4ns: $id4ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List contents of the collection
#
# GET /api/v1/collections/{id4n}/elements
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>
# operationId: listElementsOfCollection
export def "list-elements-of-collection" [
  id4n: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
  --organization-id: string # The organization namespace.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/collections/{id4n}/elements"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, offset: $offset, limit: $limit, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add elements to collection
#
# POST /api/v1/collections/{id4n}/elements
# operationId: addElementsToCollection
export def "add-elements-to-collection" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id4ns: list<string> # A list of id4ns.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/collections/{id4n}/elements"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: id4ns, var: id4ns}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    id4n: $id4n, id4ns: $id4ns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List countries
#
# GET /api/v1/countries
# Returns: record<elements: table<code: string, name: string>, limit: int, offset: int, total: int>
# operationId: listCountries
export def "list-countries" [
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/countries"
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List documents
#
# GET /api/v1/documents/{id4n}
# Returns: record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: listAllDocuments
export def "list-all-documents" [
  id4n: string
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
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: owner, var: owner}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, owner: $owner, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List organization specific documents
#
# GET /api/v1/documents/{id4n}/{organizationId}
# Returns: record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: listDocuments
export def "list-documents" [
  id4n: string
  organization_id: string
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
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/documents/{id4n}/{organizationId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}]
    query: [{name: owner, var: owner}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, owner: $owner, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an document for an id4n
#
# POST /api/v1/documents/{id4n}/{organizationId}
# Returns: record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: createDocument
export def "create-document" [
  id4n: string
  organization_id: string
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
  content: string # content (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/documents/{id4n}/{organizationId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}], files: [content]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Put an document for an id4n
#
# PUT /api/v1/documents/{id4n}/{organizationId}
# Returns: record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: putDocument
export def "put-document" [
  id4n: string
  organization_id: string
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
  content: string # content (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/documents/{id4n}/{organizationId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}], files: [content]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a document
#
# DELETE /api/v1/documents/{id4n}/{organizationId}/{fileName}
# operationId: deleteDocument
export def "delete-document" [
  id4n: string
  organization_id: string
  file_name: string
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
    path: "/api/v1/documents/{id4n}/{organizationId}/{fileName}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read document contents
#
# GET /api/v1/documents/{id4n}/{organizationId}/{fileName}
# Returns: string
# operationId: readDocument
export def "read-document" [
  id4n: string
  organization_id: string
  file_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/documents/{id4n}/{organizationId}/{fileName}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a document (meta-data only, no content)
#
# GET /api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata
# Returns: record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: getDocument
export def "get-document" [
  id4n: string
  organization_id: string
  file_name: string
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
    path: "/api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a document
#
# PATCH /api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata
# Returns: record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: updateDocumentMetadata
export def "update-document-metadata" [
  id4n: string
  organization_id: string
  file_name: string
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
  --filename: string # File Name (e.g. publicInfo.pdf)
  --mime-type: string # Mime Type (e.g. text/plain)
  --visibility: record # shape: {public?: bool, sharedWithOrganizationIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/documents/{id4n}/{organizationId}/{fileName}/metadata"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: filename, var: filename}, {name: mimeType, var: mime_type}, {name: visibility, var: visibility}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name, filename: $filename, mime_type: $mime_type, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create GUID(s)
#
# POST /api/v1/guids
# Returns: record<id4ns: list<string>>
# operationId: createGuid
export def "create-guid" [
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
  count: int # The total number of GUIDs to create (format: int32, e.g. 1)
  length: int # The charactersequence length of the GUID (format: int32, e.g. 40)
  organization_id: string # The namespace of the organization where the generated GUIDs should be assigned. (e.g. de.acme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/guids"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: length, var: length}, {name: organizationId, var: organization_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    count: $count, length: $length, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve GUIDs not in any collection
#
# GET /api/v1/guids/withoutCollection
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>
# operationId: getGuidsWithoutCollection
export def "get-guids-without-collection" [
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
  --organization-id: string # The namespace of the organization to search GUIDs for (required)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/guids/withoutCollection"
    query: [{name: organizationId, var: organization_id, required: true}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve GUID information
#
# GET /api/v1/guids/{id4n}
# Returns: record<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>
# operationId: getGuid
export def "get-guid" [
  id4n: string
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
  --organization-id: string # The organization namespace to resolve.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/guids/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change GUID information.
#
# PATCH /api/v1/guids/{id4n}
# Returns: record
# operationId: updateGuid
export def "update-guid" [
  id4n: string
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
  --physical-state: string@physical-state-completer # Physical attachment state of the GUID
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/guids/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: physicalState, var: physical_state}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    id4n: $id4n, physical_state: $physical_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List history
#
# GET /api/v1/history/{id4n}
# Returns: record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: filteredList
export def "filtered-list" [
  id4n: string
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
  --include-private: oneof<nothing, bool> # Also return private history entries (default: true)
  --organization: string # Show only entries created by one of the given organizations. This parameter can be used multiple times.
  --type: list<string>@type-completer-1 # Show only entries matching one of the given history item types. This parameter can be used multiple times.
  --qualifier: list<string> # Show only entries matching one of the given history item qualifiers (additional property de.id4i.history.item.qualifier). This parameter can be used multiple times.
  --from-date: string # From date time as UTC Date-Time format (format: date-time)
  --to-date: string # To date time as UTC Date-Time format (format: date-time)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/history/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: includePrivate, var: include_private}, {name: organization, var: organization}, {name: type, var: type, style: multi}, {name: qualifier, var: qualifier, style: multi}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, include_private: $include_private, organization: $organization, type: $type, qualifier: $qualifier, from_date: $from_date, to_date: $to_date, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add history item
#
# POST /api/v1/history/{id4n}
# operationId: addItem
export def "add-item" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-properties: record # History items custom additional properties
  organization_id: string # Originator of the history item (e.g. org.acme)
  type: string@type-completer-1 # Type of the history item (e.g. DISPATCHED)
  --visibility: record # shape: {public?: bool, sharedOrganizationIds?: list<string>}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/history/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalProperties, var: additional_properties}, {name: organizationId, var: organization_id}, {name: type, var: type}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    id4n: $id4n, additional_properties: $additional_properties, organization_id: $organization_id, type: $type, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DEPRECATED - List history
#
# GET /api/v1/history/{id4n}/{organizationId}
# DEPRECATED
# Returns: record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: list
@deprecated
export def "list" [
  id4n: string
  organization_id: string
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
  --include-private: oneof<nothing, bool> # Also return private history entries (default: true)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/history/{id4n}/{organizationId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}]
    query: [{name: includePrivate, var: include_private}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, include_private: $include_private, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get history item
#
# GET /api/v1/history/{id4n}/{organizationId}/{sequenceId}
# Returns: record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: retrieveItem
export def "retrieve-item" [
  id4n: string
  organization_id: string
  sequence_id: int
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
    path: "/api/v1/history/{id4n}/{organizationId}/{sequenceId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: sequenceId, var: sequence_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, sequence_id: $sequence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update history item
#
# PATCH /api/v1/history/{id4n}/{organizationId}/{sequenceId}
# Returns: record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: updateItem
export def "update-item" [
  id4n: string
  organization_id: string
  sequence_id: int
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
  --body-organization-id: string # New organization id displayed for this item. If given, must match the holder of GUID and the organization the history item is found under. (e.g. de.acme) (spec name: organizationId)
  --visibility: record # shape: {public?: bool, sharedOrganizationIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/history/{id4n}/{organizationId}/{sequenceId}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: sequenceId, var: sequence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: organizationId, var: body_organization_id}, {name: visibility, var: visibility}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, sequence_id: $sequence_id, body_organization_id: $body_organization_id, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set history item visibility
#
# PUT /api/v1/history/{id4n}/{organizationId}/{sequenceId}/visibility
# Returns: record<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: updateItemVisibility
export def "update-item-visibility" [
  id4n: string
  organization_id: string
  sequence_id: int
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
  --public: oneof<nothing, bool> # Document is publicly readable (if ID4N is owned by the same organization) (e.g. true)
  --shared-organization-ids: list<string> # Document is readable by these organizations (independend of ID4N ownership) (e.g. [de.acme, com.porsche, de.bluerain])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/history/{id4n}/{organizationId}/{sequenceId}/visibility"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: sequenceId, var: sequence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: public, var: public}, {name: sharedOrganizationIds, var: shared_organization_ids}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, sequence_id: $sequence_id, public: $public, shared_organization_ids: $shared_organization_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve ID4n information
#
# GET /api/v1/id4ns/{id4n}
# Returns: record<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, properties: record, type: string>
# operationId: getId4n
export def "get-id4n" [
  id4n: string
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
  --organization-id: string # The organization namespace to resolve.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/id4ns/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all aliases for the given GUID or Collection.
#
# GET /api/v1/id4ns/{id4n}/alias
# Returns: record
# operationId: getGuidAliases
export def "get-guid-aliases" [
  id4n: string
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
    path: "/api/v1/id4ns/{id4n}/alias"
    path_params: [{name: id4n, var: id4n}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove aliases from GUID or Collection
#
# DELETE /api/v1/id4ns/{id4n}/alias/{aliasType}
# operationId: removeGuidAlias
export def "remove-guid-alias" [
  id4n: string
  alias_type: string@alias-type-completer
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
    path: "/api/v1/id4ns/{id4n}/alias/{aliasType}"
    path_params: [{name: id4n, var: id4n}, {name: aliasType, var: alias_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id4n: $id4n, alias_type: $alias_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add alias for GUID or Collection
#
# POST /api/v1/id4ns/{id4n}/alias/{aliasType}
# operationId: addGuidAlias
export def "add-guid-alias" [
  id4n: string
  alias_type: string@alias-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alias: string # An alias (e.g. alias)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/id4ns/{id4n}/alias/{aliasType}"
    path_params: [{name: id4n, var: id4n}, {name: aliasType, var: alias_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    id4n: $id4n, alias_type: $alias_type, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve collections of an ID
#
# GET /api/v1/id4ns/{id4n}/collections
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int>
# operationId: getCollections
export def "get-collections" [
  id4n: string
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
  --organization-id: string # The organization holding the collections.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/id4ns/{id4n}/collections"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete ID4n properties
#
# DELETE /api/v1/id4ns/{id4n}/properties
# operationId: deleteProperties
export def "delete-properties" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The organization namespace to work on while deleting the properties. (required)
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/id4ns/{id4n}/properties"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id, required: true}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve ID4n properties
#
# GET /api/v1/id4ns/{id4n}/properties
# Returns: record
# operationId: getProperties
export def "get-properties" [
  id4n: string
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
  --organization-id: string # The organization namespace.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/id4ns/{id4n}/properties"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Patch ID4n properties
#
# PATCH /api/v1/id4ns/{id4n}/properties
# operationId: patchProperties
export def "patch-properties" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string # The organization namespace to work on while patching the properties. (required)
  --body: record
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/id4ns/{id4n}/properties"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import GS1/MAPP codes
#
# POST /api/v1/import/gs1
# operationId: importGS1Codes
export def "import-gs1-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  list_of_gs1s: record # A list of GS1/MAPP codes — shape: {codes?: list<string>}
  organization_id: string # The organization where the GS1/Mapp code is imported. (e.g. de.acme)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/import/gs1"
    body: {content_type: "application/json", kind: json, fields: [{name: listOfGS1s, var: list_of_gs1s}, {name: organizationId, var: organization_id}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    list_of_gs1s: $list_of_gs1s, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve version information about ID4i
#
# GET /api/v1/info
# Returns: record<branch: string, commitTime: string, name: string, productionMode: bool, revision: string, version: string>
# operationId: applicationInfo
export def "application-info" [
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
    path: "/api/v1/info"
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Read data from microstorage
#
# GET /api/v1/microstorage/{id4n}/{organization}
# Returns: string
# operationId: readFromMicrostorage
export def "read-from-microstorage" [
  id4n: string
  organization: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/microstorage/{id4n}/{organization}"
    path_params: [{name: id4n, var: id4n}, {name: organization, var: organization}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization: $organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Write data to microstorage
#
# PUT /api/v1/microstorage/{id4n}/{organization}
# Returns: record
# operationId: writeToMicrostorage
export def "write-to-microstorage" [
  id4n: string
  organization: string
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
  --content-type: string # Content-Type
  --content-length: int # Content-Length (format: int64)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/microstorage/{id4n}/{organization}"
    path_params: [{name: id4n, var: id4n}, {name: organization, var: organization}]
    header: [{name: Content-Type, var: content_type}, {name: Content-Length, var: content_length}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization: $organization, content_type: $content_type, content_length: $content_length, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get multiple ID4n properties
#
# GET /api/v1/multiple/id4ns/properties
# Returns: record<list: table<id4n: string, properties: record>>
# operationId: getMultipleProperties
export def "get-multiple-properties" [
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
  --id4ns: list<string> # The list of ID4ns to resolve. (required)
  --organization-id: string # The organization namespace.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/multiple/id4ns/properties"
    query: [{name: id4ns, var: id4ns, style: multi, required: true}, {name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4ns: $id4ns, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create organization
#
# POST /api/v1/organizations
# Returns: record<id: int, logoURL: string, name: string, namespace: string>
# operationId: createOrganization
export def "create-organization" [
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
  name: string # The name of the organization (e.g. ACME Inc.)
  namespace: string # The namespace of the organization (e.g. de.acme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/organizations"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: namespace, var: namespace}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    name: $name, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete organization
#
# DELETE /api/v1/organizations/{organizationId}
# operationId: deleteOrganization
export def "delete-organization" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find organization by id/namespace
#
# GET /api/v1/organizations/{organizationId}
# Returns: record<id: int, logoURL: string, name: string, namespace: string>
# operationId: findOrganization
export def "find-organization" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update organization
#
# PUT /api/v1/organizations/{organizationId}
# Returns: record<id: int, logoURL: string, name: string, namespace: string>
# operationId: updateOrganization
export def "update-organization" [
  organization_id: string
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
  --name: string # The name of the organization (e.g. ACME Inc.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove billing address
#
# DELETE /api/v1/organizations/{organizationId}/addresses/billing
# operationId: deleteOrganizationBillingAddress
export def "delete-organization-billing-address" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/addresses/billing"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve billing address
#
# GET /api/v1/organizations/{organizationId}/addresses/billing
# Returns: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>
# operationId: findOrganizationBillingAddress
export def "find-organization-billing-address" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/addresses/billing"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Store billing address
#
# PUT /api/v1/organizations/{organizationId}/addresses/billing
# Returns: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>
# operationId: updateOrganizationBillingAddress
export def "update-organization-billing-address" [
  organization_id: string
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
  city: string # e.g. MyCity
  --company-name: string # e.g. ACME Inc.
  country_code: string # The ISO 3166 two-letter country code (e.g. DE)
  firstname: string # e.g. Max
  lastname: string # e.g. Muster
  post_code: string # e.g. 12345
  street: string # e.g. Examplestreet 1
  --telephone: string # The telephone number e.g. (e.g. +49 8088 12345)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/organizations/{organizationId}/addresses/billing"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: companyName, var: company_name}, {name: countryCode, var: country_code}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: postCode, var: post_code}, {name: street, var: street}, {name: telephone, var: telephone}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, city: $city, company_name: $company_name, country_code: $country_code, firstname: $firstname, lastname: $lastname, post_code: $post_code, street: $street, telephone: $telephone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve address
#
# GET /api/v1/organizations/{organizationId}/addresses/default
# Returns: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>
# operationId: findOrganizationAddress
export def "find-organization-address" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/addresses/default"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Store address
#
# PUT /api/v1/organizations/{organizationId}/addresses/default
# Returns: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>
# operationId: updateOrganizationAddress
export def "update-organization-address" [
  organization_id: string
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
  city: string # e.g. MyCity
  --company-name: string # e.g. ACME Inc.
  country_code: string # The ISO 3166 two-letter country code (e.g. DE)
  firstname: string # e.g. Max
  lastname: string # e.g. Muster
  post_code: string # e.g. 12345
  street: string # e.g. Examplestreet 1
  --telephone: string # The telephone number e.g. (e.g. +49 8088 12345)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/organizations/{organizationId}/addresses/default"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: companyName, var: company_name}, {name: countryCode, var: country_code}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: postCode, var: post_code}, {name: street, var: street}, {name: telephone, var: telephone}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, city: $city, company_name: $company_name, country_code: $country_code, firstname: $firstname, lastname: $lastname, post_code: $post_code, street: $street, telephone: $telephone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get collections of organization
#
# GET /api/v1/organizations/{organizationId}/collections
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, label: string, ownerOrganizationId: string, physicalState: string, type: string>, limit: int, offset: int, total: int>
# operationId: getAllCollectionsOfOrganization
export def "get-all-collections-of-organization" [
  organization_id: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
  --type: string@type-completer # Filter by this type
  --label: string # Filter by this label
  --label-prefix: string # Filter by this label prefix
  --property: list<string> # List of i4dn property filter. e.g. "com.myorga.state:IN:waiting|processing" or "com.myorga.orderId:EQ:SAP001"
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/organizations/{organizationId}/collections"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: type, var: type}, {name: label, var: label}, {name: labelPrefix, var: label_prefix}, {name: property, var: property, style: multi}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit, type: $type, label: $label, label_prefix: $label_prefix, property: $property
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete organization logo
#
# DELETE /api/v1/organizations/{organizationId}/logo
# operationId: deleteOrganizationLogo
export def "delete-organization-logo" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/logo"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization logo
#
# POST /api/v1/organizations/{organizationId}/logo
# Returns: record<uri: string>
# operationId: setOrganizationLogo
export def "set-organization-logo" [
  organization_id: string
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
  file: string # An image containing the new logo. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/organizations/{organizationId}/logo"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    organization_id: $organization_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/organizations/{organizationId}/messaging
#
# Returns: record<active: bool, id: string, waitingMessages: int>
# operationId: getDefaultQueue
export def "get-default-queue" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/messaging"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PATCH /api/v1/organizations/{organizationId}/messaging
#
# operationId: patchDefaultQueue
export def "patch-default-queue" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # If this value is set to false the queue will be deleted. (e.g. true)
  --id: string # e.g. <default>
  --purge-queue: oneof<nothing, bool> # Set this value to true if you want to purge the queue. (e.g. false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/organizations/{organizationId}/messaging"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: id, var: id}, {name: purgeQueue, var: purge_queue}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    organization_id: $organization_id, active: $active, id: $id, purge_queue: $purge_queue
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enqueue a custom message
#
# POST /api/v1/organizations/{organizationId}/messaging/enqueueCustomMessage
# operationId: enqueueCustomMessage
export def "enqueue-custom-message" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Custom data in a map. You may use JSON content (e.g. x = y)
  name: string # The name of the message (organisation specific) (e.g. <event name>)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/organizations/{organizationId}/messaging/enqueueCustomMessage"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    organization_id: $organization_id, data: $data, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove partner
#
# DELETE /api/v1/organizations/{organizationId}/partner
# operationId: removePartnerOrganization
export def "remove-partner-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-organization-id: string # The namespace of the partner organization to remove (e.g. org.acme) (spec name: organizationId)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/organizations/{organizationId}/partner"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: organizationId, var: body_organization_id, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, body_organization_id: $body_organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get partners of an organization
#
# GET /api/v1/organizations/{organizationId}/partner
# Returns: record<elements: table<logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int>
# operationId: getPartnerOrganizations
export def "get-partner-organizations" [
  organization_id: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/organizations/{organizationId}/partner"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add partner
#
# PUT /api/v1/organizations/{organizationId}/partner
# operationId: addPartnerOrganization
export def "add-partner-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-organization-id: string # The namespace of the partner organization to add (e.g. org.acme) (spec name: organizationId)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/organizations/{organizationId}/partner"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: organizationId, var: body_organization_id, required: true}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, body_organization_id: $body_organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List my privileges
#
# GET /api/v1/organizations/{organizationId}/privileges
# Returns: list<string>
# operationId: getOrganizationPrivileges
export def "get-organization-privileges" [
  organization_id: string
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
    path: "/api/v1/organizations/{organizationId}/privileges"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List users and their roles
#
# GET /api/v1/organizations/{organizationId}/roles
# Returns: record<elements: table<roles: list, user: record>, limit: int, offset: int, total: int>
# operationId: getAllOrganizationRoles
export def "get-all-organization-roles" [
  organization_id: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/organizations/{organizationId}/roles"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Find users in organization
#
# GET /api/v1/organizations/{organizationId}/users
# Returns: record<elements: table<id: string, name: string>, limit: int, offset: int, total: int>
# operationId: getUsersOfOrganization
export def "get-users-of-organization" [
  organization_id: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/organizations/{organizationId}/users"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite Users
#
# POST /api/v1/organizations/{organizationId}/users/invite
# operationId: inviteUsers
export def "invite-users" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  invitations: list # item shape: {email?: string, roles: list<string>, userName?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/organizations/{organizationId}/users/invite"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: invitations, var: invitations}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    organization_id: $organization_id, invitations: $invitations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove role(s) from user
#
# DELETE /api/v1/organizations/{organizationId}/users/{username}/roles
# operationId: removeUserRoles
export def "remove-user-roles" [
  organization_id: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --roles: list<string>
]: any -> any {
  $in | http-request {
    method: delete
    path: "/api/v1/organizations/{organizationId}/users/{username}/roles"
    path_params: [{name: organizationId, var: organization_id}, {name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, username: $username, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user roles by username
#
# GET /api/v1/organizations/{organizationId}/users/{username}/roles
# Returns: record<elements: list<string>, limit: int, offset: int, total: int>
# operationId: getUserRoles
export def "get-user-roles" [
  organization_id: string
  username: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/organizations/{organizationId}/users/{username}/roles"
    path_params: [{name: organizationId, var: organization_id}, {name: username, var: username}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id, username: $username, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add role(s) to user
#
# POST /api/v1/organizations/{organizationId}/users/{username}/roles
# operationId: addUserRoles
export def "add-user-roles" [
  organization_id: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --roles: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/organizations/{organizationId}/users/{username}/roles"
    path_params: [{name: organizationId, var: organization_id}, {name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: roles, var: roles}]}
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    organization_id: $organization_id, username: $username, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List public documents
#
# GET /api/v1/public/documents/{id4n}
# Returns: record<elements: table<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: listAllPublicDocuments
export def "list-all-public-documents" [
  id4n: string
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
  --organization-id: string # organizationId
  --owner: string # Filter by owner organization
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/public/documents/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}, {name: owner, var: owner}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, owner: $owner, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Read public document contents
#
# GET /api/v1/public/documents/{id4n}/{organizationId}/{fileName}
# Returns: string
# operationId: readPublicDocument
export def "read-public-document" [
  id4n: string
  organization_id: string
  file_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/public/documents/{id4n}/{organizationId}/{fileName}"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve a public document (meta-data only, no content)
#
# GET /api/v1/public/documents/{id4n}/{organizationId}/{fileName}/metadata
# Returns: record<filename: string, mimeType: string, ownerOrganizationId: string, visibility: record<public: bool, sharedOrganizationIds: list<string>>>
# operationId: getPublicDocument
export def "get-public-document" [
  id4n: string
  organization_id: string
  file_name: string
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
    path: "/api/v1/public/documents/{id4n}/{organizationId}/{fileName}/metadata"
    path_params: [{name: id4n, var: id4n}, {name: organizationId, var: organization_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Shows the public history of the given GUID
#
# GET /api/v1/public/history/{id4n}
# Returns: record<elements: table<additionalProperties: record, organizationId: string, ownerOrganizationId: string, sequenceId: int, timestamp: int, type: string, visibility: record>, limit: int, offset: int, total: int>
# operationId: listPublicHistory
export def "list-public-history" [
  id4n: string
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
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/public/history/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resolve image
#
# GET /api/v1/public/image/{imageID}
# Returns: string
# operationId: resolveImageUsingGET
export def "resolve-image-using-get" [
  image_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/public/image/{imageID}"
    path_params: [{name: imageID, var: image_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Read public organization information
#
# GET /api/v1/public/organizations/{organizationId}
# Returns: record<id: int, logoURL: string, name: string, namespace: string>
# operationId: readOrganizationInfo
export def "read-organization-info" [
  organization_id: string
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
    path: "/api/v1/public/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve all public routes for a GUID
#
# GET /api/v1/public/routes/{id4n}
# Returns: table<params: record, priority: int, public: bool, type: string, validUntil: int>
# operationId: getRoutes
export def "get-routes" [
  id4n: string
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
  --type: string # type (required, default: web)
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/public/routes/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: type, var: type, required: true, default: web}, {name: interpolate, var: interpolate}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, type: $type, interpolate: $interpolate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List roles
#
# GET /api/v1/roles
# Returns: record<elements: table<name: string, privileges: list>, limit: int, offset: int, total: int>
# operationId: listAllRoles
export def "list-all-roles" [
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
  --privilege: string # If specified the roles will be filtered containing that privilege.
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/roles"
    query: [{name: privilege, var: privilege}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    privilege: $privilege, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve routing file
#
# GET /api/v1/routingfiles/{id4n}
# Returns: record<options: record<deleteOutdatedRoutes: bool>, routes: table<params: record, priority: int, public: bool, type: string, validUntil: int>>
# operationId: getRoutingFile
export def "get-routing-file" [
  id4n: string
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
  --organization-id: string # organizationId
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/routingfiles/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    query: [{name: organizationId, var: organization_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Store routing file
#
# PUT /api/v1/routingfiles/{id4n}
# operationId: updateRoutingFile
export def "update-routing-file" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-id: string
  routing: record # shape: {options?: record, routes: list}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/routingfiles/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: organizationId, var: organization_id}, {name: routing, var: routing}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id, routing: $routing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve current route of a GUID (or ID4N)
#
# GET /api/v1/routingfiles/{id4n}/route/{type}
# Returns: record<params: record, priority: int, public: bool, type: string, validUntil: int>
# operationId: getRoute
export def "get-route" [
  id4n: string
  type: string
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
  --private-routes: oneof<nothing, bool> # privateRoutes (default: true)
  --public-routes: oneof<nothing, bool> # publicRoutes (default: true)
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/routingfiles/{id4n}/route/{type}"
    path_params: [{name: id4n, var: id4n}, {name: type, var: type}]
    query: [{name: privateRoutes, var: private_routes}, {name: publicRoutes, var: public_routes}, {name: interpolate, var: interpolate}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, type: $type, private_routes: $private_routes, public_routes: $public_routes, interpolate: $interpolate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve all routes of a GUID (or ID4N)
#
# GET /api/v1/routingfiles/{id4n}/routes/{type}
# Returns: table<params: record, priority: int, public: bool, type: string, validUntil: int>
# operationId: getAllRoutes
export def "get-all-routes" [
  id4n: string
  type: string
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
  --organization-id: string # organizationId
  --interpolate: oneof<nothing, bool> # interpolate (default: true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/routingfiles/{id4n}/routes/{type}"
    path_params: [{name: id4n, var: id4n}, {name: type, var: type}]
    query: [{name: organizationId, var: organization_id}, {name: interpolate, var: interpolate}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, type: $type, organization_id: $organization_id, interpolate: $interpolate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for GUIDs by alias
#
# GET /api/v1/search/guids
# Returns: record<elements: table<createdTimestamp: int, holderOrganizationId: string, id4n: string, ownerOrganizationId: string, physicalState: string, properties: record>, limit: int, offset: int, total: int>
# operationId: searchByAlias
export def "search-by-alias" [
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
  --alias: string # The alias to search for (required)
  --alias-type: string@alias-type-completer # Alias type type to search for (required)
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/search/guids"
    query: [{name: alias, var: alias, required: true}, {name: aliasType, var: alias_type, required: true}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    alias: $alias, alias_type: $alias_type, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all supported alias types
#
# GET /api/v1/search/guids/aliases/types
# Returns: list<string>
# operationId: getGuidAliasTypes
export def "get-guid-alias-types" [
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
    path: "/api/v1/search/guids/aliases/types"
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Transfer a GUID or collection, obtaining it (i.e. becoming the holder) and if allowed also taking ownership
#
# PUT /api/v1/transfers/{id4n}/receiveInfo
# operationId: receive
export def "receive" [
  id4n: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_id: string # Organization to take the ownership of the ID. If the sender chose to keep the ownership, this organization becomes the holder. Otherwise, it becomes the new owner. (e.g. de.id4i)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/transfers/{id4n}/receiveInfo"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: organizationId, var: organization_id}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show transfer preparation information
#
# GET /api/v1/transfers/{id4n}/sendInfo
# Returns: record<holderOrganizationId: string, keepOwnership: bool, openForClaims: bool, ownerOrganizationId: string, recipientOrganizationIds: list<string>>
# operationId: getSendInfo
export def "get-send-info" [
  id4n: string
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
    path: "/api/v1/transfers/{id4n}/sendInfo"
    path_params: [{name: id4n, var: id4n}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Prepare an object for transfer
#
# PUT /api/v1/transfers/{id4n}/sendInfo
# Returns: record
# operationId: prepare
export def "prepare" [
  id4n: string
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
  --keep-ownership: oneof<nothing, bool> # Keep the public ownership while transferring the object (e.g. true)
  --open-for-claims: oneof<nothing, bool> # Allow anyone who knows (or can scan) the ID4N to claim ownership of this object (e.g. false)
  recipient_organization_ids: list<string> # Allow only these organizations to obtain this object (e.g. [de.acme, com.porsche, de.bluerain])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/transfers/{id4n}/sendInfo"
    path_params: [{name: id4n, var: id4n}]
    body: {content_type: "application/json", kind: json, fields: [{name: keepOwnership, var: keep_ownership, required: true}, {name: openForClaims, var: open_for_claims, required: true}, {name: recipientOrganizationIds, var: recipient_organization_ids}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n, keep_ownership: $keep_ownership, open_for_claims: $open_for_claims, recipient_organization_ids: $recipient_organization_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve organizations of user
#
# GET /api/v1/user/organizations
# Returns: record<elements: table<id: int, logoURL: string, name: string, namespace: string>, limit: int, offset: int, total: int>
# operationId: getOrganizationsOfUser
export def "get-organizations-of-user" [
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
  --role: string # role
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/user/organizations"
    query: [{name: role, var: role}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    role: $role, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Find users
#
# GET /api/v1/users
# Returns: record<elements: table<id: string, name: string>, limit: int, offset: int, total: int>
# operationId: findUsers
export def "find-users" [
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
  --username-prefix: string
  --offset: int # Start with the n-th element (format: int32)
  --limit: int # The maximum count of returned elements (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users"
    query: [{name: usernamePrefix, var: username_prefix}, {name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    username_prefix: $username_prefix, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Find by username
#
# GET /api/v1/users/{username}
# Returns: record<id: string, name: string>
# operationId: findUserByUsername
export def "find-user-by-username" [
  username: string
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
    path: "/api/v1/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Forward
#
# GET /go/{guid}
# operationId: go
export def "go" [
  guid: string
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
    path: "/go/{guid}"
    path_params: [{name: guid, var: guid}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    guid: $guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ID4i API Login
#
# POST /login
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
  --login: string
  --password: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/login"
    body: {content_type: "application/json", kind: json, fields: [{name: login, var: login}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolve owner of id4n
#
# GET /whois/{id4n}
# Returns: record<aliases: record, organization: record<id: int, logoURL: string, name: string, namespace: string>, organizationAddress: record<city: string, companyName: string, countryCode: string, countryName: string, firstname: string, lastname: string, postCode: string, street: string, telephone: string>>
# operationId: resolveWhoIsEntry
export def "resolve-who-is-entry" [
  id4n: string
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
    path: "/whois/{id4n}"
    path_params: [{name: id4n, var: id4n}]
    accept: ["application/json", "application/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    id4n: $id4n
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
