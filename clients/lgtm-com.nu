# Auto-generated client for LGTM API specification v1.0
# Source: https://api.apis.guru/v2/specs/lgtm.com/v1.0/openapi.json
# Auth: --token flag or $env.LGTM_API_SPECIFICATION_TOKEN

const CLIENT = {
  base_url: "https://lgtm.com/api/v1.0"
  token_env_var: "LGTM_API_SPECIFICATION_TOKEN"
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

def base-url-completer [] { ["https://lgtm.com/api/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/sarif+json" "text/csv"] }
def mode-completer [] { ["full" "sparse" "upload"] }
def source-completer [] { ["administrator" "repository"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-version: "record<apiVersion: string>"
    get-analysis: "record<commit-id: string, id: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string>, log-url: string, project: record<id: int, name: string, url: string, url-identifier: string>, results-url: string>"
    get-alerts: "record"
    request-analysis: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    get-analysis-for-commit: "record<commit-id: string, id: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string>, log-url: string, project: record<id: int, name: string, url: string, url-identifier: string>, results-url: string>"
    request-review: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    get-code-review: "table<id: string, languages: list<record>, results-url: string, status: string, status-message: string>"
    get-issue: "record"
    get-spec: "record"
    get-operation: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    get-projects: "record<data: table<id: int, name: string, url: string, url-identifier: string>, nextPageUrl: string>"
    add-project: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    delete-project: "record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>"
    get-project: "record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>"
    get-project-config: "record"
    set-project-config: "record"
    get-project-by-url-identifier: "record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>"
    create-query-job: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    get-query-job: "record<id: string, result-url: string, stats: record<failed: int, pending: int, success-with-result: int, success-without-result: int, successful: int>>"
    get-query-job-results-overview: "record<data: table<error: string, external: int, internal: int, project: record, status: string, total: int>, next: string>"
    get-query-job-results-for-project: "record<columns: list<string>, data: list<list<record>>, next: string, project: record<id: int, name: string, url: string, url-identifier: string>>"
    abort-upload: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    complete-upload: "record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>"
    init-snapshot-upload: "record<id: string, url: string>"
    get-health: "record<description: string, details: record, status: string>"
    get-metrics: "record<data: table<description: string, metric-id: string>>"
    get-metric: "record<measurements: table<timestamp: string, value: float>, metric-id: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-version" "get-analysis" "get-alerts" "request-analysis" "get-analysis-for-commit" "request-review" "get-code-review" "get-issue" "get-spec" "get-operation" "get-projects" "add-project" "delete-project" "get-project" "get-project-config" "set-project-config" "get-project-by-url-identifier" "create-query-job" "get-query-job" "get-query-job-results-overview" "get-query-job-results-for-project" "abort-upload" "complete-upload" "upload-part" "get-snapshot" "init-snapshot-upload" "get-health" "get-metrics" "get-metric" "commands"] | sort) } | get name | first)
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

