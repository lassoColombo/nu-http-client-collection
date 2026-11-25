# Auto-generated client for PeerTube v5.1.0
# Source: https://api.apis.guru/v2/specs/cpy.re/peertube/5.1.0/openapi.json
# Auth: --token flag or $env.PEERTUBE_TOKEN

const CLIENT = {
  base_url: "https://peertube2.cpy.re"
  token_env_var: "PEERTUBE_TOKEN"
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

def base-url-completer [] { ["https://peertube2.cpy.re" "https://peertube3.cpy.re" "https://peertube.cpy.re"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["1" "2" "3"] }
def video-is-completer [] { ["blacklisted" "deleted"] }
def filter-completer [] { ["account" "comment" "video"] }
def sort-completer [] { ["-createdAt" "-id" "-state"] }
def sort-completer-1 [] { ["createdAt"] }
def rating-completer [] { ["dislike" "like"] }
def playlist-type-completer [] { ["1" "2"] }
def nsfw-completer [] { ["false" "true"] }
def include-completer [] { ["0" "1" "2" "4" "8"] }
def privacy-one-of-completer [] { ["1" "2" "3" "4"] }
def skip-count-completer [] { ["false" "true"] }
def sort-completer-2 [] { ["-best" "-createdAt" "-duration" "-hot" "-likes" "-publishedAt" "-trending" "-views" "name"] }
def state-completer-1 [] { ["" "active" "completed" "delayed" "failed" "waiting"] }
def job-type-completer [] { ["activitypub-follow" "activitypub-http-broadcast" "activitypub-http-fetcher" "activitypub-http-unicast" "activitypub-refresher" "email" "video-channel-import" "video-file-import" "video-import" "video-live-ending" "video-redundancy" "video-transcoding" "videos-views-stats"] }
def player-mode-completer [] { ["p2p-media-loader" "webtorrent"] }
def search-target-completer [] { ["local" "search-index"] }
def sort-completer-3 [] { ["-createdAt" "-duration" "-likes" "-match" "-publishedAt" "-views" "name"] }
def state-completer-2 [] { ["accepted" "pending"] }
def actor-type-completer [] { ["Application" "Group" "Organization" "Person" "Service"] }
def level-completer [] { ["error" "warn"] }
def target-completer [] { ["my-videos" "remote-videos"] }
def sort-completer-4 [] { ["name"] }
def sort-completer-5 [] { ["-createdAt" "-id" "-username"] }
def admin-flags-completer [] { ["0" "1"] }
def role-completer [] { ["0" "1" "2"] }
def display-nsfw-completer [] { ["both" "false" "true"] }
def sort-completer-6 [] { ["-createdAt" "-state" "createdAt" "state"] }
def grant-type-completer [] { ["password" "refresh_token"] }
def privacy-completer [] { ["1" "2" "3"] }
def type-completer [] { ["1" "2"] }
def sort-completer-7 [] { ["-createdAt" "-dislikes" "-duration" "-id" "-likes" "-uuid" "-views" "name"] }
def privacy-completer-1 [] { ["1" "2" "3" "4"] }
def latency-mode-completer [] { ["1" "2" "3"] }
def sort-completer-8 [] { ["-createdAt" "-totalReplies"] }
def metric-completer [] { ["aggregateWatchTime" "viewers"] }
def transcoding-type-completer [] { ["hls" "webtorrent"] }
def view-event-completer [] { ["seek"] }
def format-completer [] { ["atom" "atom1" "json" "json1" "rss" "rss2" "xml"] }
def accept-completer [] { ["application/atom+xml" "application/json" "application/rss+xml" "application/xml" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-abuses: "record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int>"
    post-api-v1-abuses: "record<abuse: record<id: int>>"
    get-api-v1-abuses-abuse-id-messages: "record<data: table<account: record, byModerator: bool, createdAt: string, id: int, message: string>, total: int>"
    get-accounts: "table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>"
    get-account: "record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>"
    get-account-followers: "record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>"
    get-api-v1-accounts-name-ratings: "table<rating: string, video: record<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>>"
    get-api-v1-accounts-name-video-channel-syncs: "record<data: table<channel: record, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record>, total: int>"
    get-api-v1-accounts-name-video-channels: "record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>"
    get-api-v1-accounts-name-video-playlists: "record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>"
    get-account-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-api-v1-blocklist-status: "record<accounts: record, hosts: record>"
    get-config: "record<autoBlacklist: record<videos: record<ofUsers: record>>, avatar: record<extensions: list<string>, file: record<size: record>>, contactForm: record<enabled: bool>, email: record<enabled: bool>, followings: record<instance: record<autoFollowIndex: record>>, homepage: record<enabled: bool>, import: record<videoChannelSynchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, isNSFW: bool, name: string, shortDescription: string>, plugin: record<registered: list<string>>, search: record<remoteUri: record<anonymous: bool, users: bool>>, serverCommit: string, serverVersion: string, signup: record<allowed: bool, allowedForCurrentIP: bool, requiresEmailVerification: bool>, theme: record<registered: list<string>>, tracker: record<enabled: bool>, transcoding: record<enabledResolutions: list<int>, hls: record<enabled: bool>, webtorrent: record<enabled: bool>>, trending: record<videos: record<intervalDays: int>>, user: record<videoQuota: int, videoQuotaDaily: int>, video: record<file: record<extensions: list>, image: record<extensions: list, size: record>>, videoCaption: record<file: record<extensions: list, size: record>>>"
    get-about: "record<instance: record<description: string, name: string, shortDescription: string, terms: string>>"
    get-custom-config: "record<admin: record<email: string>, autoBlacklist: record<videos: record<ofUsers: record>>, cache: record<captions: record<size: int>, previews: record<size: int>>, contactForm: record<enabled: bool>, followers: record<instance: record<enabled: bool, manualApproval: bool>>, import: record<video_channel_synchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, description: string, isNSFW: bool, name: string, shortDescription: string, terms: string>, services: record<twitter: record<username: string, whitelisted: bool>>, signup: record<enabled: bool, limit: int, requiresEmailVerification: bool>, theme: record<default: string>, transcoding: record<allowAdditionalExtensions: bool, allowAudioFiles: bool, concurrency: float, enabled: bool, hls: record<enabled: bool>, profile: string, resolutions: record<\"0p\": bool, \"1080p\": bool, \"1440p\": bool, \"144p\": bool, \"2160p\": bool, \"240p\": bool, \"360p\": bool, \"480p\": bool, \"720p\": bool>, threads: int, webtorrent: record<enabled: bool>>, user: record<videoQuota: int, videoQuotaDaily: int>>"
    get-api-v1-custom-pages-homepage-instance: "record<content: string>"
    get-jobs: "record<data: table<createdAt: string, data: record, error: record, finishedOn: string, id: int, processedOn: string, state: string, type: string>, total: int>"
    get-o-auth-client: "record<client_id: string, client_secret: string>"
    get-plugins: "record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int>"
    get-available-plugins: "record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int>"
    get-plugin: "record<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>"
    get-api-v1-plugins-npm-name-public-settings: "record"
    get-api-v1-plugins-npm-name-registered-settings: "record"
    search-channels: "record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>"
    search-playlists: "record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>"
    search-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-instance-audit-logs: "list<string>"
    get-api-v1-server-followers: "record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>"
    get-api-v1-server-following: "record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>"
    get-instance-logs: "list<string>"
    get-mirrored-videos: "table<id: int, name: string, redundancies: record<files: list, streamingPlaylists: list>, url: string, uuid: string>"
    get-instance-stats: "record<activityPubMessagesProcessedPerSecond: float, totalActivityPubMessagesErrors: float, totalActivityPubMessagesProcessed: float, totalActivityPubMessagesSuccesses: float, totalActivityPubMessagesWaiting: float, totalDailyActiveUsers: float, totalInstanceFollowers: float, totalInstanceFollowing: float, totalLocalDailyActiveVideoChannels: float, totalLocalMonthlyActiveVideoChannels: float, totalLocalPlaylists: float, totalLocalVideoChannels: float, totalLocalVideoComments: float, totalLocalVideoFilesSize: float, totalLocalVideoViews: float, totalLocalVideos: float, totalLocalWeeklyActiveVideoChannels: float, totalMonthlyActiveUsers: float, totalUsers: float, totalVideoComments: float, totalVideos: float, totalWeeklyActiveUsers: float, videosRedundancy: table<strategy: string, totalSize: float, totalUsed: float, totalVideoFiles: float, totalVideos: float>>"
    get-users: "table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: int, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int>"
    add-user: "record<user: record<account: record<id: int>, id: int>>"
    get-user-info: "table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: int, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int>"
    get-my-abuses: "record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int>"
    post-api-v1-users-me-avatar-pick: "record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>>"
    get-api-v1-users-me-history-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-api-v1-users-me-notifications: "record<data: table<account: record, actorFollow: record, comment: record, createdAt: string, id: int, read: bool, type: int, updatedAt: string, video: record, videoAbuse: record, videoBlacklist: record, videoImport: record>, total: int>"
    get-api-v1-users-me-subscriptions: "record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>"
    get-api-v1-users-me-subscriptions-exist: "record"
    get-api-v1-users-me-subscriptions-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-api-v1-users-me-subscriptions-subscription-handle: "record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>"
    get-api-v1-users-me-video-playlists-videos-exist: "record<videoId: table<playlistElementId: int, playlistId: int, startTimestamp: int, stopTimestamp: int>>"
    get-api-v1-users-me-video-quota-used: "record<videoQuotaUsed: float, videoQuotaUsedDaily: float>"
    get-api-v1-users-me-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-api-v1-users-me-videos-imports: "record<data: table<createdAt: string, error: string, id: int, magnetUri: string, state: record, targetUrl: string, torrentName: string, torrentfile: string, updatedAt: string, video: record>, total: int>"
    get-api-v1-users-me-videos-video-id-rating: "record<id: int, rating: string>"
    list-registrations: "record<data: table<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record, updatedAt: string, user: record, username: string>, total: int>"
    request-registration: "record<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record<id: int, label: string>, updatedAt: string, user: record<id: int>, username: string>"
    get-o-auth-token: "record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, token_type: string>"
    request-two-factor: "table<otpRequest: record<requestToken: string, secret: string, uri: string>>"
    add-video-channel-sync: "record<videoChannelSync: record<channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record<id: int, label: string>>>"
    get-video-channels: "record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>"
    add-video-channel: "record<videoChannel: record<id: int>>"
    get-video-channel: "record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>"
    post-api-v1-video-channels-channel-handle-avatar-pick: "record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>>"
    post-api-v1-video-channels-channel-handle-banner-pick: "record<banners: table<createdAt: string, path: string, updatedAt: string, width: int>>"
    get-video-channel-followers: "record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>"
    get-api-v1-video-channels-channel-handle-video-playlists: "record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>"
    get-video-channel-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-playlists: "record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>"
    add-playlist: "record<videoPlaylist: record<id: int, shortUUID: string, uuid: string>>"
    get-playlist-privacy-policies: "list<string>"
    get-api-v1-video-playlists-playlist-id: "record<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, privacy: record<id: int, label: string>, shortUUID: string, thumbnailPath: string, type: record<id: int, label: string>, updatedAt: string, uuid: string, videoChannel: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, videoLength: int>"
    get-video-playlist-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    add-video-playlist-video: "record<videoPlaylistElement: record<id: int>>"
    get-videos: "record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>"
    get-video-blocks: "record<data: table<createdAt: string, description: string, dislikes: int, duration: int, id: int, likes: int, name: string, nsfw: bool, updatedAt: string, uuid: string, videoId: int, views: int>, total: int>"
    get-categories: "list<string>"
    import-video: "record<video: record<id: int, shortUUID: string, uuid: string>>"
    get-languages: "list<string>"
    get-licences: "list<string>"
    add-live: "record<video: record<id: int, shortUUID: string, uuid: string>>"
    get-live-id: "record<latencyMode: int, permanentLive: bool, rtmpUrl: string, rtmpsUrl: string, saveReplay: bool, streamKey: string>"
    get-api-v1-videos-live-id-sessions: "record<data: table<endDate: string, error: int, id: int, replayVideo: record, startDate: string>, total: int>"
    get-privacy-policies: "list<string>"
    upload-legacy: "record<video: record<id: int, shortUUID: string, uuid: string>>"
    upload-resumable: "record<video: record<id: int, shortUUID: string, uuid: string>>"
    get-video: "record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, blacklisted: bool, blacklistedReason: string, category: record<id: int, label: string>, channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list<record>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record<id: string, label: string>, licence: record<id: int, label: string>, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record<id: int, label: string>, publishedAt: string, scheduledUpdate: record<privacy: int, updateAt: string>, shortUUID: string, state: record<id: int, label: string>, thumbnailPath: string, updatedAt: string, userHistory: record<currentTime: int>, uuid: string, views: int, waitTranscoding: bool, commentsEnabled: bool, descriptionPath: string, downloadEnabled: bool, files: table<fileDownloadUrl: string, fileUrl: string, fps: float, id: int, magnetUri: string, metadataUrl: string, resolution: record, size: int, torrentDownloadUrl: string, torrentUrl: string>, streamingPlaylists: table<id: int, type: int, files: list, playlistUrl: string, redundancies: list, segmentsSha256Url: string>, support: string, tags: list<string>, trackerUrls: list<string>, viewers: int>"
    get-video-captions: "record<data: table<captionPath: string, language: record>, total: int>"
    get-api-v1-videos-id-comment-threads: "record<data: table<account: record, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>, total: int>"
    post-api-v1-videos-id-comment-threads: "record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>"
    get-api-v1-videos-id-comment-threads-thread-id: "record<children: list<any>, comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>"
    post-api-v1-videos-id-comments-comment-id: "record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>"
    get-video-desc: "string"
    get-api-v1-videos-id-live-session: "record<endDate: string, error: int, id: int, replayVideo: record<id: float, shortUUID: string, uuid: string>, startDate: string>"
    get-video-source: "record<filename: string>"
    get-api-v1-videos-id-stats-overall: "record<averageWatchTime: float, countries: table<isoCode: string, viewers: float>, totalWatchTime: float, viewersPeak: float, viewersPeakDate: string>"
    get-api-v1-videos-id-stats-retention: "record<data: table<retentionPercent: float, second: float>>"
    get-api-v1-videos-id-stats-timeseries-metric: "record<data: table<date: string, value: float>>"
    request-video-token: "record<files: record<expires: string, token: string>>"
    get-syndicated-subscription-videos: "record"
    get-syndicated-comments: "record"
    get-syndicated-videos: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-abuses" "post-api-v1-abuses" "delete-api-v1-abuses-abuse-id" "put-api-v1-abuses-abuse-id" "get-api-v1-abuses-abuse-id-messages" "post-api-v1-abuses-abuse-id-messages" "delete-api-v1-abuses-abuse-id-messages-abuse-message-id" "get-accounts" "get-account" "get-account-followers" "get-api-v1-accounts-name-ratings" "get-api-v1-accounts-name-video-channel-syncs" "get-api-v1-accounts-name-video-channels" "get-api-v1-accounts-name-video-playlists" "get-account-videos" "get-api-v1-blocklist-status" "get-config" "get-about" "del-custom-config" "get-custom-config" "put-custom-config" "get-api-v1-custom-pages-homepage-instance" "put-api-v1-custom-pages-homepage-instance" "post-api-v1-jobs-pause" "post-api-v1-jobs-resume" "get-jobs" "post-api-v1-metrics-playback" "get-o-auth-client" "get-plugins" "get-available-plugins" "add-plugin" "uninstall-plugin" "update-plugin" "get-plugin" "get-api-v1-plugins-npm-name-public-settings" "get-api-v1-plugins-npm-name-registered-settings" "put-api-v1-plugins-npm-name-settings" "search-channels" "search-playlists" "search-videos" "get-instance-audit-logs" "get-api-v1-server-blocklist-accounts" "post-api-v1-server-blocklist-accounts" "delete-api-v1-server-blocklist-accounts-account-name" "get-api-v1-server-blocklist-servers" "post-api-v1-server-blocklist-servers" "delete-api-v1-server-blocklist-servers-host" "get-api-v1-server-followers" "delete-api-v1-server-followers-name-with-host" "post-api-v1-server-followers-name-with-host-accept" "post-api-v1-server-followers-name-with-host-reject" "get-api-v1-server-following" "post-api-v1-server-following" "delete-api-v1-server-following-host-or-handle" "get-instance-logs" "send-client-log" "get-mirrored-videos" "put-mirrored-video" "del-mirrored-video" "put-api-v1-server-redundancy-host" "get-instance-stats" "get-users" "add-user" "resend-email-to-verify-user" "get-user-info" "put-user-info" "get-my-abuses" "delete-api-v1-users-me-avatar" "post-api-v1-users-me-avatar-pick" "get-api-v1-users-me-history-videos" "post-api-v1-users-me-history-videos-remove" "delete-api-v1-users-me-history-videos-video-id" "put-api-v1-users-me-notification-settings" "get-api-v1-users-me-notifications" "post-api-v1-users-me-notifications-read" "post-api-v1-users-me-notifications-read-all" "get-api-v1-users-me-subscriptions" "post-api-v1-users-me-subscriptions" "get-api-v1-users-me-subscriptions-exist" "get-api-v1-users-me-subscriptions-videos" "delete-api-v1-users-me-subscriptions-subscription-handle" "get-api-v1-users-me-subscriptions-subscription-handle" "get-api-v1-users-me-video-playlists-videos-exist" "get-api-v1-users-me-video-quota-used" "get-api-v1-users-me-videos" "get-api-v1-users-me-videos-imports" "get-api-v1-users-me-videos-video-id-rating" "register-user" "list-registrations" "resend-email-to-verify-registration" "request-registration" "delete-registration" "accept-registration" "reject-registration" "verify-registration-email" "revoke-o-auth-token" "get-o-auth-token" "del-user" "get-user" "put-user" "confirm-two-factor-request" "disable-two-factor" "request-two-factor" "verify-user" "add-video-channel-sync" "del-video-channel-sync" "trigger-video-channel-sync" "get-video-channels" "add-video-channel" "del-video-channel" "get-video-channel" "put-video-channel" "delete-api-v1-video-channels-channel-handle-avatar" "post-api-v1-video-channels-channel-handle-avatar-pick" "delete-api-v1-video-channels-channel-handle-banner" "post-api-v1-video-channels-channel-handle-banner-pick" "get-video-channel-followers" "post-api-v1-video-channels-channel-handle-import-videos" "get-api-v1-video-channels-channel-handle-video-playlists" "get-video-channel-videos" "get-playlists" "add-playlist" "get-playlist-privacy-policies" "delete-api-v1-video-playlists-playlist-id" "get-api-v1-video-playlists-playlist-id" "put-api-v1-video-playlists-playlist-id" "get-video-playlist-videos" "add-video-playlist-video" "reorder-video-playlist" "del-video-playlist-video" "put-video-playlist-video" "get-videos" "get-video-blocks" "get-categories" "import-video" "delete-api-v1-videos-imports-id" "post-api-v1-videos-imports-id-cancel" "get-languages" "get-licences" "add-live" "get-live-id" "update-live-id" "get-api-v1-videos-live-id-sessions" "get-api-v1-videos-ownership" "post-api-v1-videos-ownership-id-accept" "post-api-v1-videos-ownership-id-refuse" "get-privacy-policies" "upload-legacy" "upload-resumable-cancel" "upload-resumable-init" "upload-resumable" "del-video" "get-video" "put-video" "del-video-block" "add-video-block" "get-video-captions" "del-video-caption" "add-video-caption" "get-api-v1-videos-id-comment-threads" "post-api-v1-videos-id-comment-threads" "get-api-v1-videos-id-comment-threads-thread-id" "delete-api-v1-videos-id-comments-comment-id" "post-api-v1-videos-id-comments-comment-id" "get-video-desc" "post-api-v1-videos-id-give-ownership" "del-video-hls" "get-api-v1-videos-id-live-session" "put-api-v1-videos-id-rate" "get-video-source" "get-api-v1-videos-id-stats-overall" "get-api-v1-videos-id-stats-retention" "get-api-v1-videos-id-stats-timeseries-metric" "post-api-v1-videos-id-studio-edit" "request-video-token" "create-video-transcoding" "add-view" "put-api-v1-videos-id-watching" "del-video-web-torrent" "get-syndicated-subscription-videos" "get-syndicated-comments" "get-syndicated-videos" "get-static-streaming-playlists-hls-private-filename" "get-static-streaming-playlists-hls-filename" "get-static-webseed-private-filename" "get-static-webseed-filename" "commands"] | sort) } | get name | first)
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

# List abuses
#
# GET /api/v1/abuses
# Returns: record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int>
# operationId: getAbuses
export def "get-abuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --predefined-reason: list<string> # predefined reason the listed reports should contain
  --search: string # plain search that will match with video titles, reporter names and more
  --state: int@state-completer
  --search-reporter: string # only list reports of a specific reporter
  --search-reportee: string # only list reports of a specific reportee
  --search-video: string # only list reports of a specific video
  --search-video-channel: string # only list reports of a specific video channel
  --video-is: string@video-is-completer # only list deleted or blocklisted videos
  --filter: string@filter-completer # only list account, comment or video reports
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer # Sort abuses by criteria
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/abuses"
    query: [{name: id, var: id}, {name: predefinedReason, var: predefined_reason, style: multi}, {name: search, var: search}, {name: state, var: state}, {name: searchReporter, var: search_reporter}, {name: searchReportee, var: search_reportee}, {name: searchVideo, var: search_video}, {name: searchVideoChannel, var: search_video_channel}, {name: videoIs, var: video_is}, {name: filter, var: filter}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, predefined_reason: $predefined_reason, search: $search, state: $state, search_reporter: $search_reporter, search_reportee: $search_reportee, search_video: $search_video, search_video_channel: $search_video_channel, video_is: $video_is, filter: $filter, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report an abuse
#
# POST /api/v1/abuses
# Returns: record<abuse: record<id: int>>
export def "post-api-v1-abuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: record # shape: {id?: int}
  --comment: record # shape: {id?: int}
  --predefined-reasons: list<string> # Reason categories that help triage reports
  reason: string # Reason why the user reports this video
  --video: record # shape: {endAt?: int, id?: int, startAt?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/abuses"
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}, {name: comment, var: comment}, {name: predefinedReasons, var: predefined_reasons}, {name: reason, var: reason}, {name: video, var: video}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, comment: $comment, predefined_reasons: $predefined_reasons, reason: $reason, video: $video
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an abuse
#
# DELETE /api/v1/abuses/{abuseId}
export def "delete-api-v1-abuses-abuse-id" [
  abuse_id: int
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
    path: "/api/v1/abuses/{abuseId}"
    path_params: [{name: abuseId, var: abuse_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    abuse_id: $abuse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an abuse
#
# PUT /api/v1/abuses/{abuseId}
export def "put-api-v1-abuses-abuse-id" [
  abuse_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderation-comment: string # Update the report comment visible only to the moderation team
  --state: int@state-completer # The abuse state (Pending = `1`, Rejected = `2`, Accepted = `3`)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/abuses/{abuseId}"
    path_params: [{name: abuseId, var: abuse_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: moderationComment, var: moderation_comment}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    abuse_id: $abuse_id, moderation_comment: $moderation_comment, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messages of an abuse
#
# GET /api/v1/abuses/{abuseId}/messages
# Returns: record<data: table<account: record, byModerator: bool, createdAt: string, id: int, message: string>, total: int>
export def "get-api-v1-abuses-abuse-id-messages" [
  abuse_id: int
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
    path: "/api/v1/abuses/{abuseId}/messages"
    path_params: [{name: abuseId, var: abuse_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    abuse_id: $abuse_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add message to an abuse
#
# POST /api/v1/abuses/{abuseId}/messages
export def "post-api-v1-abuses-abuse-id-messages" [
  abuse_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # Message to send
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/abuses/{abuseId}/messages"
    path_params: [{name: abuseId, var: abuse_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    abuse_id: $abuse_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an abuse message
#
# DELETE /api/v1/abuses/{abuseId}/messages/{abuseMessageId}
export def "delete-api-v1-abuses-abuse-id-messages-abuse-message-id" [
  abuse_id: int
  abuse_message_id: int
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
    path: "/api/v1/abuses/{abuseId}/messages/{abuseMessageId}"
    path_params: [{name: abuseId, var: abuse_id}, {name: abuseMessageId, var: abuse_message_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    abuse_id: $abuse_id, abuse_message_id: $abuse_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts
#
# GET /api/v1/accounts
# Returns: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>
# operationId: getAccounts
export def "get-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an account
#
# GET /api/v1/accounts/{name}
# Returns: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>
# operationId: getAccount
export def "get-account" [
  name: string
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
    path: "/api/v1/accounts/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List followers of an account
#
# GET /api/v1/accounts/{name}/followers
# Returns: record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>
# operationId: getAccountFollowers
export def "get-account-followers" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/followers"
    path_params: [{name: name, var: name}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, start: $start, count: $count, sort: $sort, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ratings of an account
#
# GET /api/v1/accounts/{name}/ratings
# Returns: table<rating: string, video: record<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>>
export def "get-api-v1-accounts-name-ratings" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
  --rating: string@rating-completer # Optionally filter which ratings to retrieve
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/ratings"
    path_params: [{name: name, var: name}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: rating, var: rating}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, start: $start, count: $count, sort: $sort, rating: $rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the synchronizations of video channels of an account
#
# GET /api/v1/accounts/{name}/video-channel-syncs
# Returns: record<data: table<channel: record, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record>, total: int>
export def "get-api-v1-accounts-name-video-channel-syncs" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/video-channel-syncs"
    path_params: [{name: name, var: name}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video channels of an account
#
# GET /api/v1/accounts/{name}/video-channels
# Returns: record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>
export def "get-api-v1-accounts-name-video-channels" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-stats: oneof<nothing, bool> # include daily view statistics for the last 30 days and total views (only if authentified as the account user)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/video-channels"
    path_params: [{name: name, var: name}]
    query: [{name: withStats, var: with_stats}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, with_stats: $with_stats, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List playlists of an account
#
# GET /api/v1/accounts/{name}/video-playlists
# Returns: record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>
export def "get-api-v1-accounts-name-video-playlists" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --playlist-type: int@playlist-type-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/video-playlists"
    path_params: [{name: name, var: name}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: search, var: search}, {name: playlistType, var: playlist_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, start: $start, count: $count, sort: $sort, search: $search, playlist_type: $playlist_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos of an account
#
# GET /api/v1/accounts/{name}/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
# operationId: getAccountVideos
export def "get-account-videos" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/accounts/{name}/videos"
    path_params: [{name: name, var: name}]
    query: [{name: categoryOneOf, var: category_one_of}, {name: isLive, var: is_live}, {name: tagsOneOf, var: tags_one_of}, {name: tagsAllOf, var: tags_all_of}, {name: licenceOneOf, var: licence_one_of}, {name: languageOneOf, var: language_one_of}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}, {name: skipCount, var: skip_count}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, category_one_of: $category_one_of, is_live: $is_live, tags_one_of: $tags_one_of, tags_all_of: $tags_all_of, licence_one_of: $licence_one_of, language_one_of: $language_one_of, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files, skip_count: $skip_count, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get block status of accounts/hosts
#
# GET /api/v1/blocklist/status
# Returns: record<accounts: record, hosts: record>
export def "get-api-v1-blocklist-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounts: list<string> # Check if these accounts are blocked (e.g. [goofy@example.com, donald@example.com])
  --hosts: list<string> # Check if these hosts are blocked (e.g. [example.com])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/blocklist/status"
    query: [{name: accounts, var: accounts, style: multi}, {name: hosts, var: hosts, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accounts: $accounts, hosts: $hosts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance public configuration
#
# GET /api/v1/config
# Returns: record<autoBlacklist: record<videos: record<ofUsers: record>>, avatar: record<extensions: list<string>, file: record<size: record>>, contactForm: record<enabled: bool>, email: record<enabled: bool>, followings: record<instance: record<autoFollowIndex: record>>, homepage: record<enabled: bool>, import: record<videoChannelSynchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, isNSFW: bool, name: string, shortDescription: string>, plugin: record<registered: list<string>>, search: record<remoteUri: record<anonymous: bool, users: bool>>, serverCommit: string, serverVersion: string, signup: record<allowed: bool, allowedForCurrentIP: bool, requiresEmailVerification: bool>, theme: record<registered: list<string>>, tracker: record<enabled: bool>, transcoding: record<enabledResolutions: list<int>, hls: record<enabled: bool>, webtorrent: record<enabled: bool>>, trending: record<videos: record<intervalDays: int>>, user: record<videoQuota: int, videoQuotaDaily: int>, video: record<file: record<extensions: list>, image: record<extensions: list, size: record>>, videoCaption: record<file: record<extensions: list, size: record>>>
# operationId: getConfig
export def "get-config" [
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
    path: "/api/v1/config"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance "About" information
#
# GET /api/v1/config/about
# Returns: record<instance: record<description: string, name: string, shortDescription: string, terms: string>>
# operationId: getAbout
export def "get-about" [
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
    path: "/api/v1/config/about"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete instance runtime configuration
#
# DELETE /api/v1/config/custom
# operationId: delCustomConfig
export def "del-custom-config" [
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
    path: "/api/v1/config/custom"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance runtime configuration
#
# GET /api/v1/config/custom
# Returns: record<admin: record<email: string>, autoBlacklist: record<videos: record<ofUsers: record>>, cache: record<captions: record<size: int>, previews: record<size: int>>, contactForm: record<enabled: bool>, followers: record<instance: record<enabled: bool, manualApproval: bool>>, import: record<video_channel_synchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, description: string, isNSFW: bool, name: string, shortDescription: string, terms: string>, services: record<twitter: record<username: string, whitelisted: bool>>, signup: record<enabled: bool, limit: int, requiresEmailVerification: bool>, theme: record<default: string>, transcoding: record<allowAdditionalExtensions: bool, allowAudioFiles: bool, concurrency: float, enabled: bool, hls: record<enabled: bool>, profile: string, resolutions: record<"0p": bool, "1080p": bool, "1440p": bool, "144p": bool, "2160p": bool, "240p": bool, "360p": bool, "480p": bool, "720p": bool>, threads: int, webtorrent: record<enabled: bool>>, user: record<videoQuota: int, videoQuotaDaily: int>>
# operationId: getCustomConfig
export def "get-custom-config" [
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
    path: "/api/v1/config/custom"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set instance runtime configuration
#
# PUT /api/v1/config/custom
# operationId: putCustomConfig
export def "put-custom-config" [
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
    method: put
    path: "/api/v1/config/custom"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance custom homepage
#
# GET /api/v1/custom-pages/homepage/instance
# Returns: record<content: string>
export def "get-api-v1-custom-pages-homepage-instance" [
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
    path: "/api/v1/custom-pages/homepage/instance"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set instance custom homepage
#
# PUT /api/v1/custom-pages/homepage/instance
export def "put-api-v1-custom-pages-homepage-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # content of the homepage, that will be injected in the client
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/custom-pages/homepage/instance"
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause job queue
#
# POST /api/v1/jobs/pause
export def "post-api-v1-jobs-pause" [
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
    path: "/api/v1/jobs/pause"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resume job queue
#
# POST /api/v1/jobs/resume
export def "post-api-v1-jobs-resume" [
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
    path: "/api/v1/jobs/resume"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List instance jobs
#
# GET /api/v1/jobs/{state}
# Returns: record<data: table<createdAt: string, data: record, error: record, finishedOn: string, id: int, processedOn: string, state: string, type: string>, total: int>
# operationId: getJobs
export def "get-jobs" [
  state: string@state-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-type: string@job-type-completer # job type
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/jobs/{state}"
    path_params: [{name: state, var: state}]
    query: [{name: jobType, var: job_type}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, job_type: $job_type, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create playback metrics
#
# POST /api/v1/metrics/playback
export def "post-api-v1-metrics-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  downloaded_bytes_http: float # How many bytes were downloaded with HTTP since the last metric creation
  downloaded_bytes_p2p: float # How many bytes were downloaded with P2P since the last metric creation
  errors: float # How many errors occured since the last metric creation
  --fps: float # Current player video fps
  player_mode: string@player-mode-completer
  --resolution: float # Current player video resolution
  resolution_changes: float # How many resolution changes occured since the last metric creation
  uploaded_bytes_p2p: float # How many bytes were uploaded with P2P since the last metric creation
  video_id: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/metrics/playback"
    body: {content_type: "application/json", kind: json, fields: [{name: downloadedBytesHTTP, var: downloaded_bytes_http}, {name: downloadedBytesP2P, var: downloaded_bytes_p2p}, {name: errors, var: errors}, {name: fps, var: fps}, {name: playerMode, var: player_mode}, {name: resolution, var: resolution}, {name: resolutionChanges, var: resolution_changes}, {name: uploadedBytesP2P, var: uploaded_bytes_p2p}, {name: videoId, var: video_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    downloaded_bytes_http: $downloaded_bytes_http, downloaded_bytes_p2p: $downloaded_bytes_p2p, errors: $errors, fps: $fps, player_mode: $player_mode, resolution: $resolution, resolution_changes: $resolution_changes, uploaded_bytes_p2p: $uploaded_bytes_p2p, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login prerequisite
#
# GET /api/v1/oauth-clients/local
# Returns: record<client_id: string, client_secret: string>
# operationId: getOAuthClient
export def "get-o-auth-client" [
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
    path: "/api/v1/oauth-clients/local"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List plugins
#
# GET /api/v1/plugins
# Returns: record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int>
# operationId: getPlugins
export def "get-plugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plugin-type: int
  --uninstalled: oneof<nothing, bool>
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/plugins"
    query: [{name: pluginType, var: plugin_type}, {name: uninstalled, var: uninstalled}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plugin_type: $plugin_type, uninstalled: $uninstalled, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available plugins
#
# GET /api/v1/plugins/available
# Returns: record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int>
# operationId: getAvailablePlugins
export def "get-available-plugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --plugin-type: int
  --current-peer-tube-engine: string
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/plugins/available"
    query: [{name: search, var: search}, {name: pluginType, var: plugin_type}, {name: currentPeerTubeEngine, var: current_peer_tube_engine}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, plugin_type: $plugin_type, current_peer_tube_engine: $current_peer_tube_engine, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Install a plugin
#
# POST /api/v1/plugins/install
# operationId: addPlugin
export def "add-plugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --npm-name: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/plugins/install"
    body: {content_type: "application/json", kind: json, fields: [{name: npmName, var: npm_name}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    npm_name: $npm_name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uninstall a plugin
#
# POST /api/v1/plugins/uninstall
# operationId: uninstallPlugin
export def "uninstall-plugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  npm_name: string # name of the plugin/theme in its package.json (e.g. peertube-plugin-auth-ldap)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/plugins/uninstall"
    body: {content_type: "application/json", kind: json, fields: [{name: npmName, var: npm_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    npm_name: $npm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a plugin
#
# POST /api/v1/plugins/update
# operationId: updatePlugin
export def "update-plugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --npm-name: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/plugins/update"
    body: {content_type: "application/json", kind: json, fields: [{name: npmName, var: npm_name}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    npm_name: $npm_name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a plugin
#
# GET /api/v1/plugins/{npmName}
# Returns: record<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>
# operationId: getPlugin
export def "get-plugin" [
  npm_name: string
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
    path: "/api/v1/plugins/{npmName}"
    path_params: [{name: npmName, var: npm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    npm_name: $npm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a plugin's public settings
#
# GET /api/v1/plugins/{npmName}/public-settings
# Returns: record
export def "get-api-v1-plugins-npm-name-public-settings" [
  npm_name: string
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
    path: "/api/v1/plugins/{npmName}/public-settings"
    path_params: [{name: npmName, var: npm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    npm_name: $npm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a plugin's registered settings
#
# GET /api/v1/plugins/{npmName}/registered-settings
# Returns: record
export def "get-api-v1-plugins-npm-name-registered-settings" [
  npm_name: string
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
    path: "/api/v1/plugins/{npmName}/registered-settings"
    path_params: [{name: npmName, var: npm_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    npm_name: $npm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a plugin's settings
#
# PUT /api/v1/plugins/{npmName}/settings
export def "put-api-v1-plugins-npm-name-settings" [
  npm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/plugins/{npmName}/settings"
    path_params: [{name: npmName, var: npm_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    npm_name: $npm_name, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search channels
#
# GET /api/v1/search/video-channels
# Returns: record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>
# operationId: searchChannels
export def "search-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete channel information and interact with it. (required)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/search/video-channels"
    query: [{name: search, var: search, required: true}, {name: start, var: start}, {name: count, var: count}, {name: searchTarget, var: search_target}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, start: $start, count: $count, search_target: $search_target, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search playlists
#
# GET /api/v1/search/video-playlists
# Returns: record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>
# operationId: searchPlaylists
export def "search-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete playlist information and interact with it. (required)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/search/video-playlists"
    query: [{name: search, var: search, required: true}, {name: start, var: start}, {name: count, var: count}, {name: searchTarget, var: search_target}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, start: $start, count: $count, search_target: $search_target, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search videos
#
# GET /api/v1/search/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
# operationId: searchVideos
export def "search-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete video information and interact with it. (required)
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --uuids: string # Find videos with specific UUIDs
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --sort: string@sort-completer-3 # Sort videos by criteria (prefixing with `-` means `DESC` order):
  --start-date: string # Get videos that are published after this date (format: date-time)
  --end-date: string # Get videos that are published before this date (format: date-time)
  --originally-published-start-date: string # Get videos that are originally published after this date (format: date-time)
  --originally-published-end-date: string # Get videos that are originally published before this date (format: date-time)
  --duration-min: int # Get videos that have this minimum duration
  --duration-max: int # Get videos that have this maximum duration
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/search/videos"
    query: [{name: search, var: search, required: true}, {name: categoryOneOf, var: category_one_of}, {name: isLive, var: is_live}, {name: tagsOneOf, var: tags_one_of}, {name: tagsAllOf, var: tags_all_of}, {name: licenceOneOf, var: licence_one_of}, {name: languageOneOf, var: language_one_of}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: uuids, var: uuids}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}, {name: skipCount, var: skip_count}, {name: start, var: start}, {name: count, var: count}, {name: searchTarget, var: search_target}, {name: sort, var: sort}, {name: startDate, var: start_date}, {name: endDate, var: end_date}, {name: originallyPublishedStartDate, var: originally_published_start_date}, {name: originallyPublishedEndDate, var: originally_published_end_date}, {name: durationMin, var: duration_min}, {name: durationMax, var: duration_max}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, category_one_of: $category_one_of, is_live: $is_live, tags_one_of: $tags_one_of, tags_all_of: $tags_all_of, licence_one_of: $licence_one_of, language_one_of: $language_one_of, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, uuids: $uuids, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files, skip_count: $skip_count, start: $start, count: $count, search_target: $search_target, sort: $sort, start_date: $start_date, end_date: $end_date, originally_published_start_date: $originally_published_start_date, originally_published_end_date: $originally_published_end_date, duration_min: $duration_min, duration_max: $duration_max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance audit logs
#
# GET /api/v1/server/audit-logs
# Returns: list<string>
# operationId: getInstanceAuditLogs
export def "get-instance-audit-logs" [
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
    path: "/api/v1/server/audit-logs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List account blocks
#
# GET /api/v1/server/blocklist/accounts
export def "get-api-v1-server-blocklist-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/server/blocklist/accounts"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block an account
#
# POST /api/v1/server/blocklist/accounts
export def "post-api-v1-server-blocklist-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # account to block, in the form `username@domain` (e.g. chocobozzz@example.org)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/server/blocklist/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock an account by its handle
#
# DELETE /api/v1/server/blocklist/accounts/{accountName}
export def "delete-api-v1-server-blocklist-accounts-account-name" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/server/blocklist/accounts/{accountName}"
    path_params: [{name: accountName, var: account_name}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_name: $account_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List server blocks
#
# GET /api/v1/server/blocklist/servers
export def "get-api-v1-server-blocklist-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/server/blocklist/servers"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block a server
#
# POST /api/v1/server/blocklist/servers
export def "post-api-v1-server-blocklist-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string # server domain to block (format: hostname)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/server/blocklist/servers"
    body: {content_type: "application/json", kind: json, fields: [{name: host, var: host}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock a server by its domain
#
# DELETE /api/v1/server/blocklist/servers/{host}
export def "delete-api-v1-server-blocklist-servers-host" [
  host: string
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
    path: "/api/v1/server/blocklist/servers/{host}"
    path_params: [{name: host, var: host}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List instances following the server
#
# GET /api/v1/server/followers
# Returns: record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>
export def "get-api-v1-server-followers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-2
  --actor-type: string@actor-type-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/server/followers"
    query: [{name: state, var: state}, {name: actorType, var: actor_type}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, actor_type: $actor_type, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove or reject a follower to your server
#
# DELETE /api/v1/server/followers/{nameWithHost}
export def "delete-api-v1-server-followers-name-with-host" [
  name_with_host: string
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
    path: "/api/v1/server/followers/{nameWithHost}"
    path_params: [{name: nameWithHost, var: name_with_host}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_with_host: $name_with_host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/accept
export def "post-api-v1-server-followers-name-with-host-accept" [
  name_with_host: string
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
    path: "/api/v1/server/followers/{nameWithHost}/accept"
    path_params: [{name: nameWithHost, var: name_with_host}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_with_host: $name_with_host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/reject
export def "post-api-v1-server-followers-name-with-host-reject" [
  name_with_host: string
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
    path: "/api/v1/server/followers/{nameWithHost}/reject"
    path_params: [{name: nameWithHost, var: name_with_host}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_with_host: $name_with_host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List instances followed by the server
#
# GET /api/v1/server/following
# Returns: record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>
export def "get-api-v1-server-following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-2
  --actor-type: string@actor-type-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/server/following"
    query: [{name: state, var: state}, {name: actorType, var: actor_type}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, actor_type: $actor_type, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow a list of actors (PeerTube instance, channel or account)
#
# POST /api/v1/server/following
export def "post-api-v1-server-following" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --handles: list<string>
  --hosts: list<string>
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/server/following"
    body: {content_type: "application/json", kind: json, fields: [{name: handles, var: handles}, {name: hosts, var: hosts}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    handles: $handles, hosts: $hosts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow an actor (PeerTube instance, channel or account)
#
# DELETE /api/v1/server/following/{hostOrHandle}
export def "delete-api-v1-server-following-host-or-handle" [
  host_or_handle: string
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
    path: "/api/v1/server/following/{hostOrHandle}"
    path_params: [{name: hostOrHandle, var: host_or_handle}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    host_or_handle: $host_or_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance logs
#
# GET /api/v1/server/logs
# Returns: list<string>
# operationId: getInstanceLogs
export def "get-instance-logs" [
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
    path: "/api/v1/server/logs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send client log
#
# POST /api/v1/server/logs/client
# operationId: sendClientLog
export def "send-client-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  level: any@level-completer
  message: string
  --meta: string # Additional information regarding this log
  --stack-trace: string # Stack trace of the error if there is one
  url: string # URL of the current user page
  --user-agent: string # User agent of the web browser that sends the message
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/server/logs/client"
    body: {content_type: "application/json", kind: json, fields: [{name: level, var: level}, {name: message, var: message}, {name: meta, var: meta}, {name: stackTrace, var: stack_trace}, {name: url, var: url}, {name: userAgent, var: user_agent}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    level: $level, message: $message, meta: $meta, stack_trace: $stack_trace, url: $url, user_agent: $user_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos being mirrored
#
# GET /api/v1/server/redundancy/videos
# Returns: table<id: int, name: string, redundancies: record<files: list, streamingPlaylists: list>, url: string, uuid: string>
# operationId: getMirroredVideos
export def "get-mirrored-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target: string@target-completer # direction of the mirror (required)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-4 # Sort abuses by criteria
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/server/redundancy/videos"
    query: [{name: target, var: target, required: true}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target: $target, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mirror a video
#
# POST /api/v1/server/redundancy/videos
# operationId: putMirroredVideo
export def "put-mirrored-video" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_id: int # object id for the video
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/server/redundancy/videos"
    body: {content_type: "application/json", kind: json, fields: [{name: videoId, var: video_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mirror done on a video
#
# DELETE /api/v1/server/redundancy/videos/{redundancyId}
# operationId: delMirroredVideo
export def "del-mirrored-video" [
  redundancy_id: string
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
    path: "/api/v1/server/redundancy/videos/{redundancyId}"
    path_params: [{name: redundancyId, var: redundancy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    redundancy_id: $redundancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a server redundancy policy
#
# PUT /api/v1/server/redundancy/{host}
export def "put-api-v1-server-redundancy-host" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redundancy-allowed: oneof<nothing, bool> # allow mirroring of the host's local videos
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/server/redundancy/{host}"
    path_params: [{name: host, var: host}]
    body: {content_type: "application/json", kind: json, fields: [{name: redundancyAllowed, var: redundancy_allowed, required: true}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    host: $host, redundancy_allowed: $redundancy_allowed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance stats
#
# GET /api/v1/server/stats
# Returns: record<activityPubMessagesProcessedPerSecond: float, totalActivityPubMessagesErrors: float, totalActivityPubMessagesProcessed: float, totalActivityPubMessagesSuccesses: float, totalActivityPubMessagesWaiting: float, totalDailyActiveUsers: float, totalInstanceFollowers: float, totalInstanceFollowing: float, totalLocalDailyActiveVideoChannels: float, totalLocalMonthlyActiveVideoChannels: float, totalLocalPlaylists: float, totalLocalVideoChannels: float, totalLocalVideoComments: float, totalLocalVideoFilesSize: float, totalLocalVideoViews: float, totalLocalVideos: float, totalLocalWeeklyActiveVideoChannels: float, totalMonthlyActiveUsers: float, totalUsers: float, totalVideoComments: float, totalVideos: float, totalWeeklyActiveUsers: float, videosRedundancy: table<strategy: string, totalSize: float, totalUsed: float, totalVideoFiles: float, totalVideos: float>>
# operationId: getInstanceStats
export def "get-instance-stats" [
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
    path: "/api/v1/server/stats"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /api/v1/users
# Returns: table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: int, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int>
# operationId: getUsers
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
  --search: string # Plain text search that will match with user usernames or emails
  --blocked: oneof<nothing, bool> # Filter results down to (un)banned users
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-5 # Sort users by criteria
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users"
    query: [{name: search, var: search}, {name: blocked, var: blocked}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, blocked: $blocked, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a user
#
# POST /api/v1/users
# Returns: record<user: record<account: record<id: int>, id: int>>
# operationId: addUser
export def "add-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-flags: int@admin-flags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --channel-name: string # immutable name of the channel, used to interact with its actor (e.g. framasoft_videos)
  email: string # The user email (format: email)
  password: string # format: password
  role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  username: string # immutable name of the user, used to find or mention its actor (e.g. chocobozzz)
  video_quota: int # The user video quota in bytes (e.g. -1)
  video_quota_daily: int # The user daily video quota in bytes (e.g. -1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users"
    body: {content_type: "application/json", kind: json, fields: [{name: adminFlags, var: admin_flags}, {name: channelName, var: channel_name}, {name: email, var: email}, {name: password, var: password}, {name: role, var: role}, {name: username, var: username}, {name: videoQuota, var: video_quota}, {name: videoQuotaDaily, var: video_quota_daily}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    admin_flags: $admin_flags, channel_name: $channel_name, email: $email, password: $password, role: $role, username: $username, video_quota: $video_quota, video_quota_daily: $video_quota_daily
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend user verification link
#
# POST /api/v1/users/ask-send-verify-email
# operationId: resendEmailToVerifyUser
export def "resend-email-to-verify-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/ask-send-verify-email"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get my user information
#
# GET /api/v1/users/me
# Returns: table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: int, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int>
# operationId: getUserInfo
export def "get-user-info" [
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
    path: "/api/v1/users/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update my user information
#
# PUT /api/v1/users/me
# operationId: putUserInfo
export def "put-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-play-next-video: oneof<nothing, bool> # new preference regarding playing following videos automatically
  --auto-play-next-video-playlist: oneof<nothing, bool> # new preference regarding playing following playlist videos automatically
  --auto-play-video: oneof<nothing, bool> # new preference regarding playing videos automatically
  --current-password: string # format: password
  --display-nsfw: string@display-nsfw-completer # new NSFW display policy
  --display-name: string # new name of the user in its representations
  --email: string # new email used for login and service communications (format: email)
  --no-account-setup-warning-modal: oneof<nothing, bool>
  --no-instance-config-warning-modal: oneof<nothing, bool>
  --no-welcome-modal: oneof<nothing, bool>
  --p2p-enabled: oneof<nothing, bool> # whether to enable P2P in the player or not
  --password: string # format: password
  --theme: string
  --video-languages: list<string> # list of languages to filter videos down to
  --videos-history-enabled: oneof<nothing, bool> # whether to keep track of watched history or not
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/users/me"
    body: {content_type: "application/json", kind: json, fields: [{name: autoPlayNextVideo, var: auto_play_next_video}, {name: autoPlayNextVideoPlaylist, var: auto_play_next_video_playlist}, {name: autoPlayVideo, var: auto_play_video}, {name: currentPassword, var: current_password}, {name: displayNSFW, var: display_nsfw}, {name: displayName, var: display_name}, {name: email, var: email}, {name: noAccountSetupWarningModal, var: no_account_setup_warning_modal}, {name: noInstanceConfigWarningModal, var: no_instance_config_warning_modal}, {name: noWelcomeModal, var: no_welcome_modal}, {name: p2pEnabled, var: p2p_enabled}, {name: password, var: password}, {name: theme, var: theme}, {name: videoLanguages, var: video_languages}, {name: videosHistoryEnabled, var: videos_history_enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    auto_play_next_video: $auto_play_next_video, auto_play_next_video_playlist: $auto_play_next_video_playlist, auto_play_video: $auto_play_video, current_password: $current_password, display_nsfw: $display_nsfw, display_name: $display_name, email: $email, no_account_setup_warning_modal: $no_account_setup_warning_modal, no_instance_config_warning_modal: $no_instance_config_warning_modal, no_welcome_modal: $no_welcome_modal, p2p_enabled: $p2p_enabled, password: $password, theme: $theme, video_languages: $video_languages, videos_history_enabled: $videos_history_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List my abuses
#
# GET /api/v1/users/me/abuses
# Returns: record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int>
# operationId: getMyAbuses
export def "get-my-abuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --state: int@state-completer
  --sort: string@sort-completer # Sort abuses by criteria
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/abuses"
    query: [{name: id, var: id}, {name: state, var: state}, {name: sort, var: sort}, {name: start, var: start}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, sort: $sort, start: $start, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete my avatar
#
# DELETE /api/v1/users/me/avatar
export def "delete-api-v1-users-me-avatar" [
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
    path: "/api/v1/users/me/avatar"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update my user avatar
#
# POST /api/v1/users/me/avatar/pick
# Returns: record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>>
export def "post-api-v1-users-me-avatar-pick" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users/me/avatar/pick"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: avatarfile, var: avatarfile}], files: [avatarfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    avatarfile: $avatarfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List watched videos history
#
# GET /api/v1/users/me/history/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
export def "get-api-v1-users-me-history-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/history/videos"
    query: [{name: start, var: start}, {name: count, var: count}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear video history
#
# POST /api/v1/users/me/history/videos/remove
export def "post-api-v1-users-me-history-videos-remove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-date: string # history before this date will be deleted (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/me/history/videos/remove"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: beforeDate, var: before_date}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    before_date: $before_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete history element
#
# DELETE /api/v1/users/me/history/videos/{videoId}
export def "delete-api-v1-users-me-history-videos-video-id" [
  video_id: int
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
    path: "/api/v1/users/me/history/videos/{videoId}"
    path_params: [{name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update my notification settings
#
# PUT /api/v1/users/me/notification-settings
export def "put-api-v1-users-me-notification-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --abuse-as-moderator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --auto-instance-following: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --blacklist-on-my-video: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --comment-mention: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --my-video-import-finished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --my-video-published: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-comment-on-my-video: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-follow: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-instance-follower: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-user-registration: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-video-from-subscription: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --video-auto-blacklist-as-moderator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/users/me/notification-settings"
    body: {content_type: "application/json", kind: json, fields: [{name: abuseAsModerator, var: abuse_as_moderator}, {name: autoInstanceFollowing, var: auto_instance_following}, {name: blacklistOnMyVideo, var: blacklist_on_my_video}, {name: commentMention, var: comment_mention}, {name: myVideoImportFinished, var: my_video_import_finished}, {name: myVideoPublished, var: my_video_published}, {name: newCommentOnMyVideo, var: new_comment_on_my_video}, {name: newFollow, var: new_follow}, {name: newInstanceFollower, var: new_instance_follower}, {name: newUserRegistration, var: new_user_registration}, {name: newVideoFromSubscription, var: new_video_from_subscription}, {name: videoAutoBlacklistAsModerator, var: video_auto_blacklist_as_moderator}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    abuse_as_moderator: $abuse_as_moderator, auto_instance_following: $auto_instance_following, blacklist_on_my_video: $blacklist_on_my_video, comment_mention: $comment_mention, my_video_import_finished: $my_video_import_finished, my_video_published: $my_video_published, new_comment_on_my_video: $new_comment_on_my_video, new_follow: $new_follow, new_instance_follower: $new_instance_follower, new_user_registration: $new_user_registration, new_video_from_subscription: $new_video_from_subscription, video_auto_blacklist_as_moderator: $video_auto_blacklist_as_moderator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List my notifications
#
# GET /api/v1/users/me/notifications
# Returns: record<data: table<account: record, actorFollow: record, comment: record, createdAt: string, id: int, read: bool, type: int, updatedAt: string, video: record, videoAbuse: record, videoBlacklist: record, videoImport: record>, total: int>
export def "get-api-v1-users-me-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unread: oneof<nothing, bool> # only list unread notifications
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/notifications"
    query: [{name: unread, var: unread}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    unread: $unread, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark notifications as read by their id
#
# POST /api/v1/users/me/notifications/read
export def "post-api-v1-users-me-notifications-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<int> # ids of the notifications to mark as read
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/me/notifications/read"
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark all my notification as read
#
# POST /api/v1/users/me/notifications/read-all
export def "post-api-v1-users-me-notifications-read-all" [
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
    path: "/api/v1/users/me/notifications/read-all"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get my user subscriptions
#
# GET /api/v1/users/me/subscriptions
# Returns: record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>
export def "get-api-v1-users-me-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/subscriptions"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add subscription to my user
#
# POST /api/v1/users/me/subscriptions
export def "post-api-v1-users-me-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uri: string # uri of the video channels to subscribe to (format: uri)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/me/subscriptions"
    body: {content_type: "application/json", kind: json, fields: [{name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get if subscriptions exist for my user
#
# GET /api/v1/users/me/subscriptions/exist
# Returns: record
export def "get-api-v1-users-me-subscriptions-exist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: list<string> # list of uris to check if each is part of the user subscriptions (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/subscriptions/exist"
    query: [{name: uris, var: uris, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos of subscriptions of my user
#
# GET /api/v1/users/me/subscriptions/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
export def "get-api-v1-users-me-subscriptions-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/subscriptions/videos"
    query: [{name: categoryOneOf, var: category_one_of}, {name: isLive, var: is_live}, {name: tagsOneOf, var: tags_one_of}, {name: tagsAllOf, var: tags_all_of}, {name: licenceOneOf, var: licence_one_of}, {name: languageOneOf, var: language_one_of}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}, {name: skipCount, var: skip_count}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_one_of: $category_one_of, is_live: $is_live, tags_one_of: $tags_one_of, tags_all_of: $tags_all_of, licence_one_of: $licence_one_of, language_one_of: $language_one_of, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files, skip_count: $skip_count, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete subscription of my user
#
# DELETE /api/v1/users/me/subscriptions/{subscriptionHandle}
export def "delete-api-v1-users-me-subscriptions-subscription-handle" [
  subscription_handle: string
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
    path: "/api/v1/users/me/subscriptions/{subscriptionHandle}"
    path_params: [{name: subscriptionHandle, var: subscription_handle}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_handle: $subscription_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subscription of my user
#
# GET /api/v1/users/me/subscriptions/{subscriptionHandle}
# Returns: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>
export def "get-api-v1-users-me-subscriptions-subscription-handle" [
  subscription_handle: string
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
    path: "/api/v1/users/me/subscriptions/{subscriptionHandle}"
    path_params: [{name: subscriptionHandle, var: subscription_handle}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_handle: $subscription_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check video exists in my playlists
#
# GET /api/v1/users/me/video-playlists/videos-exist
# Returns: record<videoId: table<playlistElementId: int, playlistId: int, startTimestamp: int, stopTimestamp: int>>
export def "get-api-v1-users-me-video-playlists-videos-exist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-ids: list<int> # The video ids to check (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/video-playlists/videos-exist"
    query: [{name: videoIds, var: video_ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_ids: $video_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get my user used quota
#
# GET /api/v1/users/me/video-quota-used
# Returns: record<videoQuotaUsed: float, videoQuotaUsedDaily: float>
export def "get-api-v1-users-me-video-quota-used" [
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
    path: "/api/v1/users/me/video-quota-used"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get videos of my user
#
# GET /api/v1/users/me/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
export def "get-api-v1-users-me-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/videos"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get video imports of my user
#
# GET /api/v1/users/me/videos/imports
# Returns: record<data: table<createdAt: string, error: string, id: int, magnetUri: string, state: record, targetUrl: string, torrentName: string, torrentfile: string, updatedAt: string, video: record>, total: int>
export def "get-api-v1-users-me-videos-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
  --target-url: string # Filter on import target URL
  --video-channel-sync-id: float # Filter on imports created by a specific channel synchronization
  --search: string # Search in video names
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/me/videos/imports"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: targetUrl, var: target_url}, {name: videoChannelSyncId, var: video_channel_sync_id}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort, target_url: $target_url, video_channel_sync_id: $video_channel_sync_id, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get rate of my user for a video
#
# GET /api/v1/users/me/videos/{videoId}/rating
# Returns: record<id: int, rating: string>
export def "get-api-v1-users-me-videos-video-id-rating" [
  video_id: int
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
    path: "/api/v1/users/me/videos/{videoId}/rating"
    path_params: [{name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a user
#
# POST /api/v1/users/register
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
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --display-name: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: string # immutable name of the user, used to find or mention its actor
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/register"
    body: {content_type: "application/json", kind: json, fields: [{name: channel, var: channel}, {name: displayName, var: display_name}, {name: email, var: email}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel: $channel, display_name: $display_name, email: $email, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List registrations
#
# GET /api/v1/users/registrations
# Returns: record<data: table<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record, updatedAt: string, user: record, username: string>, total: int>
# operationId: listRegistrations
export def "list-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string
  --sort: string@sort-completer-6
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/users/registrations"
    query: [{name: start, var: start}, {name: count, var: count}, {name: search, var: search}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, search: $search, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend verification link to registration email
#
# POST /api/v1/users/registrations/ask-send-verify-email
# operationId: resendEmailToVerifyRegistration
export def "resend-email-to-verify-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Registration email
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/registrations/ask-send-verify-email"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request registration
#
# POST /api/v1/users/registrations/request
# Returns: record<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record<id: int, label: string>, updatedAt: string, user: record<id: int>, username: string>
# operationId: requestRegistration
export def "request-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --display-name: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: string # immutable name of the user, used to find or mention its actor
  registration_reason: string # reason for the user to register on the instance
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users/registrations/request"
    body: {content_type: "application/json", kind: json, fields: [{name: channel, var: channel}, {name: displayName, var: display_name}, {name: email, var: email}, {name: password, var: password}, {name: username, var: username}, {name: registrationReason, var: registration_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel: $channel, display_name: $display_name, email: $email, password: $password, username: $username, registration_reason: $registration_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete registration
#
# DELETE /api/v1/users/registrations/{registrationId}
# operationId: deleteRegistration
export def "delete-registration" [
  registration_id: int
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
    path: "/api/v1/users/registrations/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept registration
#
# POST /api/v1/users/registrations/{registrationId}/accept
# operationId: acceptRegistration
export def "accept-registration" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderation_response: string # Moderation response to send to the user
  --prevent-email-delivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/registrations/{registrationId}/accept"
    path_params: [{name: registrationId, var: registration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: moderationResponse, var: moderation_response}, {name: preventEmailDelivery, var: prevent_email_delivery}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    registration_id: $registration_id, moderation_response: $moderation_response, prevent_email_delivery: $prevent_email_delivery
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject registration
#
# POST /api/v1/users/registrations/{registrationId}/reject
# operationId: rejectRegistration
export def "reject-registration" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderation_response: string # Moderation response to send to the user
  --prevent-email-delivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/registrations/{registrationId}/reject"
    path_params: [{name: registrationId, var: registration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: moderationResponse, var: moderation_response}, {name: preventEmailDelivery, var: prevent_email_delivery}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    registration_id: $registration_id, moderation_response: $moderation_response, prevent_email_delivery: $prevent_email_delivery
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a registration email
#
# POST /api/v1/users/registrations/{registrationId}/verify-email
# operationId: verifyRegistrationEmail
export def "verify-registration-email" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  verification_string: string # format: url
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/registrations/{registrationId}/verify-email"
    path_params: [{name: registrationId, var: registration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: verificationString, var: verification_string}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    registration_id: $registration_id, verification_string: $verification_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout
#
# POST /api/v1/users/revoke-token
# operationId: revokeOAuthToken
export def "revoke-o-auth-token" [
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
    path: "/api/v1/users/revoke-token"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login
#
# POST /api/v1/users/token
# Discriminator (request): grant_type = password, refresh_token
# Returns: record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, token_type: string>
# operationId: getOAuthToken
export def "get-o-auth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # e.g. v1ikx5hnfop4mdpnci8nsqh93c45rldf
  client_secret: string # e.g. AjWiOapPltI6EnsWQwlFarRtLh4u8tDt
  grant_type: string@grant-type-completer # default: password
  --password: string # format: password
  --username: string # immutable name of the user, used to find or mention its actor (e.g. chocobozzz)
  --refresh-token: string # e.g. 2e0d675df9fc96d2e4ec8a3ebbbf45eca9137bb7
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: grant_type, var: grant_type}, {name: password, var: password}, {name: username, var: username}, {name: refresh_token, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, password: $password, username: $username, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /api/v1/users/{id}
# operationId: delUser
export def "del-user" [
  id: int
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
    path: "/api/v1/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /api/v1/users/{id}
# operationId: getUser
export def "get-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-stats: oneof<nothing, bool> # include statistics about the user (only available as a moderator/admin)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: withStats, var: with_stats}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, with_stats: $with_stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PUT /api/v1/users/{id}
# operationId: putUser
export def "put-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-flags: int@admin-flags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --email: string # The updated email of the user (format: email)
  --email-verified: oneof<nothing, bool> # Set the email as verified
  --password: string # format: password
  --plugin-auth: string # The auth plugin to use to authenticate the user (nullable, e.g. peertube-plugin-auth-saml2)
  --role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  --video-quota: int # The updated video quota of the user in bytes
  --video-quota-daily: int # The updated daily video quota of the user in bytes
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminFlags, var: admin_flags}, {name: email, var: email}, {name: emailVerified, var: email_verified}, {name: password, var: password}, {name: pluginAuth, var: plugin_auth}, {name: role, var: role}, {name: videoQuota, var: video_quota}, {name: videoQuotaDaily, var: video_quota_daily}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, admin_flags: $admin_flags, email: $email, email_verified: $email_verified, password: $password, plugin_auth: $plugin_auth, role: $role, video_quota: $video_quota, video_quota_daily: $video_quota_daily
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm two factor auth
#
# POST /api/v1/users/{id}/two-factor/confirm-request
# operationId: confirmTwoFactorRequest
export def "confirm-two-factor-request" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  otp_token: string # OTP token generated by the app
  request_token: string # Token to identify the two factor request
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/{id}/two-factor/confirm-request"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: otpToken, var: otp_token}, {name: requestToken, var: request_token}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, otp_token: $otp_token, request_token: $request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable two factor auth
#
# POST /api/v1/users/{id}/two-factor/disable
# operationId: disableTwoFactor
export def "disable-two-factor" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-password: string # Password of the currently authenticated user
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/{id}/two-factor/disable"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentPassword, var: current_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, current_password: $current_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request two factor auth
#
# POST /api/v1/users/{id}/two-factor/request
# Returns: table<otpRequest: record<requestToken: string, secret: string, uri: string>>
# operationId: requestTwoFactor
export def "request-two-factor" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-password: string # Password of the currently authenticated user
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/users/{id}/two-factor/request"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentPassword, var: current_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, current_password: $current_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a user
#
# POST /api/v1/users/{id}/verify-email
# operationId: verifyUser
export def "verify-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-pending-email: oneof<nothing, bool>
  verification_string: string # format: url
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/users/{id}/verify-email"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: isPendingEmail, var: is_pending_email}, {name: verificationString, var: verification_string}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, is_pending_email: $is_pending_email, verification_string: $verification_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a synchronization for a video channel
#
# POST /api/v1/video-channel-syncs
# Returns: record<videoChannelSync: record<channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record<id: int, label: string>>>
# operationId: addVideoChannelSync
export def "add-video-channel-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-channel-url: string # e.g. https://youtube.com/c/UC_myfancychannel
  --video-channel-id: int # e.g. 42
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-channel-syncs"
    body: {content_type: "application/json", kind: json, fields: [{name: externalChannelUrl, var: external_channel_url}, {name: videoChannelId, var: video_channel_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_channel_url: $external_channel_url, video_channel_id: $video_channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video channel synchronization
#
# DELETE /api/v1/video-channel-syncs/{channelSyncId}
# operationId: delVideoChannelSync
export def "del-video-channel-sync" [
  channel_sync_id: int
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
    path: "/api/v1/video-channel-syncs/{channelSyncId}"
    path_params: [{name: channelSyncId, var: channel_sync_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_sync_id: $channel_sync_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers the channel synchronization job, fetching all the videos from the remote channel
#
# POST /api/v1/video-channel-syncs/{channelSyncId}/sync
# operationId: triggerVideoChannelSync
export def "trigger-video-channel-sync" [
  channel_sync_id: int
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
    path: "/api/v1/video-channel-syncs/{channelSyncId}/sync"
    path_params: [{name: channelSyncId, var: channel_sync_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_sync_id: $channel_sync_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video channels
#
# GET /api/v1/video-channels
# Returns: record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, total: int>
# operationId: getVideoChannels
export def "get-video-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-channels"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a video channel
#
# POST /api/v1/video-channels
# Returns: record<videoChannel: record<id: int>>
# operationId: addVideoChannel
export def "add-video-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Channel description
  display_name: any # Channel display name
  --support: any # How to support/fund the channel
  name: string # username of the channel to create
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-channels"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: support, var: support}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, display_name: $display_name, support: $support, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video channel
#
# DELETE /api/v1/video-channels/{channelHandle}
# operationId: delVideoChannel
export def "del-video-channel" [
  channel_handle: string
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
    path: "/api/v1/video-channels/{channelHandle}"
    path_params: [{name: channelHandle, var: channel_handle}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_handle: $channel_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a video channel
#
# GET /api/v1/video-channels/{channelHandle}
# Returns: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>
# operationId: getVideoChannel
export def "get-video-channel" [
  channel_handle: string
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
    path: "/api/v1/video-channels/{channelHandle}"
    path_params: [{name: channelHandle, var: channel_handle}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a video channel
#
# PUT /api/v1/video-channels/{channelHandle}
# operationId: putVideoChannel
export def "put-video-channel" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Channel description
  --display-name: any # Channel display name
  --support: any # How to support/fund the channel
  --bulk-videos-support-update: oneof<nothing, bool> # Update the support field for all videos of this channel
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/video-channels/{channelHandle}"
    path_params: [{name: channelHandle, var: channel_handle}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: support, var: support}, {name: bulkVideosSupportUpdate, var: bulk_videos_support_update}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_handle: $channel_handle, description: $description, display_name: $display_name, support: $support, bulk_videos_support_update: $bulk_videos_support_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete channel avatar
#
# DELETE /api/v1/video-channels/{channelHandle}/avatar
export def "delete-api-v1-video-channels-channel-handle-avatar" [
  channel_handle: string
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
    path: "/api/v1/video-channels/{channelHandle}/avatar"
    path_params: [{name: channelHandle, var: channel_handle}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_handle: $channel_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update channel avatar
#
# POST /api/v1/video-channels/{channelHandle}/avatar/pick
# Returns: record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>>
export def "post-api-v1-video-channels-channel-handle-avatar-pick" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-channels/{channelHandle}/avatar/pick"
    path_params: [{name: channelHandle, var: channel_handle}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: avatarfile, var: avatarfile}], files: [avatarfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle, avatarfile: $avatarfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete channel banner
#
# DELETE /api/v1/video-channels/{channelHandle}/banner
export def "delete-api-v1-video-channels-channel-handle-banner" [
  channel_handle: string
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
    path: "/api/v1/video-channels/{channelHandle}/banner"
    path_params: [{name: channelHandle, var: channel_handle}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_handle: $channel_handle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update channel banner
#
# POST /api/v1/video-channels/{channelHandle}/banner/pick
# Returns: record<banners: table<createdAt: string, path: string, updatedAt: string, width: int>>
export def "post-api-v1-video-channels-channel-handle-banner-pick" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bannerfile: string # The file to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-channels/{channelHandle}/banner/pick"
    path_params: [{name: channelHandle, var: channel_handle}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: bannerfile, var: bannerfile}], files: [bannerfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle, bannerfile: $bannerfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List followers of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/followers
# Returns: record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int>
# operationId: getVideoChannelFollowers
export def "get-video-channel-followers" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-channels/{channelHandle}/followers"
    path_params: [{name: channelHandle, var: channel_handle}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle, start: $start, count: $count, sort: $sort, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import videos in channel
#
# POST /api/v1/video-channels/{channelHandle}/import-videos
export def "post-api-v1-video-channels-channel-handle-import-videos" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  external_channel_url: string # e.g. https://youtube.com/c/UC_myfancychannel
  --video-channel-sync-id: int # If part of a channel sync process, specify its id to assign video imports to this channel synchronization
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/video-channels/{channelHandle}/import-videos"
    path_params: [{name: channelHandle, var: channel_handle}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalChannelUrl, var: external_channel_url}, {name: videoChannelSyncId, var: video_channel_sync_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    channel_handle: $channel_handle, external_channel_url: $external_channel_url, video_channel_sync_id: $video_channel_sync_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List playlists of a channel
#
# GET /api/v1/video-channels/{channelHandle}/video-playlists
# Returns: record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>
export def "get-api-v1-video-channels-channel-handle-video-playlists" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
  --playlist-type: int@playlist-type-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-channels/{channelHandle}/video-playlists"
    path_params: [{name: channelHandle, var: channel_handle}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: playlistType, var: playlist_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle, start: $start, count: $count, sort: $sort, playlist_type: $playlist_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
# operationId: getVideoChannelVideos
export def "get-video-channel-videos" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-channels/{channelHandle}/videos"
    path_params: [{name: channelHandle, var: channel_handle}]
    query: [{name: categoryOneOf, var: category_one_of}, {name: isLive, var: is_live}, {name: tagsOneOf, var: tags_one_of}, {name: tagsAllOf, var: tags_all_of}, {name: licenceOneOf, var: licence_one_of}, {name: languageOneOf, var: language_one_of}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}, {name: skipCount, var: skip_count}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_handle: $channel_handle, category_one_of: $category_one_of, is_live: $is_live, tags_one_of: $tags_one_of, tags_all_of: $tags_all_of, licence_one_of: $licence_one_of, language_one_of: $language_one_of, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files, skip_count: $skip_count, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video playlists
#
# GET /api/v1/video-playlists
# Returns: record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: string, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int>
# operationId: getPlaylists
export def "get-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string # Sort column (e.g. -createdAt)
  --playlist-type: int@playlist-type-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-playlists"
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}, {name: playlistType, var: playlist_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start: $start, count: $count, sort: $sort, playlist_type: $playlist_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a video playlist
#
# POST /api/v1/video-playlists
# Returns: record<videoPlaylist: record<id: int, shortUUID: string, uuid: string>>
# operationId: addPlaylist
export def "add-playlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Video playlist description
  display_name: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --video-channel-id: int # Video channel in which the playlist will be published
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-playlists"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: privacy, var: privacy}, {name: thumbnailfile, var: thumbnailfile}, {name: videoChannelId, var: video_channel_id}], files: [thumbnailfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, display_name: $display_name, privacy: $privacy, thumbnailfile: $thumbnailfile, video_channel_id: $video_channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available playlist privacy policies
#
# GET /api/v1/video-playlists/privacies
# Returns: list<string>
# operationId: getPlaylistPrivacyPolicies
export def "get-playlist-privacy-policies" [
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
    path: "/api/v1/video-playlists/privacies"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video playlist
#
# DELETE /api/v1/video-playlists/{playlistId}
export def "delete-api-v1-video-playlists-playlist-id" [
  playlist_id: int
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
    path: "/api/v1/video-playlists/{playlistId}"
    path_params: [{name: playlistId, var: playlist_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a video playlist
#
# GET /api/v1/video-playlists/{playlistId}
# Returns: record<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, privacy: record<id: int, label: string>, shortUUID: string, thumbnailPath: string, type: record<id: int, label: string>, updatedAt: string, uuid: string, videoChannel: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, videoLength: int>
export def "get-api-v1-video-playlists-playlist-id" [
  playlist_id: int
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
    path: "/api/v1/video-playlists/{playlistId}"
    path_params: [{name: playlistId, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a video playlist
#
# PUT /api/v1/video-playlists/{playlistId}
export def "put-api-v1-video-playlists-playlist-id" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Video playlist description
  --display-name: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --video-channel-id: int # Video channel in which the playlist will be published
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/video-playlists/{playlistId}"
    path_params: [{name: playlistId, var: playlist_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: privacy, var: privacy}, {name: thumbnailfile, var: thumbnailfile}, {name: videoChannelId, var: video_channel_id}], files: [thumbnailfile]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playlist_id: $playlist_id, description: $description, display_name: $display_name, privacy: $privacy, thumbnailfile: $thumbnailfile, video_channel_id: $video_channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos of a playlist
#
# GET /api/v1/video-playlists/{playlistId}/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
# operationId: getVideoPlaylistVideos
export def "get-video-playlist-videos" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/video-playlists/{playlistId}/videos"
    path_params: [{name: playlistId, var: playlist_id}]
    query: [{name: start, var: start}, {name: count, var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, start: $start, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a video in a playlist
#
# POST /api/v1/video-playlists/{playlistId}/videos
# Returns: record<videoPlaylistElement: record<id: int>>
# operationId: addVideoPlaylistVideo
export def "add-video-playlist-video" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: int # Start the video at this specific timestamp (format: seconds)
  --stop-timestamp: int # Stop the video at this specific timestamp (format: seconds)
  video_id: any # Video to add in the playlist
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/video-playlists/{playlistId}/videos"
    path_params: [{name: playlistId, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: startTimestamp, var: start_timestamp}, {name: stopTimestamp, var: stop_timestamp}, {name: videoId, var: video_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, start_timestamp: $start_timestamp, stop_timestamp: $stop_timestamp, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder a playlist
#
# POST /api/v1/video-playlists/{playlistId}/videos/reorder
# operationId: reorderVideoPlaylist
export def "reorder-video-playlist" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  insert_after_position: int # New position for the block to reorder, to add the block before the first element
  --reorder-length: int # How many element from `startPosition` to reorder
  start_position: int # Start position of the element to reorder
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/video-playlists/{playlistId}/videos/reorder"
    path_params: [{name: playlistId, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: insertAfterPosition, var: insert_after_position}, {name: reorderLength, var: reorder_length}, {name: startPosition, var: start_position}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playlist_id: $playlist_id, insert_after_position: $insert_after_position, reorder_length: $reorder_length, start_position: $start_position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an element from a playlist
#
# DELETE /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: delVideoPlaylistVideo
export def "del-video-playlist-video" [
  playlist_id: int
  playlist_element_id: int
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
    path: "/api/v1/video-playlists/{playlistId}/videos/{playlistElementId}"
    path_params: [{name: playlistId, var: playlist_id}, {name: playlistElementId, var: playlist_element_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playlist_id: $playlist_id, playlist_element_id: $playlist_element_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a playlist element
#
# PUT /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: putVideoPlaylistVideo
export def "put-video-playlist-video" [
  playlist_id: int
  playlist_element_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: int # Start the video at this specific timestamp (format: seconds)
  --stop-timestamp: int # Stop the video at this specific timestamp (format: seconds)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/video-playlists/{playlistId}/videos/{playlistElementId}"
    path_params: [{name: playlistId, var: playlist_id}, {name: playlistElementId, var: playlist_element_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: startTimestamp, var: start_timestamp}, {name: stopTimestamp, var: stop_timestamp}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playlist_id: $playlist_id, playlist_element_id: $playlist_element_id, start_timestamp: $start_timestamp, stop_timestamp: $stop_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos
#
# GET /api/v1/videos
# Returns: record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: string, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: string, views: int, waitTranscoding: bool>, total: int>
# operationId: getVideos
export def "get-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos"
    query: [{name: categoryOneOf, var: category_one_of}, {name: isLive, var: is_live}, {name: tagsOneOf, var: tags_one_of}, {name: tagsAllOf, var: tags_all_of}, {name: licenceOneOf, var: licence_one_of}, {name: languageOneOf, var: language_one_of}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}, {name: skipCount, var: skip_count}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_one_of: $category_one_of, is_live: $is_live, tags_one_of: $tags_one_of, tags_all_of: $tags_all_of, licence_one_of: $licence_one_of, language_one_of: $language_one_of, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files, skip_count: $skip_count, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video blocks
#
# GET /api/v1/videos/blacklist
# Returns: record<data: table<createdAt: string, description: string, dislikes: int, duration: int, id: int, likes: int, name: string, nsfw: bool, updatedAt: string, uuid: string, videoId: int, views: int>, total: int>
# operationId: getVideoBlocks
export def "get-video-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: int@type-completer # list only blocks that match this type: - `1`: manual block - `2`: automatic block that needs review
  --search: string # plain search that will match with video titles, and more
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-7 # Sort blocklists by criteria
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos/blacklist"
    query: [{name: type, var: type}, {name: search, var: search}, {name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, search: $search, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available video categories
#
# GET /api/v1/videos/categories
# Returns: list<string>
# operationId: getCategories
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos/categories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a video
#
# POST /api/v1/videos/imports
# Returns: record<video: record<id: int, shortUUID: string, uuid: string>>
# operationId: importVideo
export def "import-video" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/videos/imports"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: channelId, var: channel_id}, {name: commentsEnabled, var: comments_enabled}, {name: description, var: description}, {name: downloadEnabled, var: download_enabled}, {name: language, var: language}, {name: licence, var: licence}, {name: name, var: name}, {name: nsfw, var: nsfw}, {name: originallyPublishedAt, var: originally_published_at}, {name: previewfile, var: previewfile}, {name: privacy, var: privacy}, {name: scheduleUpdate, var: schedule_update}, {name: support, var: support}, {name: tags, var: tags}, {name: thumbnailfile, var: thumbnailfile}, {name: waitTranscoding, var: wait_transcoding}], files: [previewfile, thumbnailfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, channel_id: $channel_id, comments_enabled: $comments_enabled, description: $description, download_enabled: $download_enabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originally_published_at: $originally_published_at, previewfile: $previewfile, privacy: $privacy, schedule_update: $schedule_update, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, wait_transcoding: $wait_transcoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete video import
#
# DELETE /api/v1/videos/imports/{id}
export def "delete-api-v1-videos-imports-id" [
  id: int
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
    path: "/api/v1/videos/imports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel video import
#
# POST /api/v1/videos/imports/{id}/cancel
export def "post-api-v1-videos-imports-id-cancel" [
  id: int
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
    path: "/api/v1/videos/imports/{id}/cancel"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available video languages
#
# GET /api/v1/videos/languages
# Returns: list<string>
# operationId: getLanguages
export def "get-languages" [
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
    path: "/api/v1/videos/languages"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available video licences
#
# GET /api/v1/videos/licences
# Returns: list<string>
# operationId: getLicences
export def "get-licences" [
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
    path: "/api/v1/videos/licences"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a live
#
# POST /api/v1/videos/live
# Returns: record<video: record<id: int, shortUUID: string, uuid: string>>
# operationId: addLive
export def "add-live" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this live video
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this live video/replay
  --description: string # Live video/replay description
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for the replay of this live video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --latency-mode: int@latency-mode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Live video/replay name
  --nsfw: oneof<nothing, bool> # Whether or not this live video/replay contains sensitive content
  --permanent-live: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --previewfile: string # Live video/replay preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --save-replay: oneof<nothing, bool>
  --support: string # A text tell the audience how to support the creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Live video/replay tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Live video/replay thumbnail file (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/videos/live"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: channelId, var: channel_id}, {name: commentsEnabled, var: comments_enabled}, {name: description, var: description}, {name: downloadEnabled, var: download_enabled}, {name: language, var: language}, {name: latencyMode, var: latency_mode}, {name: licence, var: licence}, {name: name, var: name}, {name: nsfw, var: nsfw}, {name: permanentLive, var: permanent_live}, {name: previewfile, var: previewfile}, {name: privacy, var: privacy}, {name: saveReplay, var: save_replay}, {name: support, var: support}, {name: tags, var: tags}, {name: thumbnailfile, var: thumbnailfile}], files: [previewfile, thumbnailfile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, channel_id: $channel_id, comments_enabled: $comments_enabled, description: $description, download_enabled: $download_enabled, language: $language, latency_mode: $latency_mode, licence: $licence, name: $name, nsfw: $nsfw, permanent_live: $permanent_live, previewfile: $previewfile, privacy: $privacy, save_replay: $save_replay, support: $support, tags: $tags, thumbnailfile: $thumbnailfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a live
#
# GET /api/v1/videos/live/{id}
# Returns: record<latencyMode: int, permanentLive: bool, rtmpUrl: string, rtmpsUrl: string, saveReplay: bool, streamKey: string>
# operationId: getLiveId
export def "get-live-id" [
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
    path: "/api/v1/videos/live/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information about a live
#
# PUT /api/v1/videos/live/{id}
# operationId: updateLiveId
export def "update-live-id" [
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
  --latency-mode: int@latency-mode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --permanent-live: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --save-replay: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/videos/live/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: latencyMode, var: latency_mode}, {name: permanentLive, var: permanent_live}, {name: saveReplay, var: save_replay}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, latency_mode: $latency_mode, permanent_live: $permanent_live, save_replay: $save_replay
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List live sessions
#
# GET /api/v1/videos/live/{id}/sessions
# Returns: record<data: table<endDate: string, error: int, id: int, replayVideo: record, startDate: string>, total: int>
export def "get-api-v1-videos-live-id-sessions" [
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
    path: "/api/v1/videos/live/{id}/sessions"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video ownership changes
#
# GET /api/v1/videos/ownership
export def "get-api-v1-videos-ownership" [
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
    path: "/api/v1/videos/ownership"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept ownership change request
#
# POST /api/v1/videos/ownership/{id}/accept
export def "post-api-v1-videos-ownership-id-accept" [
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
    method: post
    path: "/api/v1/videos/ownership/{id}/accept"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refuse ownership change request
#
# POST /api/v1/videos/ownership/{id}/refuse
export def "post-api-v1-videos-ownership-id-refuse" [
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
    method: post
    path: "/api/v1/videos/ownership/{id}/refuse"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available video privacy policies
#
# GET /api/v1/videos/privacies
# Returns: list<string>
# operationId: getPrivacyPolicies
export def "get-privacy-policies" [
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
    path: "/api/v1/videos/privacies"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a video
#
# POST /api/v1/videos/upload
# Returns: record<video: record<id: int, shortUUID: string, uuid: string>>
# operationId: uploadLegacy
export def "upload-legacy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  videofile: string # Video file (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/videos/upload"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: channelId, var: channel_id}, {name: commentsEnabled, var: comments_enabled}, {name: description, var: description}, {name: downloadEnabled, var: download_enabled}, {name: language, var: language}, {name: licence, var: licence}, {name: name, var: name}, {name: nsfw, var: nsfw}, {name: originallyPublishedAt, var: originally_published_at}, {name: previewfile, var: previewfile}, {name: privacy, var: privacy}, {name: scheduleUpdate, var: schedule_update}, {name: support, var: support}, {name: tags, var: tags}, {name: thumbnailfile, var: thumbnailfile}, {name: waitTranscoding, var: wait_transcoding}, {name: videofile, var: videofile}], files: [previewfile, thumbnailfile, videofile]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, channel_id: $channel_id, comments_enabled: $comments_enabled, description: $description, download_enabled: $download_enabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originally_published_at: $originally_published_at, previewfile: $previewfile, privacy: $privacy, schedule_update: $schedule_update, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, wait_transcoding: $wait_transcoding, videofile: $videofile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel the resumable upload of a video, deleting any data uploaded so far
#
# DELETE /api/v1/videos/upload-resumable
# operationId: uploadResumableCancel
export def "upload-resumable-cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last 12 hours, it is not valid anymore and the upload session has already been deleted with its data ;-) (required)
  --content-length: float # required, e.g. 0
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/videos/upload-resumable"
    query: [{name: upload_id, var: upload_id, required: true}]
    header: [{name: Content-Length, var: content_length, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    upload_id: $upload_id, content_length: $content_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initialize the resumable upload of a video
#
# POST /api/v1/videos/upload-resumable
# operationId: uploadResumableInit
export def "upload-resumable-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-upload-content-length: float # Number of bytes that will be uploaded in subsequent requests. Set this value to the size of the file you are uploading. (required, e.g. 2469036)
  --x-upload-content-type: string # MIME type of the file that you are uploading. Depending on your instance settings, acceptable values might vary. (required, format: mimetype, e.g. video/mp4)
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  filename: string # Video filename including extension (format: filename, e.g. what_is_peertube.mp4)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/videos/upload-resumable"
    header: [{name: X-Upload-Content-Length, var: x_upload_content_length, required: true}, {name: X-Upload-Content-Type, var: x_upload_content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}, {name: channelId, var: channel_id}, {name: commentsEnabled, var: comments_enabled}, {name: description, var: description}, {name: downloadEnabled, var: download_enabled}, {name: language, var: language}, {name: licence, var: licence}, {name: name, var: name}, {name: nsfw, var: nsfw}, {name: originallyPublishedAt, var: originally_published_at}, {name: previewfile, var: previewfile}, {name: privacy, var: privacy}, {name: scheduleUpdate, var: schedule_update}, {name: support, var: support}, {name: tags, var: tags}, {name: thumbnailfile, var: thumbnailfile}, {name: waitTranscoding, var: wait_transcoding}, {name: filename, var: filename}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    x_upload_content_length: $x_upload_content_length, x_upload_content_type: $x_upload_content_type, category: $category, channel_id: $channel_id, comments_enabled: $comments_enabled, description: $description, download_enabled: $download_enabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originally_published_at: $originally_published_at, previewfile: $previewfile, privacy: $privacy, schedule_update: $schedule_update, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, wait_transcoding: $wait_transcoding, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send chunk for the resumable upload of a video
#
# PUT /api/v1/videos/upload-resumable
# Returns: record<video: record<id: int, shortUUID: string, uuid: string>>
# operationId: uploadResumable
export def "upload-resumable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload. (required)
  --content-range: string # Specifies the bytes in the file that the request is uploading. For example, a value of `bytes 0-262143/1000000` shows that the request is sending the first 262144 bytes (256 x 1024) in a 2,469,036 byte file. (required, e.g. bytes 0-262143/2469036)
  --content-length: float # Size of the chunk that the request is sending. Remember that larger chunks are more efficient. PeerTube's web client uses chunks varying from 1048576 bytes (~1MB) and increases or reduces size depending on connection health. (required, e.g. 262144)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/videos/upload-resumable"
    query: [{name: upload_id, var: upload_id, required: true}]
    header: [{name: Content-Range, var: content_range, required: true}, {name: Content-Length, var: content_length, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 308]
    auth: bearer
  } {
    upload_id: $upload_id, content_range: $content_range, content_length: $content_length, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video
#
# DELETE /api/v1/videos/{id}
# operationId: delVideo
export def "del-video" [
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
    path: "/api/v1/videos/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a video
#
# GET /api/v1/videos/{id}
# Returns: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, blacklisted: bool, blacklistedReason: string, category: record<id: int, label: string>, channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, banners: list<record>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: int, isLive: bool, isLocal: bool, language: record<id: string, label: string>, licence: record<id: int, label: string>, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record<id: int, label: string>, publishedAt: string, scheduledUpdate: record<privacy: int, updateAt: string>, shortUUID: string, state: record<id: int, label: string>, thumbnailPath: string, updatedAt: string, userHistory: record<currentTime: int>, uuid: string, views: int, waitTranscoding: bool, commentsEnabled: bool, descriptionPath: string, downloadEnabled: bool, files: table<fileDownloadUrl: string, fileUrl: string, fps: float, id: int, magnetUri: string, metadataUrl: string, resolution: record, size: int, torrentDownloadUrl: string, torrentUrl: string>, streamingPlaylists: table<id: int, type: int, files: list, playlistUrl: string, redundancies: list, segmentsSha256Url: string>, support: string, tags: list<string>, trackerUrls: list<string>, viewers: int>
# operationId: getVideo
export def "get-video" [
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
    path: "/api/v1/videos/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a video
#
# PUT /api/v1/videos/{id}
# operationId: putVideo
export def "put-video" [
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
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --name: string # Video name
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: string # Whether or not we wait transcoding before publish the video
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/videos/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: commentsEnabled, var: comments_enabled}, {name: description, var: description}, {name: downloadEnabled, var: download_enabled}, {name: language, var: language}, {name: licence, var: licence}, {name: name, var: name}, {name: nsfw, var: nsfw}, {name: originallyPublishedAt, var: originally_published_at}, {name: previewfile, var: previewfile}, {name: privacy, var: privacy}, {name: scheduleUpdate, var: schedule_update}, {name: support, var: support}, {name: tags, var: tags}, {name: thumbnailfile, var: thumbnailfile}, {name: waitTranscoding, var: wait_transcoding}], files: [previewfile, thumbnailfile]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, category: $category, comments_enabled: $comments_enabled, description: $description, download_enabled: $download_enabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originally_published_at: $originally_published_at, previewfile: $previewfile, privacy: $privacy, schedule_update: $schedule_update, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, wait_transcoding: $wait_transcoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock a video by its id
#
# DELETE /api/v1/videos/{id}/blacklist
# operationId: delVideoBlock
export def "del-video-block" [
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
    path: "/api/v1/videos/{id}/blacklist"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block a video
#
# POST /api/v1/videos/{id}/blacklist
# operationId: addVideoBlock
export def "add-video-block" [
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
    method: post
    path: "/api/v1/videos/{id}/blacklist"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List captions of a video
#
# GET /api/v1/videos/{id}/captions
# Returns: record<data: table<captionPath: string, language: record>, total: int>
# operationId: getVideoCaptions
export def "get-video-captions" [
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
    path: "/api/v1/videos/{id}/captions"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video caption
#
# DELETE /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: delVideoCaption
export def "del-video-caption" [
  id: string
  caption_language: string
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
    path: "/api/v1/videos/{id}/captions/{captionLanguage}"
    path_params: [{name: id, var: id}, {name: captionLanguage, var: caption_language}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, caption_language: $caption_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or replace a video caption
#
# PUT /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: addVideoCaption
export def "add-video-caption" [
  id: string
  caption_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --captionfile: string # The file to upload. (format: binary)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/videos/{id}/captions/{captionLanguage}"
    path_params: [{name: id, var: id}, {name: captionLanguage, var: caption_language}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: captionfile, var: captionfile}], files: [captionfile]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, caption_language: $caption_language, captionfile: $captionfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List threads of a video
#
# GET /api/v1/videos/{id}/comment-threads
# Returns: record<data: table<account: record, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>, total: int>
export def "get-api-v1-videos-id-comment-threads" [
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
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --sort: string@sort-completer-8 # Sort comments by criteria
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos/{id}/comment-threads"
    path_params: [{name: id, var: id}]
    query: [{name: start, var: start}, {name: count, var: count}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start: $start, count: $count, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a thread
#
# POST /api/v1/videos/{id}/comment-threads
# Returns: record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>
export def "post-api-v1-videos-id-comment-threads" [
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
  text: string # Text of the comment (format: markdown)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/comment-threads"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a thread
#
# GET /api/v1/videos/{id}/comment-threads/{threadId}
# Returns: record<children: list<any>, comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>
export def "get-api-v1-videos-id-comment-threads-thread-id" [
  id: string
  thread_id: int
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
    path: "/api/v1/videos/{id}/comment-threads/{threadId}"
    path_params: [{name: id, var: id}, {name: threadId, var: thread_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, thread_id: $thread_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment or a reply
#
# DELETE /api/v1/videos/{id}/comments/{commentId}
export def "delete-api-v1-videos-id-comments-comment-id" [
  id: string
  comment_id: int
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
    path: "/api/v1/videos/{id}/comments/{commentId}"
    path_params: [{name: id, var: id}, {name: commentId, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply to a thread of a video
#
# POST /api/v1/videos/{id}/comments/{commentId}
# Returns: record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: string, updatedAt: string, url: string, description: string, displayName: string, userId: int>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: int, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>>
export def "post-api-v1-videos-id-comments-comment-id" [
  id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text of the comment (format: markdown)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/comments/{commentId}"
    path_params: [{name: id, var: id}, {name: commentId, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, comment_id: $comment_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get complete video description
#
# GET /api/v1/videos/{id}/description
# Returns: string
# operationId: getVideoDesc
export def "get-video-desc" [
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
    method: get
    path: "/api/v1/videos/{id}/description"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request ownership change
#
# POST /api/v1/videos/{id}/give-ownership
export def "post-api-v1-videos-id-give-ownership" [
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
  username: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/give-ownership"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete video HLS files
#
# DELETE /api/v1/videos/{id}/hls
# operationId: delVideoHLS
export def "del-video-hls" [
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
    path: "/api/v1/videos/{id}/hls"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get live session of a replay
#
# GET /api/v1/videos/{id}/live-session
# Returns: record<endDate: string, error: int, id: int, replayVideo: record<id: float, shortUUID: string, uuid: string>, startDate: string>
export def "get-api-v1-videos-id-live-session" [
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
    path: "/api/v1/videos/{id}/live-session"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like/dislike a video
#
# PUT /api/v1/videos/{id}/rate
export def "put-api-v1-videos-id-rate" [
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
  rating: string@rating-completer
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/videos/{id}/rate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rating, var: rating}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, rating: $rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get video source file metadata
#
# POST /api/v1/videos/{id}/source
# Returns: record<filename: string>
# operationId: getVideoSource
export def "get-video-source" [
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
    method: post
    path: "/api/v1/videos/{id}/source"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get overall stats of a video
#
# GET /api/v1/videos/{id}/stats/overall
# Returns: record<averageWatchTime: float, countries: table<isoCode: string, viewers: float>, totalWatchTime: float, viewersPeak: float, viewersPeakDate: string>
export def "get-api-v1-videos-id-stats-overall" [
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
  --start-date: string # Filter stats by start date (format: date-time)
  --end-date: string # Filter stats by end date (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos/{id}/stats/overall"
    path_params: [{name: id, var: id}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get retention stats of a video
#
# GET /api/v1/videos/{id}/stats/retention
# Returns: record<data: table<retentionPercent: float, second: float>>
export def "get-api-v1-videos-id-stats-retention" [
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
    path: "/api/v1/videos/{id}/stats/retention"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get timeserie stats of a video
#
# GET /api/v1/videos/{id}/stats/timeseries/{metric}
# Returns: record<data: table<date: string, value: float>>
export def "get-api-v1-videos-id-stats-timeseries-metric" [
  id: string
  metric: string@metric-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Filter stats by start date (format: date-time)
  --end-date: string # Filter stats by end date (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/videos/{id}/stats/timeseries/{metric}"
    path_params: [{name: id, var: id}, {name: metric, var: metric}]
    query: [{name: startDate, var: start_date}, {name: endDate, var: end_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, metric: $metric, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a studio task
#
# POST /api/v1/videos/{id}/studio/edit
export def "post-api-v1-videos-id-studio-edit" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/studio/edit"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request video token
#
# POST /api/v1/videos/{id}/token
# Returns: record<files: record<expires: string, token: string>>
# operationId: requestVideoToken
export def "request-video-token" [
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
    method: post
    path: "/api/v1/videos/{id}/token"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transcoding job
#
# POST /api/v1/videos/{id}/transcoding
# operationId: createVideoTranscoding
export def "create-video-transcoding" [
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
  transcoding_type: string@transcoding-type-completer
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/transcoding"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: transcodingType, var: transcoding_type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, transcoding_type: $transcoding_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notify user is watching a video
#
# POST /api/v1/videos/{id}/views
# operationId: addView
export def "add-view" [
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
  current_time: int # timestamp within the video, in seconds (format: seconds, e.g. 5)
  --view-event: string@view-event-completer # Event since last viewing call: * `seek` - If the user seeked the video
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/videos/{id}/views"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentTime, var: current_time}, {name: viewEvent, var: view_event}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, current_time: $current_time, view_event: $view_event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set watching progress of a video
#
# PUT /api/v1/videos/{id}/watching
# DEPRECATED
@deprecated
export def "put-api-v1-videos-id-watching" [
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
  current_time: int # timestamp within the video, in seconds (format: seconds, e.g. 5)
  --view-event: string@view-event-completer # Event since last viewing call: * `seek` - If the user seeked the video
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/videos/{id}/watching"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentTime, var: current_time}, {name: viewEvent, var: view_event}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, current_time: $current_time, view_event: $view_event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete video WebTorrent files
#
# DELETE /api/v1/videos/{id}/webtorrent
# operationId: delVideoWebTorrent
export def "del-video-web-torrent" [
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
    path: "/api/v1/videos/{id}/webtorrent"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videos of subscriptions tied to a token
#
# GET /feeds/subscriptions.{format}
# Returns: record
# operationId: getSyndicatedSubscriptionVideos
export def "get-syndicated-subscription-videos" [
  format: string@format-completer
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
  --account-id: string # limit listing to a specific account (required)
  --qp-token: string # private token allowing access (required) (spec name: token)
  --sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/feeds/subscriptions.{format}"
    path_params: [{name: format, var: format}]
    query: [{name: accountId, var: account_id, required: true}, {name: token, var: qp_token, required: true}, {name: sort, var: sort}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}]
    accept: ["application/atom+xml", "application/json", "application/rss+xml", "application/xml", "text/xml"]
    ok: [204]
    auth: bearer
  } {
    format: $format, account_id: $account_id, qp_token: $qp_token, sort: $sort, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List comments on videos
#
# GET /feeds/video-comments.{format}
# Returns: record
# operationId: getSyndicatedComments
export def "get-syndicated-comments" [
  format: string@format-completer
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
  --video-id: string # limit listing to a specific video
  --account-id: string # limit listing to a specific account
  --account-name: string # limit listing to a specific account
  --video-channel-id: string # limit listing to a specific video channel
  --video-channel-name: string # limit listing to a specific video channel
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/feeds/video-comments.{format}"
    path_params: [{name: format, var: format}]
    query: [{name: videoId, var: video_id}, {name: accountId, var: account_id}, {name: accountName, var: account_name}, {name: videoChannelId, var: video_channel_id}, {name: videoChannelName, var: video_channel_name}]
    accept: ["application/atom+xml", "application/json", "application/rss+xml", "application/xml", "text/xml"]
    ok: [204]
    auth: bearer
  } {
    format: $format, video_id: $video_id, account_id: $account_id, account_name: $account_name, video_channel_id: $video_channel_id, video_channel_name: $video_channel_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List videos
#
# GET /feeds/videos.{format}
# Returns: record
# operationId: getSyndicatedVideos
export def "get-syndicated-videos" [
  format: string@format-completer
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
  --account-id: string # limit listing to a specific account
  --account-name: string # limit listing to a specific account
  --video-channel-id: string # limit listing to a specific video channel
  --video-channel-name: string # limit listing to a specific video channel
  --sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/feeds/videos.{format}"
    path_params: [{name: format, var: format}]
    query: [{name: accountId, var: account_id}, {name: accountName, var: account_name}, {name: videoChannelId, var: video_channel_id}, {name: videoChannelName, var: video_channel_name}, {name: sort, var: sort}, {name: nsfw, var: nsfw}, {name: isLocal, var: is_local}, {name: include, var: include}, {name: privacyOneOf, var: privacy_one_of}, {name: hasHLSFiles, var: has_hls_files}, {name: hasWebtorrentFiles, var: has_webtorrent_files}]
    accept: ["application/atom+xml", "application/json", "application/rss+xml", "application/xml", "text/xml"]
    ok: [204]
    auth: bearer
  } {
    format: $format, account_id: $account_id, account_name: $account_name, video_channel_id: $video_channel_id, video_channel_name: $video_channel_name, sort: $sort, nsfw: $nsfw, is_local: $is_local, include: $include, privacy_one_of: $privacy_one_of, has_hls_files: $has_hls_files, has_webtorrent_files: $has_webtorrent_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get private HLS video file
#
# GET /static/streaming-playlists/hls/private/{filename}
export def "get-static-streaming-playlists-hls-private-filename" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-file-token: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
  --reinject-video-file-token: oneof<nothing, bool> # Ask the server to reinject videoFileToken in URLs in m3u8 playlist
]: nothing -> any {
  http-request {
    method: get
    path: "/static/streaming-playlists/hls/private/{filename}"
    path_params: [{name: filename, var: filename}]
    query: [{name: videoFileToken, var: video_file_token}, {name: reinjectVideoFileToken, var: reinject_video_file_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename, video_file_token: $video_file_token, reinject_video_file_token: $reinject_video_file_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public HLS video file
#
# GET /static/streaming-playlists/hls/{filename}
export def "get-static-streaming-playlists-hls-filename" [
  filename: string
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
    path: "/static/streaming-playlists/hls/{filename}"
    path_params: [{name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get private WebTorrent video file
#
# GET /static/webseed/private/{filename}
export def "get-static-webseed-private-filename" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-file-token: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
]: nothing -> any {
  http-request {
    method: get
    path: "/static/webseed/private/{filename}"
    path_params: [{name: filename, var: filename}]
    query: [{name: videoFileToken, var: video_file_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename, video_file_token: $video_file_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public WebTorrent video file
#
# GET /static/webseed/{filename}
export def "get-static-webseed-filename" [
  filename: string
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
    path: "/static/webseed/{filename}"
    path_params: [{name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
