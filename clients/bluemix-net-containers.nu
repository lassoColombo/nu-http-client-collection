# Auto-generated client for IBM Containers API v3.0.0
# Source: https://api.apis.guru/v2/specs/bluemix.net/containers/3.0.0/openapi.json
# Auth: --token flag or $env.IBM_CONTAINERS_API_TOKEN

const CLIENT = {
  base_url: "https://containers-api.ng.bluemix.net/v3"
  token_env_var: "IBM_CONTAINERS_API_TOKEN"
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

def base-url-completer [] { ["https://containers-api.ng.bluemix.net/v3"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-containers-create: "record<Id: string, flavor_id: int, mem: int, vcpu: int>"
    get-containers-floating-ips: "table<Bindings: record<ContainerId: string>, IpAddress: string>"
    post-containers-floating-ips-request: "string"
    get-containers-groups: "table<Creation_time: string, Id: string, Name: string, Port: int, Routes: list<string>, Status: string, Updated_time: string>"
    post-containers-groups: "record<Id: string, Warnings: list<string>>"
    get-containers-groups-name-or-id: "record<Anti-affinity: string, Autorecovery: string, AvailabilityZone: string, Cmd: list<string>, Creation_time: string, Env: list<string>, Id: string, Image: string, ImageName: string, Memory: int, Name: string, NumberInstances: record<CurrentSize: int, Desired: int, Max: int, Min: int>, Port: int, Route_Status: record<in_progress: bool, message: string, successful: bool>, Routes: list<string>, Status: string, UpdatedTime: string, Volumes: list<string>>"
    post-containers-groups-name-or-id-maproute: "record<Id: string, Warnings: list<string>>"
    post-containers-groups-name-or-id-unmaproute: "record<Id: string, Warnings: list<string>>"
    get-containers-json: "table<Command: string, ContainerState: string, Created: float, Env: list<string>, Group: record<Id: string, Name: string>, Id: string, Image: string, ImageId: string, Labels: record, Memory: int, Name: string, Names: list<string>, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record, PortMapping: string, Ports: list, PublicIpAddress: string>, Ports: record<IP: string, PrivatePort: string, PublicPort: string, Type: string>, SizeRootFs: int, SizeRw: int, Started: float, Status: string, VCPU: int>"
    get-containers-messages: "record<created_date: string, message: string>"
    get-containers-quota: "record<account_type: string, country_code: string, org_quota: record<floating_ips_max: string, floating_ips_space_default: string, floating_ips_usage: int, ram_max: int, ram_space_default: int, ram_usage: int, subnet_usage: int, subnets_default: int, subnets_max: int>, space_quota: record<floating_ips_max: string, ram_max: int, subnets_max: int>>"
    get-containers-usage: "record<AvailableSizes: table<disk: int, id: string, memory_MB: int, name: string, vcpus: int>, Environment: string, Limits: record<containers: int, floating_ips: int, memory_MB: int, vcpu: int>, Usage: record<containers: int, floating_ips: int, floating_ips_bound: int, images: int, memory_MB: int, running: int, vcpu: int>>"
    get-containers-version: "record<ApiVersion: string, Arch: string, BuildDetail: record<api: string, automount: string, grupdater: string, harmony: string, health-monitor: string, hijack: string, ldap: string, logmet: string, lumberjack: string, redis-cluster: string, sgwatcher: string, volmgr: string>, BuildID: string, BuildNumber: string, BuildTime: string, GitCommit: string, GoVersion: string, KernelVersion: string, Os: string, Version: string>"
    get-containers-id-status: "record<NameOrId: string, Status: string, Transient: bool>"
    get-containers-name-or-id-json: "record<BluemixApp: string, BluemixServices: string, Config: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, ContainerState: string, Created: string, Group: record<Id: string, Name: string>, HostConfig: record<Binds: list<string>, ExtraHosts: list<string>, Links: list<string>, PortBindings: list<string>>, HostId: string, Human_Id: string, Id: string, Image: string, Mounts: list<string>, Name: string, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record<Aliases: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, IPAMConfig: string, IPPrefixLen: string, IPv6Gateway: string, Links: string, MacAddress: string, NetworkID: string>, PortMapping: string, Ports: list<string>, PublicIpAddress: string>, Path: string, ResolveConfPath: string, State: record<ExitCode: string, FinishedAt: string, Ghost: string, Pid: int, Running: bool, StartedAt: string, Status: string>, Volumes: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>, VolumesRW: list<string>>"
    get-images-json: "record<Created: float, Id: string, Image: string, RepoTags: list<string>, Size: int, VirtualSize: int>"
    get-images-name-or-id-json: "record<Architecture: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainmame: string, Entrypoint: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, Labels: list<string>, OnBuild: list<string>, OpenStdin: bool, StdinOnce: bool, Tty: bool, User: string, Volumes: string, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, Created: string, DockerVersion: string, Id: string, Os: string, Parent: string, Size: int, Tag: string, Throwaway: string, VirtualSize: int>"
    get-registry-namespaces: "record<namespace: string>"
    get-registry-namespaces-namespace: "record<namespace: string>"
    put-registry-namespaces-namespace: "record<namespace: string>"
    get-tlskey: "record<ca_cert: string, server_cert: string, user_cert: string, user_key: string>"
    put-tlskey-refresh: "record<ca_cert: string, reg_host: string, server_cert: string, user_cert: string, user_key: string>"
    post-volumes-create: "record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>"
    get-volumes-fs-flavors-json: "list<int>"
    get-volumes-fs-json: "table<capacity: int, created_date: string, fsName: string, hostPath: string, iops: float, iopsTotal: int, orderId: string, provider: string, spaceGuid: string, state: string, updated_date: string>"
    get-volumes-fs-name-json: "table<fs: list<record>, fsUsage: list<record>, volnames: list<string>>"
    get-volumes-json: "table<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>"
    post-volumes-name: "record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>"
    get-volumes-name-json: "record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-build" "post-containers-create" "get-containers-floating-ips" "post-containers-floating-ips-request" "post-containers-floating-ips-ip-release" "get-containers-groups" "post-containers-groups" "delete-containers-groups-name-or-id" "get-containers-groups-name-or-id" "patch-containers-groups-name-or-id" "post-containers-groups-name-or-id-maproute" "post-containers-groups-name-or-id-unmaproute" "get-containers-json" "get-containers-messages" "get-containers-quota" "put-containers-quota" "get-containers-usage" "get-containers-version" "get-containers-id-status" "delete-containers-name-or-id" "post-containers-name-or-id-floating-ips-ip-bind" "post-containers-name-or-id-floating-ips-ip-unbind" "get-containers-name-or-id-json" "post-containers-name-or-id-pause" "post-containers-name-or-id-rename" "post-containers-name-or-id-restart" "post-containers-name-or-id-start" "post-containers-name-or-id-stop" "post-containers-name-or-id-unpause" "get-images-json" "delete-images-id" "get-images-name-or-id-json" "get-registry-namespaces" "get-registry-namespaces-namespace" "put-registry-namespaces-namespace" "get-tlskey" "put-tlskey-refresh" "post-volumes-create" "post-volumes-fs-create" "get-volumes-fs-flavors-json" "get-volumes-fs-json" "delete-volumes-fs-name" "get-volumes-fs-name-json" "get-volumes-json" "delete-volumes-name" "post-volumes-name" "get-volumes-name-json" "commands"] | sort) } | get name | first)
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