# Version information
#
# GET /
# Returns: record<apiVersion: string>
# operationId: getVersion
export def "get-version" [
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
    path: "/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get analysis summary
#
# GET /analyses/{analysis-id}
# Returns: record<commit-id: string, id: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string>, log-url: string, project: record<id: int, name: string, url: string, url-identifier: string>, results-url: string>
# operationId: getAnalysis
export def "get-analysis" [
  analysis_id: string
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
    path: "/analyses/{analysis-id}"
    path_params: [{name: analysis-id, var: analysis_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    analysis_id: $analysis_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed alert information
#
# GET /analyses/{analysis-id}/alerts
# Returns: record
# operationId: getAlerts
export def "get-alerts" [
  analysis_id: string
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
  --sarif-version: string # The desired version of the SARIF format. Currently supported versions are `1.0.0`, `2.0.0`, and `2.1.0`.
  --excluded-files: oneof<nothing, bool> # Set `true` to include results in files that are excluded from the output by default. This includes results in test code and generated files. For more information, see [File classification](https://lgtm.com/help/lgtm/file-classification). (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{analysis-id}/alerts"
    path_params: [{name: analysis-id, var: analysis_id}]
    query: [{name: sarif-version, var: sarif_version}, {name: excluded-files, var: excluded_files}]
    accept: ["application/json", "application/sarif+json", "text/csv"]
    ok: [200]
    auth: bearer
  } {
    analysis_id: $analysis_id, sarif_version: $sarif_version, excluded_files: $excluded_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Run analysis of a specific commit
#
# POST /analyses/{project-id}
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: requestAnalysis
export def "request-analysis" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string # The identifier of the commit to analyze. (required)
  --language: list<string> # The language codes of the languages to analyze. For a list of available languages, see [Supported languages](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported). To specify more than one language, this parameter can be repeated. If no language is specified, all the project's languages will be analyzed.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/analyses/{project-id}"
    path_params: [{name: project-id, var: project_id}]
    query: [{name: commit, var: commit, required: true}, {name: language, var: language, style: multi}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_id: $project_id, commit: $commit, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get analysis summary for a specific commit
#
# GET /analyses/{project-id}/commits/{commit-id}
# Returns: record<commit-id: string, id: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string>, log-url: string, project: record<id: int, name: string, url: string, url-identifier: string>, results-url: string>
# operationId: getAnalysisForCommit
export def "get-analysis-for-commit" [
  project_id: int
  commit_id: string
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
    path: "/analyses/{project-id}/commits/{commit-id}"
    path_params: [{name: project-id, var: project_id}, {name: commit-id, var: commit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, commit_id: $commit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run code review for a patch
#
# POST /codereviews/{project-id}
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: requestReview
export def "request-review" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --base: string # The identifier for the base commit. (required)
  --external-id: int # Your reference number for the code review. (required, format: int32, e.g. integer)
  --review-url: string # An informative back-link to an external system.
  --callback-url: string # The callback URL for LGTM to post to on completion of the review. When the code review is complete, the API sends an HTTP POST request to the callback URL with the result of the code review in the request body. The code review results in the request body are identical to the results accessed through the [`/codereviews/{review-id}`](https://lgtm.com/help/lgtm/api/api-v1#opIdgetCodeReview) end-point. If you specify a `callback-secret`, the request also includes an `x-lgtm-signature` header with a digital signature of the request's contents.
  --callback-secret: string # The `callback-secret` is used to compute a signature which is included in the `x-lgtm-signature` header of the callback response. The receiver of the callback can check the validity of the response by computing the signature using HMAC-SHA1 and verifying that it matches the `x-lgtm-signature` header value. The HMAC algorithm requires byte sequences as inputs for both the secret and the message. The callback secret string must be converted to bytes using UTF-8 encoding. The response body should ideally be read as a plain byte sequence. Conversion to, for example a JSON object, and back to a byte sequence might change the formatting, and would invalidate the signature.
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/codereviews/{project-id}"
    path_params: [{name: project-id, var: project_id}]
    query: [{name: base, var: base, required: true}, {name: external-id, var: external_id, required: true}, {name: review-url, var: review_url}, {name: callback-url, var: callback_url}, {name: callback-secret, var: callback_secret}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    project_id: $project_id, base: $base, external_id: $external_id, review_url: $review_url, callback_url: $callback_url, callback_secret: $callback_secret, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get results of code review
#
# GET /codereviews/{review-id}
# Returns: table<id: string, languages: list<record>, results-url: string, status: string, status-message: string>
# operationId: getCodeReview
export def "get-code-review" [
  review_id: string
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
    path: "/codereviews/{review-id}"
    path_params: [{name: review-id, var: review_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed alert information for an issue
#
# GET /issues/{project-id}/{alert-key}
# Returns: record
# operationId: getIssue
export def "get-issue" [
  project_id: int
  alert_key: string
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
    path: "/issues/{project-id}/{alert-key}"
    path_params: [{name: project-id, var: project_id}, {name: alert-key, var: alert_key}]
    accept: ["application/sarif+json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alert_key: $alert_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API specification
#
# GET /openapi
# Returns: record
# operationId: getSpec
export def "get-spec" [
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
    path: "/openapi"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get operation status
#
# GET /operations/{operation-id}
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: getOperation
export def "get-operation" [
  operation_id: int
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
    path: "/operations/{operation-id}"
    path_params: [{name: operation-id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List projects
#
# GET /projects
# Returns: record<data: table<id: int, name: string, url: string, url-identifier: string>, nextPageUrl: string>
# operationId: getProjects
export def "get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of projects to return in each response (1-100). (format: int32, default: 100)
  --start: string # An opaque identifier generated by the API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: limit, var: limit}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a project to LGTM
#
# POST /projects
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: addProject
export def "add-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository: string # The URL of the repository to analyze. LGTM tests this against the [repository providers](https://lgtm.com/admin/help/adding-repository-providers) defined for the system. If it doesn't match any of them, the request fails. (required, format: uri)
  --language: list<string> # Optional, a [language code](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported) to specify which language to analyze. To request the analysis of more than one language, specify a query parameter for each language. By default, LGTM tries to analyze all supported languages.
  --mode: string@mode-completer # The analysis mode of the new project. When set to `full` all commits of the project are analyzed; when set to `sparse` the latest commit of the project is analyzed periodically; when set to `upload`, no automatic analysis is performed, instead externally-generated databases should be uploaded. For new projects the default value is `full`. The `mode` parameter cannot be used to change the analysis mode of existing projects. Therefore, for existing projects, it should either be left blank or set to match the analysis mode of the project.
  --commit: string # Required when `mode=upload`, specify the identifier of the commit used to generate the database.
  --date: string # Optional when `mode=upload`, specify the date and time of the commit used to generate the database; defaults to the current time. (format: date-time)
  --worker-label: list<string> # Optional, any [labels](https://lgtm.com/admin/help/defining-worker-labels) required by workers to analyze this project. To specify more than one label, repeat the query parameter.
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    query: [{name: repository, var: repository, required: true}, {name: language, var: language, style: multi}, {name: mode, var: mode}, {name: commit, var: commit}, {name: date, var: date}, {name: worker-label, var: worker_label, style: multi}]
    body: {content_type: "application/x-yaml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    repository: $repository, language: $language, mode: $mode, commit: $commit, date: $date, worker_label: $worker_label, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project by numeric identifier
#
# DELETE /projects/{project-id}
# Returns: record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>
# operationId: deleteProject
export def "delete-project" [
  project_id: int
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
    method: delete
    path: "/projects/{project-id}"
    path_params: [{name: project-id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project by numeric identifier
#
# GET /projects/{project-id}
# Returns: record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>
# operationId: getProject
export def "get-project" [
  project_id: int
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
    path: "/projects/{project-id}"
    path_params: [{name: project-id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration for a project identified by numeric identifier
#
# GET /projects/{project-id}/settings/analysis-configuration
# Returns: record
# operationId: getProjectConfig
export def "get-project-config" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string@source-completer # The type of project configuration to retrieve. If this parameter isn't specified, the request retrieves the effective configuration. That is, the configuration that is actually applied to the project, which may be from: * the repository * the administrator-set, project configuration * the global configuration. If you do specify this value, it must be one of: * `repository` to retrieve the configuration specified by a YAML file in the repository. A 404 status is returned if there is no repository configuration. * `administrator` to retrieve the administrator-set, project configuration. A 404 status is returned if there is no administrator configuration.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project-id}/settings/analysis-configuration"
    path_params: [{name: project-id, var: project_id}]
    query: [{name: source, var: source}]
    accept: ["application/x-yaml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the administrator configuration for a project identified by numeric identifier
#
# PUT /projects/{project-id}/settings/analysis-configuration
# Returns: record
# operationId: setProjectConfig
export def "set-project-config" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{project-id}/settings/analysis-configuration"
    path_params: [{name: project-id, var: project_id}]
    body: {content_type: "application/x-yaml", kind: opaque, accepts: scalar}
    accept: ["application/x-yaml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project by URL identifier
#
# GET /projects/{provider}/{org}/{name}
# Returns: record<id: int, name: string, url: string, url-identifier: string, languages: table<alerts: int, analysis-date: string, commit-date: string, commit-id: string, language: string, lines: int, status: string, grade: string>>
# operationId: getProjectByUrlIdentifier
export def "get-project-by-url-identifier" [
  provider: string
  org: string
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
    path: "/projects/{provider}/{org}/{name}"
    path_params: [{name: provider, var: provider}, {name: org, var: org}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200, 307]
    auth: bearer
  } {
    provider: $provider, org: $org, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run a CodeQL query on one or more projects
#
# POST /queryjobs
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: createQueryJob
export def "create-query-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [language](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported) you want to analyze. (required)
  --project-id: list<int> # The identifier of the project to analyze. Either `project-id` or `projects-list` must be specified.
  --projects-list: string # Name of the list containing the projects to analyze. Either `project-id` or `projects-list` must be specified.
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/queryjobs"
    query: [{name: language, var: language, required: true}, {name: project-id, var: project_id, style: multi}, {name: projects-list, var: projects_list}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    language: $language, project_id: $project_id, projects_list: $projects_list, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status of a query job
#
# GET /queryjobs/{queryjob-id}
# Returns: record<id: string, result-url: string, stats: record<failed: int, pending: int, success-with-result: int, success-without-result: int, successful: int>>
# operationId: getQueryJob
export def "get-query-job" [
  queryjob_id: string
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
    path: "/queryjobs/{queryjob-id}"
    path_params: [{name: queryjob-id, var: queryjob_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queryjob_id: $queryjob_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provide a summary of results for the projects in the query job
#
# GET /queryjobs/{queryjob-id}/results
# Returns: record<data: table<error: string, external: int, internal: int, project: record, status: string, total: int>, next: string>
# operationId: getQueryJobResultsOverview
export def "get-query-job-results-overview" [
  queryjob_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # An opaque identifier generated by the API used for pagination. This identifier will be included as part of the response for this endpoint whenever more than one page of results is available.
  --limit: int # The number of results to return. Useful for pagination. (format: int32, default: 100)
  --filter: string # Only return a subset of results. Legal values are `w-results`, `wo-results`, `error`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/queryjobs/{queryjob-id}/results"
    path_params: [{name: queryjob-id, var: queryjob_id}]
    query: [{name: start, var: start}, {name: limit, var: limit}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queryjob_id: $queryjob_id, start: $start, limit: $limit, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the results of a query job for a specific project
#
# GET /queryjobs/{queryjob-id}/results/{project-id}
# Returns: record<columns: list<string>, data: list<list<record>>, next: string, project: record<id: int, name: string, url: string, url-identifier: string>>
# operationId: getQueryJobResultsForProject
export def "get-query-job-results-for-project" [
  queryjob_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Start point for the page of results. (format: int32)
  --limit: int # The maximum number of results to display (less than 100). (format: int32, default: 100)
  --nofilter: oneof<nothing, bool> # Include results that are not part of the source tree. These results are filtered out by default. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/queryjobs/{queryjob-id}/results/{project-id}"
    path_params: [{name: queryjob-id, var: queryjob_id}, {name: project-id, var: project_id}]
    query: [{name: start, var: start}, {name: limit, var: limit}, {name: nofilter, var: nofilter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    queryjob_id: $queryjob_id, project_id: $project_id, start: $start, limit: $limit, nofilter: $nofilter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Abort database upload process
#
# DELETE /snapshots/uploads/{session-id}
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: abortUpload
export def "abort-upload" [
  session_id: string
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
    method: delete
    path: "/snapshots/uploads/{session-id}"
    path_params: [{name: session-id, var: session_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete snapshot upload session
#
# POST /snapshots/uploads/{session-id}
# Returns: record<id: int, status: string, task-result: any, task-result-url: string, task-type: string, uploads: record>
# operationId: completeUpload
export def "complete-upload" [
  session_id: string
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
    path: "/snapshots/uploads/{session-id}"
    path_params: [{name: session-id, var: session_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload snapshot
#
# PUT /snapshots/uploads/{session-id}
# operationId: uploadPart
export def "upload-part" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/snapshots/uploads/{session-id}"
    path_params: [{name: session-id, var: session_id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    session_id: $session_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a snapshot
#
# GET /snapshots/{project-id}/{language}
# operationId: getSnapshot
export def "get-snapshot" [
  project_id: int
  language: string
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
    path: "/snapshots/{project-id}/{language}"
    path_params: [{name: project-id, var: project_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [303]
    auth: bearer
  } {
    project_id: $project_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start snapshot upload session
#
# POST /snapshots/{project-id}/{language}
# Returns: record<id: string, url: string>
# operationId: initSnapshotUpload
export def "init-snapshot-upload" [
  project_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string # The identifier of the analyzed commit. (required)
  --date: string # The date and time of the analyzed commit (default the current time). (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/snapshots/{project-id}/{language}"
    path_params: [{name: project-id, var: project_id}, {name: language, var: language}]
    query: [{name: commit, var: commit, required: true}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, language: $language, commit: $commit, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summary of the application's health
#
# GET /system/health
# Returns: record<description: string, details: record, status: string>
# operationId: getHealth
export def "get-health" [
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
    path: "/system/health"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the identifiers and descriptions of the usage metrics
#
# GET /system/metrics
# Returns: record<data: table<description: string, metric-id: string>>
# operationId: getMetrics
export def "get-metrics" [
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
    path: "/system/metrics"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the computed values of the specified metric
#
# GET /system/metrics/{metric-id}
# Returns: record<measurements: table<timestamp: string, value: float>, metric-id: string>
# operationId: getMetric
export def "get-metric" [
  metric_id: string
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
    path: "/system/metrics/{metric-id}"
    path_params: [{name: metric-id, var: metric_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_id: $metric_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
