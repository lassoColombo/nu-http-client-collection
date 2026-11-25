# Auto-generated client for Business Registries v0.0.6
# Source: https://api.apis.guru/v2/specs/ato.gov.au/0.0.6/openapi.json
# Auth: --token flag or $env.BUSINESS_REGISTRIES_TOKEN

const CLIENT = {
  base_url: "http://localhost//api.abr.ato.gov.au"
  token_env_var: "BUSINESS_REGISTRIES_TOKEN"
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

def base-url-completer [] { ["http://localhost//api.abr.ato.gov.au" "http://localhost//api.sandbox.abr.ato.gov.au"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def gender-completer [] { ["Female" "Male" "Not Applicable" "Not Known"] }
def lifecycle-state-completer [] { ["Approved" "Expired" "Issued" "Pending Approval" "Suspended"] }
def electronic-address-type-completer [] { ["Email" "Fax" "Landline" "Mobile" "Website"] }
def license-type-completer [] { ["Australian Financial Services License" "License 2B"] }
def party-role-type-completer [] { ["Director" "Employee" "Member" "Partner" "Trustee"] }
def related-party-role-type-completer [] { ["Association" "Company" "Employer" "Organisation" "Partnership" "Trust"] }
def relationship-type-completer [] { ["Directorship" "Employment" "Membership" "Partnership" "Trusteeship"] }
def legal-entity-type-completer [] { ["Company" "Joint Venture" "Partnership" "Trust"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-business-names: "table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    get-classifications-address-types: "table<description: string, id: string, name: string>"
    get-classifications-business-name-lifecycle-states: "table<description: string, id: string, name: string>"
    get-classifications-electronic-address-types: "table<description: string, id: string, name: string>"
    get-classifications-genders: "table<gender: string, id: string>"
    get-classifications-legal-entity-types: "table<description: string, id: string, name: string>"
    get-classifications-license-lifecycle-states: "table<description: string, id: string, name: string>"
    get-classifications-license-types: "table<description: string, id: string, name: string>"
    get-classifications-name-directions: "table<description: string, id: string, name: string>"
    get-classifications-name-prefixes: "table<description: string, id: string, name: string>"
    get-classifications-name-types: "table<description: string, id: string, name: string>"
    get-classifications-registered-identifier-types: "table<description: string, id: string, name: string>"
    get-classifications-roles: "table<id: string, reciprocalRole: string, reciprocalRoleDescription: string, relationship: string, role: string, roleDescription: string>"
    get-individuals: "table<addresses: list<record>, dateOfBirth: string, electronicAddresses: list<record>, fromDate: string, gender: string, id: string, names: list<record>, placeOfBirth: string, toDate: string>"
    post-individuals: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>"
    get-individuals-party-id: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>"
    put-individuals-party-id: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>"
    get-individuals-party-id-addresses: "table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    post-individuals-party-id-addresses: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    get-individuals-party-id-addresses-address-id: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    put-individuals-party-id-addresses-address-id: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    get-individuals-party-id-business-names: "table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    post-individuals-party-id-business-names: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    get-individuals-party-id-business-names-product-id: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    put-individuals-party-id-business-names-product-id: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    get-individuals-party-id-electronic-addresses: "table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    post-individuals-party-id-electronic-addresses: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    get-individuals-party-id-electronic-addresses-address-id: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    put-individuals-party-id-electronic-addresses-address-id: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    get-individuals-party-id-licenses: "table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    post-individuals-party-id-licenses: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    get-individuals-party-id-licenses-product-id: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    put-individuals-party-id-licenses-product-id: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    get-individuals-party-id-roles: "table<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    post-individuals-party-id-roles: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    get-individuals-party-id-roles-role-id: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    put-individuals-party-id-roles-role-id: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    get-licenses: "table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    get-organisations: "table<addresses: list<record>, electronicAddresses: list<record>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: list<record>, registeredIdentifiers: list<record>, toDate: string>"
    post-organisations: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>"
    get-organisations-party-id: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>"
    put-organisations-party-id: "record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>"
    get-organisations-party-id-addresses: "table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    post-organisations-party-id-addresses: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    get-organisations-party-id-addresses-address-id: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    put-organisations-party-id-addresses-address-id: "record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>"
    get-organisations-party-id-business-names: "table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    post-organisations-party-id-business-names: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    get-organisations-party-id-business-names-product-id: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    put-organisations-party-id-business-names-product-id: "record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>"
    get-organisations-party-id-electronic-addresses: "table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    post-organisations-party-id-electronic-addresses: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    get-organisations-party-id-electronic-addresses-address-id: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    put-organisations-party-id-electronic-addresses-address-id: "record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>"
    get-organisations-party-id-licenses: "table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    post-organisations-party-id-licenses: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    get-organisations-party-id-licenses-product-id: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    put-organisations-party-id-licenses-product-id: "record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>"
    get-organisations-party-id-roles: "table<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    post-organisations-party-id-roles: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    get-organisations-party-id-roles-role-id: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
    put-organisations-party-id-roles-role-id: "record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-business-names" "get-classifications-address-types" "get-classifications-business-name-lifecycle-states" "get-classifications-electronic-address-types" "get-classifications-genders" "get-classifications-legal-entity-types" "get-classifications-license-lifecycle-states" "get-classifications-license-types" "get-classifications-name-directions" "get-classifications-name-prefixes" "get-classifications-name-types" "get-classifications-registered-identifier-types" "get-classifications-roles" "get-individuals" "post-individuals" "delete-individuals-party-id" "get-individuals-party-id" "put-individuals-party-id" "get-individuals-party-id-addresses" "post-individuals-party-id-addresses" "delete-individuals-party-id-addresses-address-id" "get-individuals-party-id-addresses-address-id" "put-individuals-party-id-addresses-address-id" "get-individuals-party-id-business-names" "post-individuals-party-id-business-names" "delete-individuals-party-id-business-names-product-id" "get-individuals-party-id-business-names-product-id" "put-individuals-party-id-business-names-product-id" "get-individuals-party-id-electronic-addresses" "post-individuals-party-id-electronic-addresses" "delete-individuals-party-id-electronic-addresses-address-id" "get-individuals-party-id-electronic-addresses-address-id" "put-individuals-party-id-electronic-addresses-address-id" "get-individuals-party-id-licenses" "post-individuals-party-id-licenses" "delete-individuals-party-id-licenses-product-id" "get-individuals-party-id-licenses-product-id" "put-individuals-party-id-licenses-product-id" "get-individuals-party-id-roles" "post-individuals-party-id-roles" "delete-individuals-party-id-roles-role-id" "get-individuals-party-id-roles-role-id" "put-individuals-party-id-roles-role-id" "get-licenses" "get-organisations" "post-organisations" "delete-organisations-party-id" "get-organisations-party-id" "put-organisations-party-id" "get-organisations-party-id-addresses" "post-organisations-party-id-addresses" "delete-organisations-party-id-addresses-address-id" "get-organisations-party-id-addresses-address-id" "put-organisations-party-id-addresses-address-id" "get-organisations-party-id-business-names" "post-organisations-party-id-business-names" "delete-organisations-party-id-business-names-product-id" "get-organisations-party-id-business-names-product-id" "put-organisations-party-id-business-names-product-id" "get-organisations-party-id-electronic-addresses" "post-organisations-party-id-electronic-addresses" "delete-organisations-party-id-electronic-addresses-address-id" "get-organisations-party-id-electronic-addresses-address-id" "put-organisations-party-id-electronic-addresses-address-id" "get-organisations-party-id-licenses" "post-organisations-party-id-licenses" "delete-organisations-party-id-licenses-product-id" "get-organisations-party-id-licenses-product-id" "put-organisations-party-id-licenses-product-id" "get-organisations-party-id-roles" "post-organisations-party-id-roles" "delete-organisations-party-id-roles-role-id" "get-organisations-party-id-roles-role-id" "put-organisations-party-id-roles-role-id" "commands"] | sort) } | get name | first)
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

# Retrieve a list of business names
#
# GET /business-names
# Returns: table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "get-business-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/business-names"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of address types
#
# GET /classifications/address-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-address-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/address-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of business name lifecycle states
#
# GET /classifications/business-name-lifecycle-states
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-business-name-lifecycle-states" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/business-name-lifecycle-states"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of electronic address types
#
# GET /classifications/electronic-address-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-electronic-address-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/electronic-address-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of genders
#
# GET /classifications/genders
# Returns: table<gender: string, id: string>
export def "get-classifications-genders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/genders"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of legal entity types
#
# GET /classifications/legal-entity-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-legal-entity-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/legal-entity-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of license lifecycle states
#
# GET /classifications/license-lifecycle-states
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-license-lifecycle-states" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/license-lifecycle-states"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of license types
#
# GET /classifications/license-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-license-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/license-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of name directions
#
# GET /classifications/name-directions
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-name-directions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/name-directions"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of name prefixes
#
# GET /classifications/name-prefixes
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-name-prefixes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/name-prefixes"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of name types
#
# GET /classifications/name-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-name-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/name-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of registered identifier types
#
# GET /classifications/registered-identifier-types
# Returns: table<description: string, id: string, name: string>
export def "get-classifications-registered-identifier-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/registered-identifier-types"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of roles
#
# GET /classifications/roles
# Returns: table<id: string, reciprocalRole: string, reciprocalRoleDescription: string, relationship: string, role: string, roleDescription: string>
export def "get-classifications-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/classifications/roles"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of individuals
#
# GET /individuals
# Returns: table<addresses: list<record>, dateOfBirth: string, electronicAddresses: list<record>, fromDate: string, gender: string, id: string, names: list<record>, placeOfBirth: string, toDate: string>
export def "get-individuals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-of-birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format).
  --place-of-birth: string # The individual's place of birth, for example, `Tamworth`.
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals"
    query: [{name: dateOfBirth, var: date_of_birth}, {name: placeOfBirth, var: place_of_birth}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_of_birth: $date_of_birth, place_of_birth: $place_of_birth, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an individual
#
# POST /individuals
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>
export def "post-individuals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  date_of_birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  place_of_birth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals"
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: electronicAddresses, var: electronic_addresses}, {name: gender, var: gender}, {name: names, var: names}, {name: placeOfBirth, var: place_of_birth}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_key: $api_key, addresses: $addresses, date_of_birth: $date_of_birth, electronic_addresses: $electronic_addresses, gender: $gender, names: $names, place_of_birth: $place_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an individual
#
# DELETE /individuals/{partyId}
export def "delete-individuals-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an individual
#
# GET /individuals/{partyId}
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>
export def "get-individuals-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an individual
#
# PUT /individuals/{partyId}
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: string, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: string, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string>
export def "put-individuals-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  date_of_birth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  place_of_birth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: dateOfBirth, var: date_of_birth}, {name: electronicAddresses, var: electronic_addresses}, {name: gender, var: gender}, {name: names, var: names}, {name: placeOfBirth, var: place_of_birth}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, addresses: $addresses, date_of_birth: $date_of_birth, electronic_addresses: $electronic_addresses, gender: $gender, names: $names, place_of_birth: $place_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of addresses
#
# GET /individuals/{partyId}/addresses
# Returns: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "get-individuals-party-id-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an address
#
# POST /individuals/{partyId}/addresses
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "post-individuals-party-id-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals/{partyId}/addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: line1, var: line1}, {name: line2, var: line2}, {name: line3, var: line3}, {name: name, var: name}, {name: postalCode, var: postal_code}, {name: suburb, var: suburb}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postal_code: $postal_code, suburb: $suburb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an address
#
# DELETE /individuals/{partyId}/addresses/{addressId}
export def "delete-individuals-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an address
#
# GET /individuals/{partyId}/addresses/{addressId}
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "get-individuals-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an address
#
# PUT /individuals/{partyId}/addresses/{addressId}
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "put-individuals-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: line1, var: line1}, {name: line2, var: line2}, {name: line3, var: line3}, {name: name, var: name}, {name: postalCode, var: postal_code}, {name: suburb, var: suburb}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key, city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postal_code: $postal_code, suburb: $suburb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of business names
#
# GET /individuals/{partyId}/business-names
# Returns: table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "get-individuals-party-id-business-names" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/business-names"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a business name
#
# POST /individuals/{partyId}/business-names
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "post-individuals-party-id-business-names" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals/{partyId}/business-names"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: lifecycleState, var: lifecycle_state}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, lifecycle_state: $lifecycle_state, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a business name
#
# DELETE /individuals/{partyId}/business-names/{productId}
export def "delete-individuals-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a business name
#
# GET /individuals/{partyId}/business-names/{productId}
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "get-individuals-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a business name
#
# PUT /individuals/{partyId}/business-names/{productId}
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "put-individuals-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: lifecycleState, var: lifecycle_state}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key, lifecycle_state: $lifecycle_state, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of electronic addresses
#
# GET /individuals/{partyId}/electronic-addresses
# Returns: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "get-individuals-party-id-electronic-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/electronic-addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an electronic address
#
# POST /individuals/{partyId}/electronic-addresses
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "post-individuals-party-id-electronic-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals/{partyId}/electronic-addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: areaCode, var: area_code}, {name: countryPrefix, var: country_prefix}, {name: electronicAddressType, var: electronic_address_type}, {name: email, var: email}, {name: extension, var: extension}, {name: number, var: number}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, area_code: $area_code, country_prefix: $country_prefix, electronic_address_type: $electronic_address_type, email: $email, extension: $extension, number: $number, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an electronic address
#
# DELETE /individuals/{partyId}/electronic-addresses/{addressId}
export def "delete-individuals-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an electronic address
#
# GET /individuals/{partyId}/electronic-addresses/{addressId}
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "get-individuals-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an electronic address
#
# PUT /individuals/{partyId}/electronic-addresses/{addressId}
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "put-individuals-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: areaCode, var: area_code}, {name: countryPrefix, var: country_prefix}, {name: electronicAddressType, var: electronic_address_type}, {name: email, var: email}, {name: extension, var: extension}, {name: number, var: number}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key, area_code: $area_code, country_prefix: $country_prefix, electronic_address_type: $electronic_address_type, email: $email, extension: $extension, number: $number, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of licenses
#
# GET /individuals/{partyId}/licenses
# Returns: table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "get-individuals-party-id-licenses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/licenses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a license
#
# POST /individuals/{partyId}/licenses
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "post-individuals-party-id-licenses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals/{partyId}/licenses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseType, var: license_type}, {name: lifecycleState, var: lifecycle_state}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, license_type: $license_type, lifecycle_state: $lifecycle_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a license
#
# DELETE /individuals/{partyId}/licenses/{productId}
export def "delete-individuals-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a license
#
# GET /individuals/{partyId}/licenses/{productId}
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "get-individuals-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a license
#
# PUT /individuals/{partyId}/licenses/{productId}
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "put-individuals-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseType, var: license_type}, {name: lifecycleState, var: lifecycle_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key, license_type: $license_type, lifecycle_state: $lifecycle_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of roles
#
# GET /individuals/{partyId}/roles
# Returns: table<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "get-individuals-party-id-roles" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/roles"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role
#
# POST /individuals/{partyId}/roles
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "post-individuals-party-id-roles" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: string # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/individuals/{partyId}/roles"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: partyRoleType, var: party_role_type}, {name: relatedPartyId, var: related_party_id}, {name: relatedPartyRoleType, var: related_party_role_type}, {name: relationshipType, var: relationship_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, party_role_type: $party_role_type, related_party_id: $related_party_id, related_party_role_type: $related_party_role_type, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role
#
# DELETE /individuals/{partyId}/roles/{roleId}
export def "delete-individuals-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/individuals/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a role
#
# GET /individuals/{partyId}/roles/{roleId}
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "get-individuals-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/individuals/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role
#
# PUT /individuals/{partyId}/roles/{roleId}
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "put-individuals-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: string # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/individuals/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: partyRoleType, var: party_role_type}, {name: relatedPartyId, var: related_party_id}, {name: relatedPartyRoleType, var: related_party_role_type}, {name: relationshipType, var: relationship_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key, party_role_type: $party_role_type, related_party_id: $related_party_id, related_party_role_type: $related_party_role_type, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of licenses
#
# GET /licenses
# Returns: table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "get-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/licenses"
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of organisations
#
# GET /organisations
# Returns: table<addresses: list<record>, electronicAddresses: list<record>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: list<record>, registeredIdentifiers: list<record>, toDate: string>
export def "get-organisations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registered-identifier: string # The registered identifier, for example, `ACN` or `ABN`.
  --identifier: string # The identifier, for example, `123456789`.
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations"
    query: [{name: registeredIdentifier, var: registered_identifier}, {name: identifier, var: identifier}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registered_identifier: $registered_identifier, identifier: $identifier, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an organisation
#
# POST /organisations
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>
export def "post-organisations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishment_date: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legal_entity_type: string@legal-entity-type-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registered-identifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations"
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: electronicAddresses, var: electronic_addresses}, {name: establishmentDate, var: establishment_date}, {name: legalEntityType, var: legal_entity_type}, {name: names, var: names}, {name: registeredIdentifiers, var: registered_identifiers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    api_key: $api_key, addresses: $addresses, electronic_addresses: $electronic_addresses, establishment_date: $establishment_date, legal_entity_type: $legal_entity_type, names: $names, registered_identifiers: $registered_identifiers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an organisation
#
# DELETE /organisations/{partyId}
export def "delete-organisations-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an organisation
#
# GET /organisations/{partyId}
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>
export def "get-organisations-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an organisation
#
# PUT /organisations/{partyId}
# Returns: record<addresses: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: string, legalEntityType: string, names: table<fromDate: string, id: string, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: string, identifier: string, identifierType: string, toDate: string>, toDate: string>
export def "put-organisations-party-id" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronic-addresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishment_date: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legal_entity_type: string@legal-entity-type-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registered-identifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: electronicAddresses, var: electronic_addresses}, {name: establishmentDate, var: establishment_date}, {name: legalEntityType, var: legal_entity_type}, {name: names, var: names}, {name: registeredIdentifiers, var: registered_identifiers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, addresses: $addresses, electronic_addresses: $electronic_addresses, establishment_date: $establishment_date, legal_entity_type: $legal_entity_type, names: $names, registered_identifiers: $registered_identifiers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of addresses
#
# GET /organisations/{partyId}/addresses
# Returns: table<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "get-organisations-party-id-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an address
#
# POST /organisations/{partyId}/addresses
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "post-organisations-party-id-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{partyId}/addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: line1, var: line1}, {name: line2, var: line2}, {name: line3, var: line3}, {name: name, var: name}, {name: postalCode, var: postal_code}, {name: suburb, var: suburb}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postal_code: $postal_code, suburb: $suburb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an address
#
# DELETE /organisations/{partyId}/addresses/{addressId}
export def "delete-organisations-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an address
#
# GET /organisations/{partyId}/addresses/{addressId}
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "get-organisations-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an address
#
# PUT /organisations/{partyId}/addresses/{addressId}
# Returns: record<city: string, country: string, fromDate: string, id: string, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string>
export def "put-organisations-party-id-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postal-code: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}/addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: line1, var: line1}, {name: line2, var: line2}, {name: line3, var: line3}, {name: name, var: name}, {name: postalCode, var: postal_code}, {name: suburb, var: suburb}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key, city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postal_code: $postal_code, suburb: $suburb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of business names
#
# GET /organisations/{partyId}/business-names
# Returns: table<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "get-organisations-party-id-business-names" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/business-names"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a business name
#
# POST /organisations/{partyId}/business-names
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "post-organisations-party-id-business-names" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{partyId}/business-names"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: lifecycleState, var: lifecycle_state}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, lifecycle_state: $lifecycle_state, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a business name
#
# DELETE /organisations/{partyId}/business-names/{productId}
export def "delete-organisations-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a business name
#
# GET /organisations/{partyId}/business-names/{productId}
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "get-organisations-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a business name
#
# PUT /organisations/{partyId}/business-names/{productId}
# Returns: record<fromDate: string, id: string, lifecycleState: string, name: string, toDate: string>
export def "put-organisations-party-id-business-names-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}/business-names/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: lifecycleState, var: lifecycle_state}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key, lifecycle_state: $lifecycle_state, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of electronic addresses
#
# GET /organisations/{partyId}/electronic-addresses
# Returns: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "get-organisations-party-id-electronic-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/electronic-addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an electronic address
#
# POST /organisations/{partyId}/electronic-addresses
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "post-organisations-party-id-electronic-addresses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{partyId}/electronic-addresses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: areaCode, var: area_code}, {name: countryPrefix, var: country_prefix}, {name: electronicAddressType, var: electronic_address_type}, {name: email, var: email}, {name: extension, var: extension}, {name: number, var: number}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, area_code: $area_code, country_prefix: $country_prefix, electronic_address_type: $electronic_address_type, email: $email, extension: $extension, number: $number, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an electronic address
#
# DELETE /organisations/{partyId}/electronic-addresses/{addressId}
export def "delete-organisations-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an electronic address
#
# GET /organisations/{partyId}/electronic-addresses/{addressId}
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "get-organisations-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an electronic address
#
# PUT /organisations/{partyId}/electronic-addresses/{addressId}
# Returns: record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: string, number: string, toDate: string, url: string>
export def "put-organisations-party-id-electronic-addresses-address-id" [
  party_id: string
  address_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --area-code: string # The area code, for example, "02". (e.g. 02)
  --country-prefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronic-address-type: string@electronic-address-type-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}/electronic-addresses/{addressId}"
    path_params: [{name: partyId, var: party_id}, {name: addressId, var: address_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: areaCode, var: area_code}, {name: countryPrefix, var: country_prefix}, {name: electronicAddressType, var: electronic_address_type}, {name: email, var: email}, {name: extension, var: extension}, {name: number, var: number}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, address_id: $address_id, api_key: $api_key, area_code: $area_code, country_prefix: $country_prefix, electronic_address_type: $electronic_address_type, email: $email, extension: $extension, number: $number, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of licenses
#
# GET /organisations/{partyId}/licenses
# Returns: table<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "get-organisations-party-id-licenses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/licenses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a license
#
# POST /organisations/{partyId}/licenses
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "post-organisations-party-id-licenses" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{partyId}/licenses"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseType, var: license_type}, {name: lifecycleState, var: lifecycle_state}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, license_type: $license_type, lifecycle_state: $lifecycle_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a license
#
# DELETE /organisations/{partyId}/licenses/{productId}
export def "delete-organisations-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a license
#
# GET /organisations/{partyId}/licenses/{productId}
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "get-organisations-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a license
#
# PUT /organisations/{partyId}/licenses/{productId}
# Returns: record<fromDate: string, id: string, licenseType: string, lifecycleState: string, toDate: string>
export def "put-organisations-party-id-licenses-product-id" [
  party_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --license-type: string@license-type-completer # The license type. (default: Australian Financial Services License)
  --lifecycle-state: string@lifecycle-state-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}/licenses/{productId}"
    path_params: [{name: partyId, var: party_id}, {name: productId, var: product_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseType, var: license_type}, {name: lifecycleState, var: lifecycle_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, product_id: $product_id, api_key: $api_key, license_type: $license_type, lifecycle_state: $lifecycle_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of roles
#
# GET /organisations/{partyId}/roles
# Returns: table<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "get-organisations-party-id-roles" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/roles"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role
#
# POST /organisations/{partyId}/roles
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "post-organisations-party-id-roles" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: string # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{partyId}/roles"
    path_params: [{name: partyId, var: party_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: partyRoleType, var: party_role_type}, {name: relatedPartyId, var: related_party_id}, {name: relatedPartyRoleType, var: related_party_role_type}, {name: relationshipType, var: relationship_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    party_id: $party_id, api_key: $api_key, party_role_type: $party_role_type, related_party_id: $related_party_id, related_party_role_type: $related_party_role_type, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role
#
# DELETE /organisations/{partyId}/roles/{roleId}
export def "delete-organisations-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organisations/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a role
#
# GET /organisations/{partyId}/roles/{roleId}
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "get-organisations-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role
#
# PUT /organisations/{partyId}/roles/{roleId}
# Returns: record<fromDate: string, id: string, partyRoleType: string, relatedPartyId: string, relatedPartyRoleType: string, relationshipType: string, toDate: string>
export def "put-organisations-party-id-roles-role-id" [
  party_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API key. (required)
  --party-role-type: string@party-role-type-completer # The party's role type. (default: Employee)
  related_party_id: string # The related party's unique identifier.
  --related-party-role-type: string@related-party-role-type-completer # The related party's role type. (default: Employer)
  relationship_type: string@relationship-type-completer # The relationship type. (default: Employment)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{partyId}/roles/{roleId}"
    path_params: [{name: partyId, var: party_id}, {name: roleId, var: role_id}]
    header: [{name: apiKey, var: api_key, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: partyRoleType, var: party_role_type}, {name: relatedPartyId, var: related_party_id}, {name: relatedPartyRoleType, var: related_party_role_type}, {name: relationshipType, var: relationship_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, role_id: $role_id, api_key: $api_key, party_role_type: $party_role_type, related_party_id: $related_party_id, related_party_role_type: $related_party_role_type, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