# Build a Docker image from a Dockerfile
#
# POST /build
export def "post-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: string # Tag the image with the full path to your private Bluemix registry in the following format: `t=registry.ng.bluemix.net//<image_name>:`. This path is used to push the image to the private Bluemix registry after it is built. (required)
  --q: oneof<nothing, bool> # You can choose whether or not to show the verbose build output to review every step during the container image build. If you set the query parameter to `q=false`, `q=False`, or `q=0`, the verbose build output is suppressed. To show the verbose build output, enter `q=true`, `q=True`, or `q=1`.
  --nocache: oneof<nothing, bool> # If you set the query parameter to `nocache=true`, `nocache=True`, or `nocache=1`, the cache will not be used to build your image. To use the cache, enter `nocache=false`, `nocache=False`, or `nocache=0`.
  --pull: oneof<nothing, bool> # If set to pull=true, pull=True, or pull=1, then a newer version of the image is always attempted to be pulled even though an older version of the image exists locally. If set to pull=false, pull=False, or pull=0, then the local image will be used if one exists.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/build"
    query: [{name: t, var: t, required: true}, {name: q, var: q}, {name: nocache, var: nocache}, {name: pull, var: pull}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/tar", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    t: $t, q: $q, nocache: $nocache, pull: $pull, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and start a single container
#
# POST /containers/create
# Returns: record<Id: string, flavor_id: int, mem: int, vcpu: int>
export def "post-containers-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Choose a name for your container. The characters in the name can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-), but the name must start with a letter.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --bluemix-app: string # The name of the Cloud Foundry app that you want to bind to your container. The Cloud Foundry app must be created in the same space where you want to create your container.
  --cmd: list<string> # The command and arguments in this list are passed to the container to be executed when the container is started. This command must be a long-running command. Do not use a short-lived command, for example, /bin/date, because it might cause the container to crash. Sample long-running commands:["ping","localhost"]["tail","-f","/dev/null"]["sh","-c","while true; do date; sleep 20; done"]
  --cpuset: string # Pins the container processes to a specific CPU core on the compute host. For example: 0 means that processes are executed on the first core only.
  --body-env: list<string> # A list of environment variables in the form of key=value pairs. All keys in this list have to be unique. List multiple keys separately and if you include quotation marks, include them around both the environment variable name and the value. (spec name: Env)
  --exposed-ports: list<string> # All public ports that need to be exposed for the container, so the container can be accessed from the Internet.
  --host-config: record # shape: {Binds?: list<string>, ExtraHosts?: list<string>, Links?: list<string>, PortBindings?: list<string>}
  image: string # Full path to the image in your private Bluemix registry in the format `registry.ng.bluemix.net/namespace/image`.
  --memory: int # The container memory that is set for the container in Megabyte. Choose one of the following sizes: Pico 64 MB, Nano 128 MB, Micro 256 MB, Tiny 512 MB, Small 1 GB (1024 MB), Medium 2 GB (2048 MB), Large 4 GB (4096 MB) XLarge 8GB (8192 MB) and 2XLarge 16 GB (16384 MB). (format: int32)
  --number-cpus: int # Number of virtual CPUs that are allocated to the container. (format: int32)
  --volumes: string # Mount a volume to a container by specifying the details in the following format: `VOLUME_NAME:/DIRECTORY_PATH[:ro]`. Example: testvolume:/volumedata/temp:rw. By default, all volumes will be set up with read-write access inside the container (rw). If you wish to set up your volume with read-only access, enter `ro`. Note: To mount a volume to a container, you must create the volume in your space first by using the `cf ic volume-create` command, or calling the `POST /volumes/create endpoint`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/create"
    query: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: BluemixApp, var: bluemix_app}, {name: Cmd, var: cmd}, {name: Cpuset, var: cpuset}, {name: Env, var: body_env}, {name: ExposedPorts, var: exposed_ports}, {name: HostConfig, var: host_config}, {name: Image, var: image}, {name: Memory, var: memory}, {name: NumberCpus, var: number_cpus}, {name: Volumes, var: volumes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, bluemix_app: $bluemix_app, cmd: $cmd, cpuset: $cpuset, body_env: $body_env, exposed_ports: $exposed_ports, host_config: $host_config, image: $image, memory: $memory, number_cpus: $number_cpus, volumes: $volumes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available public IP addresses in a space
#
# GET /containers/floating-ips
# Returns: table<Bindings: record<ContainerId: string>, IpAddress: string>
export def "get-containers-floating-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If this option is set to `all=1`, `all=True`, or `all=true`, all public IP addresses that are allocated to a space are returned. If this option is set to `all=0`, `all=False`, or `all=false`, only available public IP addresses that are allocated but not bound to a container are returned. By default, only available public IP addresses are returned.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/containers/floating-ips"
    query: [{name: all, var: all}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    all: $all, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a public IP address for a space
#
# POST /containers/floating-ips/request
# Returns: string
export def "post-containers-floating-ips-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/floating-ips/request"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Release public IP address
#
# POST /containers/floating-ips/{ip}/release
export def "post-containers-floating-ips-ip-release" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/floating-ips/{ip}/release"
    path_params: [{name: ip, var: ip}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ip: $ip, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all container groups in a space
#
# GET /containers/groups
# Returns: table<Creation_time: string, Id: string, Name: string, Port: int, Routes: list<string>, Status: string, Updated_time: string>
export def "get-containers-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/containers/groups"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and start a container group.
#
# POST /containers/groups
# Returns: record<Id: string, Warnings: list<string>>
export def "post-containers-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --autorecovery: string # (Optional) Enable the Auto-recovery mode for your container group. If set to true, IBM Containers checks the health of each instance with an HTTP request to the port that is assigned. If the health check does not receive a TCP response from a container instance in two subsequent 90-second intervals, the instance is removed and replaced with a new instance. If set to false and container instances crash, they are not recovered by IBM Containers.
  --bluemix-app: string # (Optional) The name of the Cloud Foundry app that you created in your organization space.
  --cmd: list<string> # (Optional) Docker command that is passed to the container group to be run when the container instances are started. This command must be a long-running command. Do not use a short-lived command, for example, /bin/date, because it might cause the container to crash.
  --body-env: list<string> # (Optional) List of environmental variables. Every environment variable that is listed here needs to be a key=value pair. Every key that you use needs to be unique for this container group. Multiple environment variables are separated with comma (,). (spec name: Env)
  image: string # (Required) The full path to your private Bluemix repository. If you want to use an image in your private Bluemix repository, specify the image in the following format: registry.ng.bluemix.net/NAMESPACE/IMAGE. If you want to use an IBM Containers provided image, do not include your organization's namespace. Specify the image in the following format: registry.ng.bluemix.net/IMAGE
  --memory: int # (Optional) The size of each container instance in the container group. The size of each container instance in the group. Choose one of the following sizes and enter the size in MegaBytes: Pico 64 MB, Nano 128 MB, Micro 256 MB, Tiny 512 MB, Small 1 GB (1024 MB), Medium 2 GB (2048 MB), Large 4 GB (4096 MB) XLarge 8GB (8192 MB) and 2XLarge 16 GB (16384 MB). If you do not specify a size, all container instances in this group are created with 256 MB. (format: int32)
  name: string # (Required) Name of the container group that you want to create. The name needs to be unique in your organization space and must start with a letter. Then, you can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-).
  --number-instances: record # shape: {Desired?: int, Max?: int, Min?: int}
  --port: int # (Optional) Expose a port for HTTP traffic to make your container group available from the Internet. Every container instance that is started for this group, listens on this port. Container groups cannot expose multiple ports. Note: You need to expose a port, when "Autorecovery" is set to true. (format: int32)
  --route: record # shape: {domain?: string, host?: string}
  --volumes: list<string> # (Optional) List of volumes to be mounted to the container instances of your container group. You need to create the volume first by using the cf ic volume-create command before you can mount a volume to a container group. When you specify a volume, use the following format: NAME:PATH:MODE. For NAME, use either the name or ID of the volume. For the PATH, enter the absolute path to the volume directory in the container. For MODE, enter either ro (read-only) or rw (read-write).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/groups"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Autorecovery, var: autorecovery}, {name: BluemixApp, var: bluemix_app}, {name: Cmd, var: cmd}, {name: Env, var: body_env}, {name: Image, var: image}, {name: Memory, var: memory}, {name: Name, var: name}, {name: NumberInstances, var: number_instances}, {name: Port, var: port}, {name: Route, var: route}, {name: Volumes, var: volumes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, autorecovery: $autorecovery, bluemix_app: $bluemix_app, cmd: $cmd, body_env: $body_env, image: $image, memory: $memory, name: $name, number_instances: $number_instances, port: $port, route: $route, volumes: $volumes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop and delete all container instances in a container group.
#
# DELETE /containers/groups/{name_or_id}
export def "delete-containers-groups-name-or-id" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: string # If you want to force the deletion of a container group that has running container instances, use the force option. This parameter needs to be set to either true or false. If set to `force=true`, `force=True`, or `force=1`, running container instances are deleted. If set to `force=false`, `force=False`, or `force=0`, running container instances are not deleted. If you do not specify this paramater, running container instances are not deleted by default.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/containers/groups/{name_or_id}"
    path_params: [{name: name_or_id, var: name_or_id}]
    query: [{name: force, var: force}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, force: $force, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a container group.
#
# GET /containers/groups/{name_or_id}
# Returns: record<Anti-affinity: string, Autorecovery: string, AvailabilityZone: string, Cmd: list<string>, Creation_time: string, Env: list<string>, Id: string, Image: string, ImageName: string, Memory: int, Name: string, NumberInstances: record<CurrentSize: int, Desired: int, Max: int, Min: int>, Port: int, Route_Status: record<in_progress: bool, message: string, successful: bool>, Routes: list<string>, Status: string, UpdatedTime: string, Volumes: list<string>>
export def "get-containers-groups-name-or-id" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/groups/{name_or_id}"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a container group.
#
# PATCH /containers/groups/{name_or_id}
export def "patch-containers-groups-name-or-id" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --autorecovery: string # Enable or disable the Autorecovery mode for your container group. To enable it, enter true. If you want to disable it, enter false. Note: You can only enable/ disable Autorecovery mode if your container group was initially created with Autorecovery mode enabled.
  --environment: list<string> # A list of environment variables that you want to add to your container group. Every environment variable needs to be a key=value pair. Every key that you use needs to be unique for this container group. Multiple environment variables are separated with comma (,)
  --number-instances: record # shape: {Desired?: int, Max?: int, Min?: int}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/containers/groups/{name_or_id}"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Autorecovery, var: autorecovery}, {name: Environment, var: environment}, {name: NumberInstances, var: number_instances}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, autorecovery: $autorecovery, environment: $environment, number_instances: $number_instances
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map a public route to a container group.
#
# POST /containers/groups/{name_or_id}/maproute
# Returns: record<Id: string, Warnings: list<string>>
export def "post-containers-groups-name-or-id-maproute" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --domain: string # The default system domain is mybluemix.net and already provides a SSL certificate, so you can access your container groups with HTTPS without any additional configuration.
  --host: string # The host name of your container group, such as mycontainerhost. Do not include underscores (_) in the host name. The host and the domain combined form the full public route URL, such as http://mycontainerhost.mybluemix.net.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/groups/{name_or_id}/maproute"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: host, var: host}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, domain: $domain, host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmap a public route from a container group
#
# POST /containers/groups/{name_or_id}/unmaproute
# Returns: record<Id: string, Warnings: list<string>>
export def "post-containers-groups-name-or-id-unmaproute" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --domain: string # The default system domain is mybluemix.net and already provides a SSL certificate, so you can access your container groups with HTTPS without any additional configuration.
  --host: string # The host name of your container group, such as mycontainerhost. Do not include underscores (_) in the host name. The host and the domain combined form the full public route URL, such as http://mycontainerhost.mybluemix.net.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/groups/{name_or_id}/unmaproute"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: host, var: host}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, domain: $domain, host: $host
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List single containers in a space.
#
# GET /containers/json
# Returns: table<Command: string, ContainerState: string, Created: float, Env: list<string>, Group: record<Id: string, Name: string>, Id: string, Image: string, ImageId: string, Labels: record, Memory: int, Name: string, Names: list<string>, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record, PortMapping: string, Ports: list, PublicIpAddress: string>, Ports: record<IP: string, PrivatePort: string, PublicPort: string, Type: string>, SizeRootFs: int, SizeRw: int, Started: float, Status: string, VCPU: int>
export def "get-containers-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # By default, the `GET /containers/json` endpoint returns a list of all single containers in a space that are in a running state. To request a list of all containers independent of their current state, set the `all` query parameter to true. Allowed values are: `all=true`, `all=True`, and `all=1`.
  --filters: string # You can filter your containers by any environment variable key or value that is listed in the `Env` section of your CLI/ API response when you run the `cf ic inspect ` command, or call the `GET /containers/{id}/json` endpoint. Your search criteria does not need to be an exact match. It can also be a part of the key or value you are looking for. For example, to filter all containers with an environment variable that contains `id` in one of their environment variables, use `filter=id`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/containers/json"
    query: [{name: all, var: all}, {name: filters, var: filters}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    all: $all, filters: $filters, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List messages for the user
#
# GET /containers/messages
# Returns: record<created_date: string, message: string>
export def "get-containers-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. To retrieve your space ID, run `cf space <space_name> --guid` and replace `<space_name>` with the name of the space where you want to create or work with your container. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/messages"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve organization and space specific quota
#
# GET /containers/quota
# Returns: record<account_type: string, country_code: string, org_quota: record<floating_ips_max: string, floating_ips_space_default: string, floating_ips_usage: int, ram_max: int, ram_space_default: int, ram_usage: int, subnet_usage: int, subnets_default: int, subnets_max: int>, space_quota: record<floating_ips_max: string, ram_max: int, subnets_max: int>>
export def "get-containers-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/quota"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update space quota
#
# PUT /containers/quota
export def "put-containers-quota" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --floating-ips: int # The new number of public IP addresses that you want to assign to your space. (format: int32)
  --ram: int # The amount of container memory that you want to assign to your space. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/containers/quota"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: floating_ips, var: floating_ips}, {name: ram, var: ram}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, floating_ips: $floating_ips, ram: $ram
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List container sizes and quota limits
#
# GET /containers/usage
# Returns: record<AvailableSizes: table<disk: int, id: string, memory_MB: int, name: string, vcpus: int>, Environment: string, Limits: record<containers: int, floating_ips: int, memory_MB: int, vcpu: int>, Usage: record<containers: int, floating_ips: int, floating_ips_bound: int, images: int, memory_MB: int, running: int, vcpu: int>>
export def "get-containers-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/usage"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List latest API version
#
# GET /containers/version
# Returns: record<ApiVersion: string, Arch: string, BuildDetail: record<api: string, automount: string, grupdater: string, harmony: string, health-monitor: string, hijack: string, ldap: string, logmet: string, lumberjack: string, redis-cluster: string, sgwatcher: string, volmgr: string>, BuildID: string, BuildNumber: string, BuildTime: string, GitCommit: string, GoVersion: string, KernelVersion: string, Os: string, Version: string>
export def "get-containers-version" [
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
    path: "/containers/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the current state of a container.
#
# GET /containers/{id}/status
# Returns: record<NameOrId: string, Status: string, Transient: bool>
export def "get-containers-id-status" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{id}/status"
    path_params: [{name: id, var: id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a single container
#
# DELETE /containers/{name_or_id}
export def "delete-containers-name-or-id" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Use the `force` query parameter if you want to delete the container independent of their current state. The container does not need to be stopped first. To force the deletion of a container, enter `force=true`, `force=True`, or `force=1`. If you want to delete containers that are in a non-running state only, do either not set this query parameter, or enter `force=false`, `force=False`, or `force=0`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/containers/{name_or_id}"
    path_params: [{name: name_or_id, var: name_or_id}]
    query: [{name: force, var: force}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, force: $force, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bind a public IP address to a single container
#
# POST /containers/{name_or_id}/floating-ips/{ip}/bind
export def "post-containers-name-or-id-floating-ips-ip-bind" [
  name_or_id: string
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/floating-ips/{ip}/bind"
    path_params: [{name: name_or_id, var: name_or_id}, {name: ip, var: ip}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    name_or_id: $name_or_id, ip: $ip, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unbind a public IP address from a container
#
# POST /containers/{name_or_id}/floating-ips/{ip}/unbind
export def "post-containers-name-or-id-floating-ips-ip-unbind" [
  name_or_id: string
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/floating-ips/{ip}/unbind"
    path_params: [{name: name_or_id, var: name_or_id}, {name: ip, var: ip}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, ip: $ip, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a single container
#
# GET /containers/{name_or_id}/json
# Returns: record<BluemixApp: string, BluemixServices: string, Config: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, ContainerState: string, Created: string, Group: record<Id: string, Name: string>, HostConfig: record<Binds: list<string>, ExtraHosts: list<string>, Links: list<string>, PortBindings: list<string>>, HostId: string, Human_Id: string, Id: string, Image: string, Mounts: list<string>, Name: string, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record<Aliases: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, IPAMConfig: string, IPPrefixLen: string, IPv6Gateway: string, Links: string, MacAddress: string, NetworkID: string>, PortMapping: string, Ports: list<string>, PublicIpAddress: string>, Path: string, ResolveConfPath: string, State: record<ExitCode: string, FinishedAt: string, Ghost: string, Pid: int, Running: bool, StartedAt: string, Status: string>, Volumes: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>, VolumesRW: list<string>>
export def "get-containers-name-or-id-json" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{name_or_id}/json"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause a single container
#
# POST /containers/{name_or_id}/pause
export def "post-containers-name-or-id-pause" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/pause"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a single container
#
# POST /containers/{name_or_id}/rename
export def "post-containers-name-or-id-rename" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the container. The characters in the name can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-), but the name must start with a letter. (required)
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/rename"
    path_params: [{name: name_or_id, var: name_or_id}]
    query: [{name: name, var: name, required: true}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart a single container
#
# POST /containers/{name_or_id}/restart
export def "post-containers-name-or-id-restart" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # The number of seconds to wait before the container is restarted. For example, if you want a container to restart after 10 seconds, enter `t=10`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/restart"
    path_params: [{name: name_or_id, var: name_or_id}]
    query: [{name: t, var: t}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    name_or_id: $name_or_id, t: $t, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a single container
#
# POST /containers/{name_or_id}/start
export def "post-containers-name-or-id-start" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/start"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a single container
#
# POST /containers/{name_or_id}/stop
export def "post-containers-name-or-id-stop" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # The number of seconds to wait before the container is stopped. For example, if you want a container to stop after 10 seconds, enter `t=10`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/stop"
    path_params: [{name: name_or_id, var: name_or_id}]
    query: [{name: t, var: t}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    name_or_id: $name_or_id, t: $t, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpause a single container
#
# POST /containers/{name_or_id}/unpause
export def "post-containers-name-or-id-unpause" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{name_or_id}/unpause"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Docker images that are available in your private Bluemix registry.
#
# GET /images/json
# Returns: record<Created: float, Id: string, Image: string, RepoTags: list<string>, Size: int, VirtualSize: int>
export def "get-images-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/json"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Docker image.
#
# DELETE /images/{id}
export def "delete-images-id" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a Docker image in private Bluemix registry
#
# GET /images/{name_or_id}/json
# Returns: record<Architecture: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainmame: string, Entrypoint: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, Labels: list<string>, OnBuild: list<string>, OpenStdin: bool, StdinOnce: bool, Tty: bool, User: string, Volumes: string, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, Created: string, DockerVersion: string, Id: string, Os: string, Parent: string, Size: int, Tag: string, Throwaway: string, VirtualSize: int>
export def "get-images-name-or-id-json" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{name_or_id}/json"
    path_params: [{name: name_or_id, var: name_or_id}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name_or_id: $name_or_id, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the namespace of an organization.
#
# GET /registry/namespaces
# Returns: record<namespace: string>
export def "get-registry-namespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/namespaces"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the availability of a namespace
#
# GET /registry/namespaces/{namespace}
# Returns: record<namespace: string>
export def "get-registry-namespaces-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registry/namespaces/{namespace}"
    path_params: [{name: namespace, var: namespace}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a namespace for your private Bluemix registry.
#
# PUT /registry/namespaces/{namespace}
# Returns: record<namespace: string>
export def "put-registry-namespaces-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/registry/namespaces/{namespace}"
    path_params: [{name: namespace, var: namespace}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    namespace: $namespace, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the TLS Certificate
#
# GET /tlskey
# Returns: record<ca_cert: string, server_cert: string, user_cert: string, user_key: string>
export def "get-tlskey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tlskey"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh the TLS Certificate
#
# PUT /tlskey/refresh
# Returns: record<ca_cert: string, reg_host: string, server_cert: string, user_cert: string, user_key: string>
export def "put-tlskey-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/tlskey/refresh"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a volume in a space
#
# POST /volumes/create
# Returns: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>
export def "post-volumes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the volume. The name must be unique for a space and can contain uppercase letters, lowercase letters, numbers, underscores (_), and hyphens (-). (required)
  --fs-name: string # The name of the file share that the volume is hosted on. File shares can have different storage sizes and IOPS based on the required workload. If this field is left blank, the volume is hosted on the default file share.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/volumes/create"
    query: [{name: name, var: name, required: true}, {name: fsName, var: fs_name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, fs_name: $fs_name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a file share in a space
#
# POST /volumes/fs/create
export def "post-volumes-fs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  fs_iops: float # The number of input/output transactions per second. Available values are 0.25, 2 or 4. (format: double)
  fs_name: string # The name of the new file share that you want to create. The name can contain uppercase letters, lowercase letters, numbers, underscores (_), and hyphens (-).
  fs_size: int # The size of the file share in gigabyte. Run `cf ic volume fs-flavor-list` or call the GET /volumes/fs/flavors/json API endpoint to retrieve a list of available file share sizes.
]: any -> any {
  $in | http-request {
    method: post
    path: "/volumes/fs/create"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: fsIOPS, var: fs_iops}, {name: fsName, var: fs_name}, {name: fsSize, var: fs_size}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, fs_iops: $fs_iops, fs_name: $fs_name, fs_size: $fs_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available file share sizes
#
# GET /volumes/fs/flavors/json
# Returns: list<int>
export def "get-volumes-fs-flavors-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/fs/flavors/json"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available file shares in a space
#
# GET /volumes/fs/json
# Returns: table<capacity: int, created_date: string, fsName: string, hostPath: string, iops: float, iopsTotal: int, orderId: string, provider: string, spaceGuid: string, state: string, updated_date: string>
export def "get-volumes-fs-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/fs/json"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a file share
#
# DELETE /volumes/fs/{name}
export def "delete-volumes-fs-name" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/volumes/fs/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a file share
#
# GET /volumes/fs/{name}/json
# Returns: table<fs: list<record>, fsUsage: list<record>, volnames: list<string>>
export def "get-volumes-fs-name-json" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/fs/{name}/json"
    path_params: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all volumes for a space
#
# GET /volumes/json
# Returns: table<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>
export def "get-volumes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/json"
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a volume
#
# DELETE /volumes/{name}
export def "delete-volumes-name" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/volumes/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share a volume with another space
#
# POST /volumes/{name}
# Returns: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>
export def "post-volumes-name" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
  --add-spaces: list<string> # The name or ID of the space where you want to provision your existing volume. Run `cf spaces` to retrieve the name, or `cf space <space_name> --guid` to retrieve the space ID.
  --remove-spaces: list<string> # The name or ID of the space from which you want to unprovision your existing volume. Run `cf spaces` to retrieve the name, or `cf space <space_name> --guid` to retrieve the space ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addSpaces, var: add_spaces}, {name: removeSpaces, var: remove_spaces}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id, add_spaces: $add_spaces, remove_spaces: $remove_spaces
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve detailed information about a volume.
#
# GET /volumes/{name}/json
# Returns: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>
export def "get-volumes-name-json" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token. (required)
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/{name}/json"
    path_params: [{name: name, var: name}]
    header: [{name: X-Auth-Token, var: x_auth_token, required: true}, {name: X-Auth-Project-Id, var: x_auth_project_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_auth_token: $x_auth_token, x_auth_project_id: $x_auth_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
