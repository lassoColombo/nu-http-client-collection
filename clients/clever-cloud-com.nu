# Auto-generated client for Clever-Cloud API v1.0.0
# Source: https://api.apis.guru/v2/specs/clever-cloud.com/1.0.0/openapi.json
# Auth: --token flag or $env.CLEVER_CLOUD_API_TOKEN

const CLIENT = {
  base_url: "https://api.clever-cloud.com/v2"
  token_env_var: "CLEVER_CLOUD_API_TOKEN"
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

def base-url-completer [] { ["https://api.clever-cloud.com/v2"] }
def auth-scheme-completer [] { ["none"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def type-completer [] { ["EXISTING_CARD" "NEW_CARD"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-github: "record<transactionId: string>"
    get-github-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-github-emails: "list<string>"
    get-github-keys: "table<fingerprint: string, key: string, name: string>"
    get-github-username: "string"
    get-oauth-rights: "record<description: string, name: string>"
    get-organisations: "table<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>"
    post-organisations: "record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>"
    get-organisations-id: "record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>"
    put-organisations-id: "record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>"
    get-organisations-id-addonproviders: "table<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    post-organisations-id-addonproviders: "record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    get-organisations-id-addonproviders-provider-id: "record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    put-organisations-id-addonproviders-provider-id: "record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    get-organisations-id-addonproviders-provider-id-features: "table<name: string, type: string, value: string>"
    post-organisations-id-addonproviders-provider-id-features: "record<name: string, type: string, value: string>"
    get-organisations-id-addonproviders-provider-id-plans: "table<features: list<record>, id: string, name: string, price: int, slug: string>"
    post-organisations-id-addonproviders-provider-id-plans: "record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>"
    get-organisations-id-addonproviders-provider-id-plans-plan-id: "record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>"
    put-organisations-id-addonproviders-provider-id-plans-plan-id: "record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>"
    get-organisations-id-addons-addon-id-sso: "record<macaroon: string, url: string>"
    get-organisations-id-addonproviders-provider-id-tags: "list<string>"
    get-organisations-id-addons: "table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    post-organisations-id-addons: "record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-organisations-id-addons-addon-id: "record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    put-organisations-id-addons-addon-id: "record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-organisations-id-addons-addon-id-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-organisations-id-addons-addon-id-env: "table<name: string, value: string>"
    get-organisations-id-addons-addon-id-instances: "table<appId: string, appPort: float, commitId: string, createdAt: float, deployId: string, deployNumber: float, displayName: string, flavor: record<cpus: float, mem: float, name: string, price: float>, hv: string, image: string, instanceNumber: float, internalIP: string, ip: string, ownerId: string, source: string, sshPort: float, state: string, uuid: string, zabbixPort: float, zone: string>"
    get-organisations-id-addons-addon-id-instances-instance-id: "record<appId: string, appPort: float, commitId: string, createdAt: float, deployId: string, deployNumber: float, displayName: string, flavor: record<cpus: float, mem: float, name: string, price: float>, hv: string, image: string, instanceNumber: float, internalIP: string, ip: string, ownerId: string, source: string, sshPort: float, state: string, uuid: string, zabbixPort: float, zone: string>"
    get-organisations-id-addons-addon-id-migrations: "table<addon_id: string, callback_url: string, database: string, database_user: string, dump_restore_finished_date: string, dump_restore_start_date: string, end_date: string, exit_message: string, hostname: string, id: string, kind: string, last_state_update_date: string, new_cluster_id: string, new_cluster_label: string, new_instance_id: string, new_plan: string, new_recipient_hostname: string, new_zone: string, old_cluster_id: string, old_cluster_label: string, old_instance_id: string, old_plan: string, old_recipient_hostname: string, old_zone: string, port: float, request_date: string, state: string>"
    post-organisations-id-addons-addon-id-migrations: "record"
    get-organisations-id-addons-addon-id-migrations-migration-id: "record<addon_id: string, callback_url: string, database: string, database_user: string, dump_restore_finished_date: string, dump_restore_start_date: string, end_date: string, exit_message: string, hostname: string, id: string, kind: string, last_state_update_date: string, new_cluster_id: string, new_cluster_label: string, new_instance_id: string, new_plan: string, new_recipient_hostname: string, new_zone: string, old_cluster_id: string, old_cluster_label: string, old_instance_id: string, old_plan: string, old_recipient_hostname: string, old_zone: string, port: float, request_date: string, state: string>"
    get-organisations-id-addons-addon-id-sso-1: "record<email: string, id: string, nav-data: string, timestamp: string, token: string, url: string>"
    get-organisations-id-addons-addon-id-tags: "list<string>"
    get-organisations-id-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    post-organisations-id-applications: "record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-organisations-id-applications-app-id: "record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>"
    put-organisations-id-applications-app-id: "record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-organisations-id-applications-app-id-addons: "table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-organisations-id-applications-app-id-addons-env: "table<addon_id: string, addon_name: string, env: list<record>, provider_id: string>"
    get-organisations-id-applications-app-id-dependencies: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-organisations-id-applications-app-id-dependencies-env: "table<app_id: string, app_name: string, env: list<record>>"
    get-organisations-id-applications-app-id-dependents: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-organisations-id-applications-app-id-deployments: "table<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>"
    get-organisations-id-applications-app-id-env: "table<name: string, value: string>"
    put-organisations-id-applications-app-id-env: "record<name: string, value: string>"
    put-organisations-id-applications-app-id-env-env-name: "record<name: string, value: string>"
    get-organisations-id-applications-app-id-instances: "table<appId: string, appPort: int, commit: string, deployNumber: int, flavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, id: string, ip: string, state: string>"
    get-organisations-id-applications-app-id-tags: "list<string>"
    get-organisations-id-applications-app-id-vhosts: "table<fqdn: string>"
    get-organisations-id-applications-app-id-vhosts-favourite: "record<fqdn: string>"
    get-organisations-id-consumers: "table<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>"
    get-organisations-id-consumers-key: "record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>"
    get-organisations-id-consumers-key-secret: "record<secret: string, value: string>"
    get-organisations-id-consumptions: "record<appId: string, conso: record<conso: string, date: string>>"
    get-organisations-id-credits: "record<count: float, dropPrice: record<currency: string, value: float>, ownerId: string>"
    get-organisations-id-deployments: "record<\"{app_id}\": table<action: string, author: record, cause: string, commit: string, date: string, id: int, instances: int, state: string, uuid: string>>"
    get-organisations-id-instances: "record"
    get-organisations-id-members: "table<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>"
    get-payments-providers: "table<comingSoon: bool, imgUrl: string, name: string, title: string>"
    get-products-addon-providers: "table<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    get-products-addon-providers-provider-id: "record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>"
    get-products-countries: "record<code: string, name: string>"
    get-products-countrycodes: "record<code: string, name: string>"
    get-products-instances: "table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>"
    get-products-instances-type-version: "record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: table<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>"
    get-products-zones: "table<correspondingRegion: string, internal: bool, name: string>"
    get-self: "record<address: string, admin: bool, avatar: string, canPay: bool, city: string, country: string, creationDate: int, email: string, emailValidated: bool, hasPassword: bool, id: string, lang: string, name: string, oauthApps: list<string>, phone: string, preferredMFA: string, zipcode: string>"
    get-self-addons: "table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-self-addons-addon-id: "record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-self-addons-addon-id-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-self-addons-addon-id-env: "table<name: string, value: string>"
    get-self-addons-addon-id-sso: "record<email: string, id: string, nav-data: string, timestamp: string, token: string, url: string>"
    get-self-addons-addon-id-tags: "list<string>"
    get-self-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-self-applications-app-id: "record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-self-applications-app-id-addons: "table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>"
    get-self-applications-app-id-addons-env: "table<addon_id: string, addon_name: string, env: list<record>, provider_id: string>"
    get-self-applications-app-id-dependencies: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-self-applications-app-id-dependencies-env: "table<app_id: string, app_name: string, env: list<record>>"
    get-self-applications-app-id-dependents: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-self-applications-app-id-deployments: "table<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>"
    get-self-applications-app-id-env: "table<name: string, value: string>"
    get-self-applications-app-id-instances: "table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>"
    get-self-applications-app-id-tags: "list<string>"
    get-self-applications-app-id-vhosts: "table<fqdn: string>"
    get-self-applications-app-id-vhosts-favourite: "record<fqdn: string>"
    put-self-change-password: "record<newPassword: string, oldPassword: string>"
    get-self-consumers: "table<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>"
    get-self-consumers-key: "record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>"
    get-self-consumers-key-secret: "record<secret: string, value: string>"
    get-self-consumptions: "record<appId: string, conso: record<conso: string, date: string>>"
    get-self-credits: "record<count: float, dropPrice: record<currency: string, value: float>, ownerId: string>"
    get-self-emails: "list<string>"
    get-self-id: "string"
    get-self-instances: "table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>"
    get-self-keys: "table<fingerprint: string, key: string, name: string>"
    get-self-tokens: "table<consumer: record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record, url: string>, creationDate: int, lastUtilisation: string, rights: record<description: string, name: string>, token: string>"
    get-summary: "record<organisations: table<addons: list, applications: list, avatar: string, consumers: list, id: string, name: string, providers: list, role: string>, user: record<addons: list<record>, admin: bool, applications: list<record>, avatar: string, consumers: list<record>, id: string, lang: string, name: string>>"
    get-users-id: "record<address: string, admin: bool, avatar: string, canPay: bool, city: string, country: string, creationDate: int, email: string, emailValidated: bool, hasPassword: bool, id: string, lang: string, name: string, oauthApps: list<string>, phone: string, preferredMFA: string, zipcode: string>"
    get-users-id-applications: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
    get-config-provider-env: "list<any>"
    update-config-provider-env: "list<any>"
    list-network-groups: "list<any>"
    list-network-group-members: "table<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>"
    get-network-group-member: "record<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>"
    list-network-group-peers: "list<any>"
    get-vendor-apps: "table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-openapi" "get-application-app-id-environment" "put-application-app-id-environment" "post-authorize" "get-events-event-socket" "get-github" "get-github-applications" "get-github-callback" "get-github-emails" "get-github-keys" "delete-github-link" "get-github-link" "get-github-login" "post-github-redeploy" "get-github-signup" "post-github-signup" "get-github-username" "get-logs-socket-app-id" "get-logs-drains" "put-logs-drains-drain-id" "get-logs-logs-chunked-app-id" "get-logs-logs-socket-app-id" "get-logs-app-id" "get-logs-app-id-drains" "post-logs-app-id-drains" "delete-logs-app-id-drains-id-or-url" "get-logs-app-id-drains-id-or-url" "get-logs-app-id-sse" "get-newsfeeds-blog" "get-newsfeed-engineering" "get-notifications-emailhooks-owner-id" "post-notifications-emailhooks-owner-id" "delete-notifications-emailhooks-owner-id-id" "put-notifications-emailhooks-owner-id-id" "get-notifications-info-events" "get-notifications-info-webhookformats" "get-notifications-webhooks-owner-id" "post-notifications-webhooks-owner-id" "delete-notifications-webhooks-owner-id-id" "put-notifications-webhooks-owner-id-id" "post-oauth-access-token" "post-oauth-access-token-query" "get-oauth-authorize" "post-oauth-authorize" "post-oauth-request-token" "post-oauth-request-token-query" "get-oauth-rights" "get-openapi-type" "get-organisations" "post-organisations" "delete-organisations-id" "get-organisations-id" "put-organisations-id" "get-organisations-id-addonproviders" "post-organisations-id-addonproviders" "delete-organisations-id-addonproviders-provider-id" "get-organisations-id-addonproviders-provider-id" "put-organisations-id-addonproviders-provider-id" "get-organisations-id-addonproviders-provider-id-features" "post-organisations-id-addonproviders-provider-id-features" "delete-organisations-id-addonproviders-provider-id-features-feature-id" "get-organisations-id-addonproviders-provider-id-plans" "post-organisations-id-addonproviders-provider-id-plans" "delete-organisations-id-addonproviders-provider-id-plans-plan-id" "get-organisations-id-addonproviders-provider-id-plans-plan-id" "put-organisations-id-addonproviders-provider-id-plans-plan-id" "delete-organisations-id-addonproviders-provider-id-plans-plan-id-features-feature-name" "put-organisations-id-addonproviders-provider-id-plans-plan-id-features-feature-name" "get-organisations-id-addons-addon-id-sso" "get-organisations-id-addonproviders-provider-id-tags" "post-organisations-id-addonproviders-provider-id-testers" "get-organisations-id-addons" "post-organisations-id-addons" "post-organisations-id-addons-preorders" "delete-organisations-id-addons-addon-id" "get-organisations-id-addons-addon-id" "put-organisations-id-addons-addon-id" "get-organisations-id-addons-addon-id-applications" "get-organisations-id-addons-addon-id-env" "get-organisations-id-addons-addon-id-instances" "get-organisations-id-addons-addon-id-instances-instance-id" "get-organisations-id-addons-addon-id-migrations" "post-organisations-id-addons-addon-id-migrations" "get-organisations-id-addons-addon-id-migrations-migration-id" "get-organisations-id-addons-addon-id-sso-1" "get-organisations-id-addons-addon-id-tags" "delete-organisations-id-addons-addon-id-tags-tag" "put-organisations-id-addons-addon-id-tags-tag" "get-organisations-id-applications" "post-organisations-id-applications" "delete-organisations-id-applications-app-id" "get-organisations-id-applications-app-id" "put-organisations-id-applications-app-id" "get-organisations-id-applications-app-id-addons" "post-organisations-id-applications-app-id-addons" "get-organisations-id-applications-app-id-addons-env" "delete-organisations-id-applications-app-id-addons-addon-id" "put-organisations-id-applications-app-id-branch" "get-organisations-id-applications-app-id-branches" "put-organisations-id-applications-app-id-buildflavor" "get-organisations-id-applications-app-id-dependencies" "get-organisations-id-applications-app-id-dependencies-env" "delete-organisations-id-applications-app-id-dependencies-dependency-id" "put-organisations-id-applications-app-id-dependencies-dependency-id" "get-organisations-id-applications-app-id-dependents" "get-organisations-id-applications-app-id-deployments" "get-organisations-id-applications-app-id-deployments-deployment-id" "delete-organisations-id-applications-app-id-deployments-deployment-id-instances" "get-organisations-id-applications-app-id-env" "put-organisations-id-applications-app-id-env" "delete-organisations-id-applications-app-id-env-env-name" "put-organisations-id-applications-app-id-env-env-name" "get-organisations-id-applications-app-id-exposed-env" "put-organisations-id-applications-app-id-exposed-env" "delete-organisations-id-applications-app-id-instances" "get-organisations-id-applications-app-id-instances" "post-organisations-id-applications-app-id-instances" "get-organisations-id-applications-app-id-instances-instance-id" "get-organisations-id-applications-app-id-tags" "delete-organisations-id-applications-app-id-tags-tag" "put-organisations-id-applications-app-id-tags-tag" "get-organisations-id-applications-app-id-vhosts" "delete-organisations-id-applications-app-id-vhosts-favourite" "get-organisations-id-applications-app-id-vhosts-favourite" "put-organisations-id-applications-app-id-vhosts-favourite" "delete-organisations-id-applications-app-id-vhosts-domain" "put-organisations-id-applications-app-id-vhosts-domain" "put-organisations-id-avatar" "get-organisations-id-consumers" "post-organisations-id-consumers" "delete-organisations-id-consumers-key" "get-organisations-id-consumers-key" "put-organisations-id-consumers-key" "get-organisations-id-consumers-key-secret" "get-organisations-id-consumptions" "get-organisations-id-credits" "get-organisations-id-deployments" "get-organisations-id-instances" "get-organisations-id-members" "post-organisations-id-members" "delete-organisations-id-members-user-id" "put-organisations-id-members-user-id" "get-organisations-id-payment-info" "get-organisations-id-payments-billings" "post-organisations-id-payments-billings" "get-organisations-id-payments-billings-unpaid" "delete-organisations-id-payments-billings-bid" "get-organisations-id-payments-billings-bid" "put-organisations-id-payments-billings-bid" "get-organisations-id-payments-billings-bid-pdf" "get-organisations-id-payments-full-price-price" "get-organisations-id-payments-methods" "post-organisations-id-payments-methods" "get-organisations-id-payments-methods-default" "put-organisations-id-payments-methods-default" "delete-organisations-id-payments-methods-m-id" "get-organisations-id-payments-monthlyinvoice" "put-organisations-id-payments-monthlyinvoice-maxcredit" "delete-organisations-id-payments-recurring" "get-organisations-id-payments-recurring" "get-password-forgotten" "post-password-forgotten" "get-password-forgotten-key" "post-password-forgotten-key" "get-payments-assets-pay-button-token-button-png" "get-payments-coupons-name" "get-payments-providers" "get-payments-tokens-stripe" "post-payments-bid-end-stripe" "get-products-addon-providers" "get-products-addon-providers-provider-id" "get-products-addonproviders-provider-id-versions" "get-products-countries" "get-products-countrycodes" "get-products-instances" "get-products-instances-type-version" "get-products-mfa-kinds" "get-products-packages" "get-products-prices" "get-products-zones" "delete-self" "get-self" "put-self" "get-self-addons" "post-self-addons" "post-self-addons-preorders" "delete-self-addons-addon-id" "get-self-addons-addon-id" "put-self-addons-addon-id" "get-self-addons-addon-id-applications" "get-self-addons-addon-id-env" "put-self-addons-addon-id-plan" "get-self-addons-addon-id-sso" "get-self-addons-addon-id-tags" "delete-self-addons-addon-id-tags-tag" "put-self-addons-addon-id-tags-tag" "get-self-applications" "post-self-applications" "delete-self-applications-app-id" "get-self-applications-app-id" "put-self-applications-app-id" "get-self-applications-app-id-addons" "post-self-applications-app-id-addons" "get-self-applications-app-id-addons-env" "delete-self-applications-app-id-addons-addon-id" "put-self-applications-app-id-branch" "get-self-applications-app-id-branches" "put-self-applications-app-id-buildflavor" "get-self-applications-app-id-dependencies" "get-self-applications-app-id-dependencies-env" "delete-self-applications-app-id-dependencies-dependency-id" "get-self-applications-app-id-dependencies-dependency-id" "get-self-applications-app-id-dependents" "get-self-applications-app-id-deployments" "get-self-applications-app-id-deployments-deployment-id" "delete-self-applications-app-id-deployments-deployment-id-instances" "get-self-applications-app-id-env" "put-self-applications-app-id-env" "delete-self-applications-app-id-env-env-name" "put-self-applications-app-id-env-env-name" "get-self-applications-app-id-exposed-env" "put-self-applications-app-id-exposed-env" "delete-self-applications-app-id-instances" "get-self-applications-app-id-instances" "post-self-applications-app-id-instances" "get-self-applications-app-id-instances-instance-id" "get-self-applications-app-id-tags" "delete-self-applications-app-id-tags-tag" "put-self-applications-app-id-tags-tag" "get-self-applications-app-id-vhosts" "delete-self-applications-app-id-vhosts-favourite" "get-self-applications-app-id-vhosts-favourite" "put-self-applications-app-id-vhosts-favourite" "delete-self-applications-app-id-vhosts-domain" "put-self-applications-app-id-vhosts-domain" "put-self-avatar" "put-self-change-password" "get-self-cli-tokens" "get-self-confirmation-email" "get-self-consumers" "post-self-consumers" "delete-self-consumers-key" "get-self-consumers-key" "put-self-consumers-key" "get-self-consumers-key-secret" "get-self-consumptions" "get-self-credits" "get-self-emails" "delete-self-emails-email" "put-self-emails-email" "get-self-id" "get-self-instances" "get-self-keys" "delete-self-keys-key" "put-self-keys-key" "delete-self-mfa-kind" "post-self-mfa-kind" "put-self-mfa-kind" "get-self-mfa-kind-backupcodes" "post-self-mfa-kind-confirmation" "get-self-payment-info" "get-self-payments-billings" "post-self-payments-billings" "delete-self-payments-billings-bid" "get-self-payments-billings-bid" "put-self-payments-billings-bid" "get-self-payments-billings-bid-pdf" "get-self-payments-fullprice-price" "get-self-payments-methods" "post-self-payments-methods" "get-self-payments-methods-default" "put-self-payments-methods-default" "delete-self-payments-methods-m-id" "get-self-payments-monthlyinvoice" "put-self-payments-monthlyinvoice-maxcredit" "delete-self-payments-recurring" "get-self-payments-recurring" "get-self-payments-tokens-stripe" "delete-self-tokens" "get-self-tokens" "delete-self-tokens-token" "get-self-validate-email" "get-summary" "post-users" "get-users-id" "get-users-id-applications" "get-users-user-id-git-info" "create-matomo" "delete-matomo" "get-v3-logs-app-id" "get-v3-logs-app-id-drains" "post-v3-logs-app-id-drains" "delete-v3-logs-app-id-drains-id-or-url" "get-v3-logs-app-id-drains-id-or-url" "get-v3-logs-app-id-logs-chunked" "get-v3-logs-app-id-logs-socket" "get-matomo" "get-matomo-k-token-validation" "get-config-provider" "get-config-provider-env" "update-config-provider-env" "list-network-groups" "create-network-group" "delete-network-group" "get-network-group" "create-network-group-external-peer" "delete-network-group-external-peer" "list-network-group-members" "create-network-group-member" "delete-network-group-member" "get-network-group-member" "list-network-group-peers" "delete-network-group-peer" "get-network-group-peer" "get-network-group-wire-guard-configuration" "get-network-group-wire-guard-configuration-stream" "get-network-group-stream" "post-vendor-addons" "get-vendor-apps-addon-id-logscollector" "get-vendor-apps" "get-vendor-apps-addon-id" "put-vendor-apps-addon-id" "post-vendor-billing-owner-id" "put-vendor-apps-addon-id-migration-callback" "commands"] | sort) } | get name | first)
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

# GET //openapi
export def "get-openapi" [
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
    path: "//openapi"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /application/{appId}/environment
export def "get-application-app-id-environment" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/application/{appId}/environment"
    path_params: [{name: appId, var: app_id}]
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /application/{appId}/environment
export def "put-application-app-id-environment" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # (spec name: token)
]: nothing -> any {
  http-request {
    method: put
    path: "/application/{appId}/environment"
    path_params: [{name: appId, var: app_id}]
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handled by our API.
#
# POST /authorize
# operationId: postAuthorize
export def "post-authorize" [
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
    path: "/authorize"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve events as they come through a websocket connection. To have authorization, you have to send a `{ "message_type": "oauth", "authorization": "oauth authorization string" }` message
#
# GET /events/event-socket
export def "get-events-event-socket" [
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
    path: "/events/event-socket"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github
#
# Returns: record<transactionId: string>
# operationId: getGithub
export def "get-github" [
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
    path: "/github"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getGithubApplications
export def "get-github-applications" [
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
    path: "/github/applications"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/callback
#
# operationId: getGithubCallback
export def "get-github-callback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --state: string
  --error: string
  --error-description: string
  --error-uri: string
  --cookie: string
]: nothing -> any {
  http-request {
    method: get
    path: "/github/callback"
    query: [{name: code, var: code}, {name: state, var: state}, {name: error, var: error}, {name: error_description, var: error_description}, {name: error_uri, var: error_uri}]
    header: [{name: Cookie, var: cookie}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, state: $state, error: $error, error_description: $error_description, error_uri: $error_uri, cookie: $cookie
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/emails
#
# Returns: list<string>
# operationId: getGithubEmails
export def "get-github-emails" [
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
    path: "/github/emails"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/keys
#
# Returns: table<fingerprint: string, key: string, name: string>
# operationId: getGithubKeys
export def "get-github-keys" [
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
    path: "/github/keys"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /github/link
#
# operationId: deleteGithubLink
export def "delete-github-link" [
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
    path: "/github/link"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/link
#
# operationId: getGithubLink
export def "get-github-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction-id: string # From GET /github
  --redirect-url: string
]: nothing -> any {
  http-request {
    method: get
    path: "/github/link"
    query: [{name: transactionId, var: transaction_id}, {name: redirectUrl, var: redirect_url}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transaction_id: $transaction_id, redirect_url: $redirect_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/login
#
# operationId: getGithubLogin
export def "get-github-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-url: string
  --from-authorize: string
]: nothing -> any {
  http-request {
    method: get
    path: "/github/login"
    query: [{name: redirectUrl, var: redirect_url}, {name: fromAuthorize, var: from_authorize}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    redirect_url: $redirect_url, from_authorize: $from_authorize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /github/redeploy
#
# operationId: postGithubRedeploy
export def "post-github-redeploy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string
  --x-github-event: string
  --x-hub-signature: string
]: nothing -> any {
  http-request {
    method: post
    path: "/github/redeploy"
    header: [{name: User-Agent, var: user_agent}, {name: X-Github-Event, var: x_github_event}, {name: X-Hub-Signature, var: x_hub_signature}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_agent: $user_agent, x_github_event: $x_github_event, x_hub_signature: $x_hub_signature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/signup
#
# operationId: getGithubSignup
export def "get-github-signup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-url: string
  --from-authorize: string
]: nothing -> any {
  http-request {
    method: get
    path: "/github/signup"
    query: [{name: redirectUrl, var: redirect_url}, {name: fromAuthorize, var: from_authorize}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    redirect_url: $redirect_url, from_authorize: $from_authorize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /github/signup
#
# operationId: postGithubSignup
export def "post-github-signup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction-id: string
  --name: string
  --other-id: string
  --other-email: string
  --password: string
  --auto-link: string
  --terms: string
]: nothing -> any {
  http-request {
    method: post
    path: "/github/signup"
    query: [{name: transactionId, var: transaction_id}, {name: name, var: name}, {name: otherId, var: other_id}, {name: otherEmail, var: other_email}, {name: password, var: password}, {name: autoLink, var: auto_link}, {name: terms, var: terms}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transaction_id: $transaction_id, name: $name, other_id: $other_id, other_email: $other_email, password: $password, auto_link: $auto_link, terms: $terms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /github/username
#
# Returns: string
# operationId: getGithubUsername
export def "get-github-username" [
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
    path: "/github/username"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# WebSocket to get logs for :appID. Optional queryString arg bind_to_es=true to bind WS on log storage and not real time AMQP broker
#
# GET /logs-socket/{appId}
export def "get-logs-socket-app-id" [
  app_id: string
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
    path: "/logs-socket/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all the logs drains (ccadmin dedicated route)
#
# GET /logs/drains
export def "get-logs-drains" [
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
    path: "/logs/drains"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all the logs drains (ccadmin dedicated route)
#
# PUT /logs/drains/{drainId}
export def "put-logs-drains-drain-id" [
  drain_id: string
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
    path: "/logs/drains/{drainId}"
    path_params: [{name: drainId, var: drain_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    drain_id: $drain_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve logs as they come through a chunked, never-ending response
#
# GET /logs/logs-chunked/{appId}
export def "get-logs-logs-chunked-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --download: oneof<nothing, bool> # Tell the user-agent to download the body as a file
]: nothing -> any {
  http-request {
    method: get
    path: "/logs/logs-chunked/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: download, var: download}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id, download: $download
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve logs as they come through a websocket connection. To have authorization, you have to send a `{ "message_type": "oauth", "authorization": "oauth authorization string" }` message
#
# GET /logs/logs-socket/{appId}
export def "get-logs-logs-socket-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Only fetch logs newer than this (ISO-8601 formatted) date (format: date-time)
  --filter: string # A pattern to filter with
  --deployment-id: string # Only fetch logs emitted by this deployment
]: nothing -> any {
  http-request {
    method: get
    path: "/logs/logs-socket/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: since, var: since}, {name: filter, var: filter}, {name: deployment_id, var: deployment_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id, since: $since, filter: $filter, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs for a given application
#
# GET /logs/{appId}
export def "get-logs-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of lines to return (format: int32)
  --order: string@order-completer # Logs order (default: desc)
  --after: string # Lowest bound for logs date, ISO 8601 (format: date-time)
  --before: string # Highest bounds for logs date, ISO 8601 (format: date-time)
  --filter: string # A pattern to filter with
  --deployment-id: string # Only fetch logs emitted by this deployment
]: nothing -> any {
  http-request {
    method: get
    path: "/logs/{appId}"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: order, var: order}, {name: after, var: after}, {name: before, var: before}, {name: filter, var: filter}, {name: deployment_id, var: deployment_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id, limit: $limit, order: $order, after: $after, before: $before, filter: $filter, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs drains for a given application
#
# GET /logs/{appId}/drains
export def "get-logs-app-id-drains" [
  app_id: string
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
    path: "/logs/{appId}/drains"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a log drain for a given application
#
# POST /logs/{appId}/drains
export def "post-logs-app-id-drains" [
  app_id: string
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
    path: "/logs/{appId}/drains"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the logs drain by id or url for a given application
#
# DELETE /logs/{appId}/drains/:idOrUrl
export def "delete-logs-app-id-drains-id-or-url" [
  app_id: string
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
    path: "/logs/{appId}/drains/:idOrUrl"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs drain by id or url for a given application
#
# GET /logs/{appId}/drains/:idOrUrl
export def "get-logs-app-id-drains-id-or-url" [
  app_id: string
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
    path: "/logs/{appId}/drains/:idOrUrl"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve logs as they come through a sse connection. To have authorization, you have to add `authorization=oAuthAuthorizationString` as query param.
#
# GET /logs/{appId}/sse
export def "get-logs-app-id-sse" [
  app_id: string
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
    path: "/logs/{appId}/sse"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /newsfeeds/blog
#
# operationId: getNewsfeedsBlog
export def "get-newsfeeds-blog" [
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
    path: "/newsfeeds/blog"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /newsfeeds/engineering
#
# operationId: getNewsfeedEngineering
export def "get-newsfeed-engineering" [
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
    path: "/newsfeeds/engineering"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list created e-mail hooks
#
# GET /notifications/emailhooks/{ownerId}
export def "get-notifications-emailhooks-owner-id" [
  owner_id: string
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
    path: "/notifications/emailhooks/{ownerId}"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create a hook for e-mail notifications
#
# POST /notifications/emailhooks/{ownerId}
export def "post-notifications-emailhooks-owner-id" [
  owner_id: string
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
    path: "/notifications/emailhooks/{ownerId}"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete an e-mail hook
#
# DELETE /notifications/emailhooks/{ownerId}/:id
export def "delete-notifications-emailhooks-owner-id-id" [
  owner_id: string
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
    path: "/notifications/emailhooks/{ownerId}/:id"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# edit an e-mail hook
#
# PUT /notifications/emailhooks/{ownerId}/:id
export def "put-notifications-emailhooks-owner-id-id" [
  owner_id: string
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
    path: "/notifications/emailhooks/{ownerId}/:id"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list available events
#
# GET /notifications/info/events
export def "get-notifications-info-events" [
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
    path: "/notifications/info/events"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list available webhook formats
#
# GET /notifications/info/webhookformats
export def "get-notifications-info-webhookformats" [
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
    path: "/notifications/info/webhookformats"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list created hooks
#
# GET /notifications/webhooks/{ownerId}
export def "get-notifications-webhooks-owner-id" [
  owner_id: string
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
    path: "/notifications/webhooks/{ownerId}"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# create a hook for notifications
#
# POST /notifications/webhooks/{ownerId}
export def "post-notifications-webhooks-owner-id" [
  owner_id: string
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
    path: "/notifications/webhooks/{ownerId}"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a hook
#
# DELETE /notifications/webhooks/{ownerId}/:id
export def "delete-notifications-webhooks-owner-id-id" [
  owner_id: string
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
    path: "/notifications/webhooks/{ownerId}/:id"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# edit a hook
#
# PUT /notifications/webhooks/{ownerId}/:id
export def "put-notifications-webhooks-owner-id-id" [
  owner_id: string
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
    path: "/notifications/webhooks/{ownerId}/:id"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/access_token
#
# operationId: postOauthAccessToken
export def "post-oauth-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-token: string
  --oauth-signature-method: string
  --oauth-signature: string
  --oauth-timestamp: string
  --oauth-nonce: string
  --oauth-version: string
  --oauth-verifier: string
  --oauth-callback: string
  --oauth-token-secret: string
  --oauth-callback-confirmed: string
]: nothing -> any {
  http-request {
    method: post
    path: "/oauth/access_token"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_token, var: oauth_token}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_signature, var: oauth_signature}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_version, var: oauth_version}, {name: oauth_verifier, var: oauth_verifier}, {name: oauth_callback, var: oauth_callback}, {name: oauth_token_secret, var: oauth_token_secret}, {name: oauth_callback_confirmed, var: oauth_callback_confirmed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_token: $oauth_token, oauth_signature_method: $oauth_signature_method, oauth_signature: $oauth_signature, oauth_timestamp: $oauth_timestamp, oauth_nonce: $oauth_nonce, oauth_version: $oauth_version, oauth_verifier: $oauth_verifier, oauth_callback: $oauth_callback, oauth_token_secret: $oauth_token_secret, oauth_callback_confirmed: $oauth_callback_confirmed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/access_token_query
export def "post-oauth-access-token-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-token: string
  --oauth-signature-method: string
  --oauth-signature: string
  --oauth-timestamp: string
  --oauth-nonce: string
  --oauth-version: string
  --oauth-verifier: string
  --oauth-callback: string
  --oauth-token-secret: string
  --oauth-callback-confirmed: string
]: nothing -> any {
  http-request {
    method: post
    path: "/oauth/access_token_query"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_token, var: oauth_token}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_signature, var: oauth_signature}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_version, var: oauth_version}, {name: oauth_verifier, var: oauth_verifier}, {name: oauth_callback, var: oauth_callback}, {name: oauth_token_secret, var: oauth_token_secret}, {name: oauth_callback_confirmed, var: oauth_callback_confirmed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_token: $oauth_token, oauth_signature_method: $oauth_signature_method, oauth_signature: $oauth_signature, oauth_timestamp: $oauth_timestamp, oauth_nonce: $oauth_nonce, oauth_version: $oauth_version, oauth_verifier: $oauth_verifier, oauth_callback: $oauth_callback, oauth_token_secret: $oauth_token_secret, oauth_callback_confirmed: $oauth_callback_confirmed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /oauth/authorize
#
# operationId: getOauthAuthorize
export def "get-oauth-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-token: string
  --cookie: string
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth/authorize"
    query: [{name: oauth_token, var: oauth_token}]
    header: [{name: Cookie, var: cookie}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_token: $oauth_token, cookie: $cookie
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/authorize
#
# operationId: postOauthAuthorize
export def "post-oauth-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --almighty: string
  --access-organisations: string
  --manage-organisations: string
  --manage-organisations-services: string
  --manage-organisations-applications: string
  --manage-organisations-members: string
  --access-organisations-bills: string
  --access-organisations-credit-count: string
  --access-organisations-consumption-statistics: string
  --access-personal-information: string
  --manage-personal-information: string
  --manage-ssh-keys: string
  --manage-services: string
  --manage-applications: string
  --access-bills: string
  --access-credit-count: string
  --access-consumption-statistics: string
  --cookie: string
]: nothing -> any {
  http-request {
    method: post
    path: "/oauth/authorize"
    query: [{name: almighty, var: almighty}, {name: access_organisations, var: access_organisations}, {name: manage_organisations, var: manage_organisations}, {name: manage_organisations_services, var: manage_organisations_services}, {name: manage_organisations_applications, var: manage_organisations_applications}, {name: manage_organisations_members, var: manage_organisations_members}, {name: access_organisations_bills, var: access_organisations_bills}, {name: access_organisations_credit_count, var: access_organisations_credit_count}, {name: access_organisations_consumption_statistics, var: access_organisations_consumption_statistics}, {name: access_personal_information, var: access_personal_information}, {name: manage_personal_information, var: manage_personal_information}, {name: manage_ssh_keys, var: manage_ssh_keys}, {name: manage_services, var: manage_services}, {name: manage_applications, var: manage_applications}, {name: access_bills, var: access_bills}, {name: access_credit_count, var: access_credit_count}, {name: access_consumption_statistics, var: access_consumption_statistics}]
    header: [{name: Cookie, var: cookie}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    almighty: $almighty, access_organisations: $access_organisations, manage_organisations: $manage_organisations, manage_organisations_services: $manage_organisations_services, manage_organisations_applications: $manage_organisations_applications, manage_organisations_members: $manage_organisations_members, access_organisations_bills: $access_organisations_bills, access_organisations_credit_count: $access_organisations_credit_count, access_organisations_consumption_statistics: $access_organisations_consumption_statistics, access_personal_information: $access_personal_information, manage_personal_information: $manage_personal_information, manage_ssh_keys: $manage_ssh_keys, manage_services: $manage_services, manage_applications: $manage_applications, access_bills: $access_bills, access_credit_count: $access_credit_count, access_consumption_statistics: $access_consumption_statistics, cookie: $cookie
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/request_token
#
# operationId: postOauthRequestToken
export def "post-oauth-request-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-token: string
  --oauth-signature-method: string
  --oauth-signature: string
  --oauth-timestamp: string
  --oauth-nonce: string
  --oauth-version: string
  --oauth-verifier: string
  --oauth-callback: string
  --oauth-token-secret: string
  --oauth-callback-confirmed: string
]: nothing -> any {
  http-request {
    method: post
    path: "/oauth/request_token"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_token, var: oauth_token}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_signature, var: oauth_signature}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_version, var: oauth_version}, {name: oauth_verifier, var: oauth_verifier}, {name: oauth_callback, var: oauth_callback}, {name: oauth_token_secret, var: oauth_token_secret}, {name: oauth_callback_confirmed, var: oauth_callback_confirmed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_token: $oauth_token, oauth_signature_method: $oauth_signature_method, oauth_signature: $oauth_signature, oauth_timestamp: $oauth_timestamp, oauth_nonce: $oauth_nonce, oauth_version: $oauth_version, oauth_verifier: $oauth_verifier, oauth_callback: $oauth_callback, oauth_token_secret: $oauth_token_secret, oauth_callback_confirmed: $oauth_callback_confirmed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /oauth/request_token_query
export def "post-oauth-request-token-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-token: string
  --oauth-signature-method: string
  --oauth-signature: string
  --oauth-timestamp: string
  --oauth-nonce: string
  --oauth-version: string
  --oauth-verifier: string
  --oauth-callback: string
  --oauth-token-secret: string
  --oauth-callback-confirmed: string
]: nothing -> any {
  http-request {
    method: post
    path: "/oauth/request_token_query"
    query: [{name: oauth_consumer_key, var: oauth_consumer_key}, {name: oauth_token, var: oauth_token}, {name: oauth_signature_method, var: oauth_signature_method}, {name: oauth_signature, var: oauth_signature}, {name: oauth_timestamp, var: oauth_timestamp}, {name: oauth_nonce, var: oauth_nonce}, {name: oauth_version, var: oauth_version}, {name: oauth_verifier, var: oauth_verifier}, {name: oauth_callback, var: oauth_callback}, {name: oauth_token_secret, var: oauth_token_secret}, {name: oauth_callback_confirmed, var: oauth_callback_confirmed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_consumer_key: $oauth_consumer_key, oauth_token: $oauth_token, oauth_signature_method: $oauth_signature_method, oauth_signature: $oauth_signature, oauth_timestamp: $oauth_timestamp, oauth_nonce: $oauth_nonce, oauth_version: $oauth_version, oauth_verifier: $oauth_verifier, oauth_callback: $oauth_callback, oauth_token_secret: $oauth_token_secret, oauth_callback_confirmed: $oauth_callback_confirmed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /oauth/rights
#
# Returns: record<description: string, name: string>
# operationId: getOauthRights
export def "get-oauth-rights" [
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
    path: "/oauth/rights"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the swagger for this API as {type}
#
# GET /openapi.{type}
export def "get-openapi-type" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/openapi.{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations
#
# Returns: table<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>
# operationId: getOrganisations
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
  --user: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations"
    query: [{name: user, var: user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations
#
# Returns: record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>
# operationId: postOrganisations
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
  --vat: string
  --address: string # The address of the organisation.
  --city: string # The city of the organisation.
  --company: string # The company's name of the organisation.
  --country: string # The country of the organisation.
  description: string # The description of the organisation.
  name: string # The name of the organisation.
  --zipcode: string # The zipcode of the city's organisation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations"
    body: {content_type: "application/json", kind: json, fields: [{name: VAT, var: vat}, {name: address, var: address}, {name: city, var: city}, {name: company, var: company}, {name: country, var: country}, {name: description, var: description}, {name: name, var: name}, {name: zipcode, var: zipcode}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    vat: $vat, address: $address, city: $city, company: $company, country: $country, description: $description, name: $name, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}
#
# operationId: deleteOrganisationsId
export def "delete-organisations-id" [
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
    path: "/organisations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}
#
# Returns: record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>
# operationId: getOrganisationsId
export def "get-organisations-id" [
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
    path: "/organisations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}
#
# Returns: record<VAT: string, address: string, avatar: string, city: string, company: string, country: string, description: string, id: string, name: string, vatState: string, zipcode: string>
# operationId: putOrganisationsId
export def "put-organisations-id" [
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
  --vat: string
  --address: string # The address of the organisation.
  --city: string # The city of the organisation.
  --company: string # The company's name of the organisation.
  --country: string # The country of the organisation.
  description: string # The description of the organisation.
  name: string # The name of the organisation.
  --zipcode: string # The zipcode of the city's organisation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: VAT, var: vat}, {name: address, var: address}, {name: city, var: city}, {name: company, var: company}, {name: country, var: country}, {name: description, var: description}, {name: name, var: name}, {name: zipcode, var: zipcode}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, vat: $vat, address: $address, city: $city, company: $company, country: $country, description: $description, name: $name, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders
#
# Returns: table<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: getOrganisationsIdAddonproviders
export def "get-organisations-id-addonproviders" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/addonproviders"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addonproviders
#
# Returns: record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: postOrganisationsIdAddonproviders
export def "post-organisations-id-addonproviders" [
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
  api: record # shape: {config_vars: list<string>, password: string, production?: record, regions?: list<string>, sso_salt: string, test?: record}
  --body-id: string # (spec name: id)
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addonproviders"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api, var: api}, {name: id, var: body_id, required: true}, {name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api: $api, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an add-on provider
#
# DELETE /organisations/{id}/addonproviders/{providerId}
export def "delete-organisations-id-addonproviders-provider-id" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}
#
# Returns: record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: getOrganisationsIdAddonprovidersProviderId
export def "get-organisations-id-addonproviders-provider-id" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/addonproviders/{providerId}
#
# Returns: record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: putOrganisationsIdAddonprovidersProviderId
export def "put-organisations-id-addonproviders-provider-id" [
  id: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api: record # shape: {config_vars: list<string>, password: string, production?: record, regions?: list<string>, sso_salt: string, test?: record}
  --body-id: string # (spec name: id)
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/addonproviders/{providerId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: api, var: api}, {name: id, var: body_id, required: true}, {name: name, var: name}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, api: $api, body_id: $body_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}/features
#
# Returns: table<name: string, type: string, value: string>
# operationId: getOrganisationsIdAddonprovidersProviderIdFeatures
export def "get-organisations-id-addonproviders-provider-id-features" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/features"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addonproviders/{providerId}/features
#
# Returns: record<name: string, type: string, value: string>
# operationId: postOrganisationsIdAddonprovidersProviderIdFeatures
export def "post-organisations-id-addonproviders-provider-id-features" [
  id: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  type: string # BOOLEAN, INTERVAL, FILESIZE, NUMBER, PERCENTAGE
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addonproviders/{providerId}/features"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/addonproviders/{providerId}/features/{featureId}
#
# operationId: deleteOrganisationsIdAddonprovidersProviderIdFeaturesFeatureId
export def "delete-organisations-id-addonproviders-provider-id-features-feature-id" [
  id: string
  provider_id: string
  feature_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/features/{featureId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: featureId, var: feature_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, feature_id: $feature_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}/plans
#
# Returns: table<features: list<record>, id: string, name: string, price: int, slug: string>
# operationId: getOrganisationsIdAddonprovidersProviderIdPlans
export def "get-organisations-id-addonproviders-provider-id-plans" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/plans"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addonproviders/{providerId}/plans
#
# Returns: record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>
# operationId: postOrganisationsIdAddonprovidersProviderIdPlans
export def "post-organisations-id-addonproviders-provider-id-plans" [
  id: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  features: list # item shape: {name: string, type: string, value: string}
  name: string
  price: int # format: int64
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addonproviders/{providerId}/plans"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: features, var: features}, {name: name, var: name}, {name: price, var: price}, {name: slug, var: slug}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, features: $features, name: $name, price: $price, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/addonproviders/{providerId}/plans/{planId}
#
# operationId: deleteOrganisationsIdAddonprovidersProviderIdPlansPlanId
export def "delete-organisations-id-addonproviders-provider-id-plans-plan-id" [
  id: string
  provider_id: string
  plan_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/plans/{planId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: planId, var: plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}/plans/{planId}
#
# Returns: record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>
# operationId: getOrganisationsIdAddonprovidersProviderIdPlansPlanId
export def "get-organisations-id-addonproviders-provider-id-plans-plan-id" [
  id: string
  provider_id: string
  plan_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/plans/{planId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: planId, var: plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/addonproviders/{providerId}/plans/{planId}
#
# Returns: record<features: table<name: string, type: string, value: string>, id: string, name: string, price: int, slug: string>
# operationId: putOrganisationsIdAddonprovidersProviderIdPlansPlanId
export def "put-organisations-id-addonproviders-provider-id-plans-plan-id" [
  id: string
  provider_id: string
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  features: list # item shape: {name: string, type: string, value: string}
  name: string
  price: int # format: int64
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/addonproviders/{providerId}/plans/{planId}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: planId, var: plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: features, var: features}, {name: name, var: name}, {name: price, var: price}, {name: slug, var: slug}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, plan_id: $plan_id, features: $features, name: $name, price: $price, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/addonproviders/{providerId}/plans/{planId}/features/{featureName}
#
# operationId: deleteOrganisationsIdAddonprovidersProviderIdPlansPlanIdFeaturesFeatureName
export def "delete-organisations-id-addonproviders-provider-id-plans-plan-id-features-feature-name" [
  id: string
  provider_id: string
  plan_id: string
  feature_name: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/plans/{planId}/features/{featureName}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: planId, var: plan_id}, {name: featureName, var: feature_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, plan_id: $plan_id, feature_name: $feature_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/addonproviders/{providerId}/plans/{planId}/features/{featureName}
#
# operationId: putOrganisationsIdAddonprovidersProviderIdPlansPlanIdFeaturesFeatureName
export def "put-organisations-id-addonproviders-provider-id-plans-plan-id-features-feature-name" [
  id: string
  provider_id: string
  plan_id: string
  feature_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  type: string
  value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/addonproviders/{providerId}/plans/{planId}/features/{featureName}"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}, {name: planId, var: plan_id}, {name: featureName, var: feature_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id, plan_id: $plan_id, feature_name: $feature_name, name: $name, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}/sso
#
# Returns: record<macaroon: string, url: string>
# operationId: getOrganisationsIdAddonsAddonIdSso
export def "get-organisations-id-addons-addon-id-sso" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/sso"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addonproviders/{providerId}/tags
#
# Returns: list<string>
# operationId: getOrganisationsIdAddonprovidersProviderIdTags
export def "get-organisations-id-addonproviders-provider-id-tags" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/tags"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addonproviders/{providerId}/testers
#
# operationId: postOrganisationsIdAddonprovidersProviderIdTesters
export def "post-organisations-id-addonproviders-provider-id-testers" [
  id: string
  provider_id: string
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
    path: "/organisations/{id}/addonproviders/{providerId}/testers"
    path_params: [{name: id, var: id}, {name: providerId, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons
#
# Returns: table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getOrganisationsIdAddons
export def "get-organisations-id-addons" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/addons"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addons
#
# Returns: record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: postOrganisationsIdAddons
export def "post-organisations-id-addons" [
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
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addons"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/addons/preorders
export def "post-organisations-id-addons-preorders" [
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
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addons/preorders"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/addons/{addonId}
#
# operationId: deleteOrganisationsIdAddonsAddonId
export def "delete-organisations-id-addons-addon-id" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons/{addonId}
#
# Returns: record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getOrganisationsIdAddonsAddonId
export def "get-organisations-id-addons-addon-id" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/addons/{addonId}
#
# Returns: record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: putOrganisationsIdAddonsAddonId
export def "put-organisations-id-addons-addon-id" [
  id: string
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/addons/{addonId}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons/{addonId}/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getOrganisationsIdAddonsAddonIdApplications
export def "get-organisations-id-addons-addon-id-applications" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}/applications"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons/{addonId}/env
#
# Returns: table<name: string, value: string>
# operationId: getOrganisationsIdAddonsAddonIdEnv
export def "get-organisations-id-addons-addon-id-env" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}/env"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List instances for this add-on.
#
# GET /organisations/{id}/addons/{addonId}/instances
# Returns: table<appId: string, appPort: float, commitId: string, createdAt: float, deployId: string, deployNumber: float, displayName: string, flavor: record<cpus: float, mem: float, name: string, price: float>, hv: string, image: string, instanceNumber: float, internalIP: string, ip: string, ownerId: string, source: string, sshPort: float, state: string, uuid: string, zabbixPort: float, zone: string>
export def "get-organisations-id-addons-addon-id-instances" [
  id: string
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string
  --with-deleted: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/addons/{addonId}/instances"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    query: [{name: deploymentId, var: deployment_id}, {name: withDeleted, var: with_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, deployment_id: $deployment_id, with_deleted: $with_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific instance for {addonId}
#
# GET /organisations/{id}/addons/{addonId}/instances/{instanceId}
# Returns: record<appId: string, appPort: float, commitId: string, createdAt: float, deployId: string, deployNumber: float, displayName: string, flavor: record<cpus: float, mem: float, name: string, price: float>, hv: string, image: string, instanceNumber: float, internalIP: string, ip: string, ownerId: string, source: string, sshPort: float, state: string, uuid: string, zabbixPort: float, zone: string>
export def "get-organisations-id-addons-addon-id-instances-instance-id" [
  id: string
  addon_id: string
  instance_id: string
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
    path: "/organisations/{id}/addons/{addonId}/instances/{instanceId}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}, {name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past migrations from add-on.
#
# GET /organisations/{id}/addons/{addonId}/migrations
# Returns: table<addon_id: string, callback_url: string, database: string, database_user: string, dump_restore_finished_date: string, dump_restore_start_date: string, end_date: string, exit_message: string, hostname: string, id: string, kind: string, last_state_update_date: string, new_cluster_id: string, new_cluster_label: string, new_instance_id: string, new_plan: string, new_recipient_hostname: string, new_zone: string, old_cluster_id: string, old_cluster_label: string, old_instance_id: string, old_plan: string, old_recipient_hostname: string, old_zone: string, port: float, request_date: string, state: string>
export def "get-organisations-id-addons-addon-id-migrations" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}/migrations"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a new add-on migration
#
# POST /organisations/{id}/addons/{addonId}/migrations
# Returns: record
export def "post-organisations-id-addons-addon-id-migrations" [
  id: string
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string # Id of the new plan. E.g. "plan_acddc485-79c2-4c6b-a617-c92a06c0cb0b"
  --region: string # New region. E.g. "EU", "US", "Par2"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/addons/{addonId}/migrations"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: planId, var: plan_id}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, plan_id: $plan_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a given migration
#
# GET /organisations/{id}/addons/{addonId}/migrations/{migrationId}
# Returns: record<addon_id: string, callback_url: string, database: string, database_user: string, dump_restore_finished_date: string, dump_restore_start_date: string, end_date: string, exit_message: string, hostname: string, id: string, kind: string, last_state_update_date: string, new_cluster_id: string, new_cluster_label: string, new_instance_id: string, new_plan: string, new_recipient_hostname: string, new_zone: string, old_cluster_id: string, old_cluster_label: string, old_instance_id: string, old_plan: string, old_recipient_hostname: string, old_zone: string, port: float, request_date: string, state: string>
export def "get-organisations-id-addons-addon-id-migrations-migration-id" [
  id: string
  addon_id: string
  migration_id: string
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
    path: "/organisations/{id}/addons/{addonId}/migrations/{migrationId}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}, {name: migrationId, var: migration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, migration_id: $migration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons/{addonId}/sso
#
# Returns: record<email: string, id: string, nav-data: string, timestamp: string, token: string, url: string>
export def "get-organisations-id-addons-addon-id-sso-1" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}/sso"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/addons/{addonId}/tags
#
# Returns: list<string>
# operationId: getOrganisationsIdAddonsAddonIdTags
export def "get-organisations-id-addons-addon-id-tags" [
  id: string
  addon_id: string
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
    path: "/organisations/{id}/addons/{addonId}/tags"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/addons/{addonId}/tags/{tag}
#
# operationId: deleteOrganisationsIdAddonsAddonIdTagsTag
export def "delete-organisations-id-addons-addon-id-tags-tag" [
  id: string
  addon_id: string
  tag: string
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
    path: "/organisations/{id}/addons/{addonId}/tags/{tag}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/addons/{addonId}/tags/{tag}
#
# operationId: putOrganisationsIdAddonsAddonIdTagsTag
export def "put-organisations-id-addons-addon-id-tags-tag" [
  id: string
  addon_id: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/addons/{addonId}/tags/{tag}"
    path_params: [{name: id, var: id}, {name: addonId, var: addon_id}, {name: tag, var: tag}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, addon_id: $addon_id, tag: $tag, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getOrganisationsIdApplications
export def "get-organisations-id-applications" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/applications"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an application. If you want to create a Github app, you need to replace the oauthApp field with what you will find here: https://github.com/CleverCloud/doc.clever-cloud.com/issues/179
#
# POST /organisations/{id}/applications
# Returns: record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: postOrganisationsIdApplications
export def "post-organisations-id-applications" [
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
  --archived: oneof<nothing, bool> # default: false
  --cancel-on-push: oneof<nothing, bool> # default: false
  deploy: string
  --description: string
  --enabled: oneof<nothing, bool> # default: false
  --favourite: oneof<nothing, bool> # default: false
  --homogeneous: oneof<nothing, bool> # default: false
  --instance-type: string
  --instance-variant: string
  --instance-version: string
  --max-flavor: string
  max_instances: int # format: int32
  --min-flavor: string
  min_instances: int # format: int32
  name: string
  --oauth-app: record # shape: {name?: string, owner?: string}
  --oauth-app-id: string
  --oauth-service: string
  --separate-build: oneof<nothing, bool> # default: false
  --shutdownable: oneof<nothing, bool> # default: false
  --sticky-sessions: oneof<nothing, bool> # default: false
  --tags: list<string>
  zone: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organisations/{id}/applications"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: cancelOnPush, var: cancel_on_push}, {name: deploy, var: deploy}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: favourite, var: favourite}, {name: homogeneous, var: homogeneous}, {name: instanceType, var: instance_type}, {name: instanceVariant, var: instance_variant}, {name: instanceVersion, var: instance_version}, {name: maxFlavor, var: max_flavor}, {name: maxInstances, var: max_instances}, {name: minFlavor, var: min_flavor}, {name: minInstances, var: min_instances}, {name: name, var: name}, {name: oauthApp, var: oauth_app}, {name: oauthAppId, var: oauth_app_id}, {name: oauthService, var: oauth_service}, {name: separateBuild, var: separate_build}, {name: shutdownable, var: shutdownable}, {name: stickySessions, var: sticky_sessions}, {name: tags, var: tags}, {name: zone, var: zone}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, archived: $archived, cancel_on_push: $cancel_on_push, deploy: $deploy, description: $description, enabled: $enabled, favourite: $favourite, homogeneous: $homogeneous, instance_type: $instance_type, instance_variant: $instance_variant, instance_version: $instance_version, max_flavor: $max_flavor, max_instances: $max_instances, min_flavor: $min_flavor, min_instances: $min_instances, name: $name, oauth_app: $oauth_app, oauth_app_id: $oauth_app_id, oauth_service: $oauth_service, separate_build: $separate_build, shutdownable: $shutdownable, sticky_sessions: $sticky_sessions, tags: $tags, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}
#
# operationId: deleteOrganisationsIdApplicationsAppId
export def "delete-organisations-id-applications-app-id" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}
#
# Returns: record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getOrganisationsIdApplicationsAppId
export def "get-organisations-id-applications-app-id" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}
#
# Returns: record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: putOrganisationsIdApplicationsAppId
export def "put-organisations-id-applications-app-id" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # default: false
  --cancel-on-push: oneof<nothing, bool> # default: false
  deploy: string
  --description: string
  --enabled: oneof<nothing, bool> # default: false
  --favourite: oneof<nothing, bool> # default: false
  --homogeneous: oneof<nothing, bool> # default: false
  --instance-type: string
  --instance-variant: string
  --instance-version: string
  --max-flavor: string
  max_instances: int # format: int32
  --min-flavor: string
  min_instances: int # format: int32
  name: string
  --oauth-app: record # shape: {name?: string, owner?: string}
  --oauth-app-id: string
  --oauth-service: string
  --separate-build: oneof<nothing, bool> # default: false
  --shutdownable: oneof<nothing, bool> # default: false
  --sticky-sessions: oneof<nothing, bool> # default: false
  --tags: list<string>
  zone: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: cancelOnPush, var: cancel_on_push}, {name: deploy, var: deploy}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: favourite, var: favourite}, {name: homogeneous, var: homogeneous}, {name: instanceType, var: instance_type}, {name: instanceVariant, var: instance_variant}, {name: instanceVersion, var: instance_version}, {name: maxFlavor, var: max_flavor}, {name: maxInstances, var: max_instances}, {name: minFlavor, var: min_flavor}, {name: minInstances, var: min_instances}, {name: name, var: name}, {name: oauthApp, var: oauth_app}, {name: oauthAppId, var: oauth_app_id}, {name: oauthService, var: oauth_service}, {name: separateBuild, var: separate_build}, {name: shutdownable, var: shutdownable}, {name: stickySessions, var: sticky_sessions}, {name: tags, var: tags}, {name: zone, var: zone}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, archived: $archived, cancel_on_push: $cancel_on_push, deploy: $deploy, description: $description, enabled: $enabled, favourite: $favourite, homogeneous: $homogeneous, instance_type: $instance_type, instance_variant: $instance_variant, instance_version: $instance_version, max_flavor: $max_flavor, max_instances: $max_instances, min_flavor: $min_flavor, min_instances: $min_instances, name: $name, oauth_app: $oauth_app, oauth_app_id: $oauth_app_id, oauth_service: $oauth_service, separate_build: $separate_build, shutdownable: $shutdownable, sticky_sessions: $sticky_sessions, tags: $tags, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/addons
#
# Returns: table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getOrganisationsIdApplicationsAppIdAddons
export def "get-organisations-id-applications-app-id-addons" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/addons"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/applications/{appId}/addons
#
# operationId: postOrganisationsIdApplicationsAppIdAddons
export def "post-organisations-id-applications-app-id-addons" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/organisations/{id}/applications/{appId}/addons"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/addons/env
#
# Returns: table<addon_id: string, addon_name: string, env: list<record>, provider_id: string>
# operationId: getOrganisationsIdApplicationsAppIdAddonsEnv
export def "get-organisations-id-applications-app-id-addons-env" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/addons/env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/addons/{addonId}
#
# operationId: deleteOrganisationsIdApplicationsAppIdAddonsAddonId
export def "delete-organisations-id-applications-app-id-addons-addon-id" [
  id: string
  app_id: string
  addon_id: string
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
    path: "/organisations/{id}/applications/{appId}/addons/{addonId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/branch
export def "put-organisations-id-applications-app-id-branch" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/branch"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/branches
export def "get-organisations-id-applications-app-id-branches" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/branches"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/buildflavor
export def "put-organisations-id-applications-app-id-buildflavor" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/buildflavor"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/dependencies
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getOrganisationsIdApplicationsAppIdDependencies
export def "get-organisations-id-applications-app-id-dependencies" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/dependencies"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/dependencies/env
#
# Returns: table<app_id: string, app_name: string, env: list<record>>
export def "get-organisations-id-applications-app-id-dependencies-env" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/dependencies/env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/dependencies/{dependencyId}
#
# operationId: deleteOrganisationsIdApplicationsAppIdDependenciesDependencyId
export def "delete-organisations-id-applications-app-id-dependencies-dependency-id" [
  id: string
  app_id: string
  dependency_id: string
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
    path: "/organisations/{id}/applications/{appId}/dependencies/{dependencyId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: dependencyId, var: dependency_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, dependency_id: $dependency_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/dependencies/{dependencyId}
#
# operationId: putOrganisationsIdApplicationsAppIdDependenciesDependencyId
export def "put-organisations-id-applications-app-id-dependencies-dependency-id" [
  id: string
  app_id: string
  dependency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/dependencies/{dependencyId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: dependencyId, var: dependency_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, dependency_id: $dependency_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/dependents
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getOrganisationsIdApplicationsAppIdDependents
export def "get-organisations-id-applications-app-id-dependents" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/dependents"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/deployments
#
# Returns: table<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>
# operationId: getOrganisationsIdApplicationsAppIdDeployments
export def "get-organisations-id-applications-app-id-deployments" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --offset: string
  --action: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/applications/{appId}/deployments"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: action, var: action}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, limit: $limit, offset: $offset, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/deployments/{deploymentId}
export def "get-organisations-id-applications-app-id-deployments-deployment-id" [
  id: string
  app_id: string
  deployment_id: string
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
    path: "/organisations/{id}/applications/{appId}/deployments/{deploymentId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: deploymentId, var: deployment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/deployments/{deploymentId}/instances
#
# operationId: deleteOrganisationsIdApplicationsAppIdDeploymentsDeploymentIdInstances
export def "delete-organisations-id-applications-app-id-deployments-deployment-id-instances" [
  id: string
  app_id: string
  deployment_id: string
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
    path: "/organisations/{id}/applications/{appId}/deployments/{deploymentId}/instances"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: deploymentId, var: deployment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/env
#
# Returns: table<name: string, value: string>
# operationId: getOrganisationsIdApplicationsAppIdEnv
export def "get-organisations-id-applications-app-id-env" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/env
#
# Returns: record<name: string, value: string>
# operationId: putOrganisationsIdApplicationsAppIdEnv
export def "put-organisations-id-applications-app-id-env" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/env/{envName}
#
# operationId: deleteOrganisationsIdApplicationsAppIdEnvEnvName
export def "delete-organisations-id-applications-app-id-env-env-name" [
  id: string
  app_id: string
  env_name: string
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
    path: "/organisations/{id}/applications/{appId}/env/{envName}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: envName, var: env_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, env_name: $env_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/env/{envName}
#
# Returns: record<name: string, value: string>
# operationId: putOrganisationsIdApplicationsAppIdEnvEnvName
export def "put-organisations-id-applications-app-id-env-env-name" [
  id: string
  app_id: string
  env_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/env/{envName}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: envName, var: env_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, env_name: $env_name, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/exposed_env
export def "get-organisations-id-applications-app-id-exposed-env" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/exposed_env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/exposed_env
export def "put-organisations-id-applications-app-id-exposed-env" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/exposed_env"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/instances
#
# operationId: deleteOrganisationsIdApplicationsAppIdInstances
export def "delete-organisations-id-applications-app-id-instances" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/instances"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/instances
#
# Returns: table<appId: string, appPort: int, commit: string, deployNumber: int, flavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, id: string, ip: string, state: string>
# operationId: getOrganisationsIdApplicationsAppIdInstances
export def "get-organisations-id-applications-app-id-instances" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/instances"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/applications/{appId}/instances
#
# operationId: postOrganisationsIdApplicationsAppIdInstances
export def "post-organisations-id-applications-app-id-instances" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string
]: nothing -> any {
  http-request {
    method: post
    path: "/organisations/{id}/applications/{appId}/instances"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    query: [{name: commit, var: commit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/instances/{instanceId}
export def "get-organisations-id-applications-app-id-instances-instance-id" [
  id: string
  app_id: string
  instance_id: string
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
    path: "/organisations/{id}/applications/{appId}/instances/{instanceId}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/tags
#
# Returns: list<string>
# operationId: getOrganisationsIdApplicationsAppIdTags
export def "get-organisations-id-applications-app-id-tags" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/tags"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/tags/{tag}
#
# operationId: deleteOrganisationsIdApplicationsAppIdTagsTag
export def "delete-organisations-id-applications-app-id-tags-tag" [
  id: string
  app_id: string
  tag: string
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
    path: "/organisations/{id}/applications/{appId}/tags/{tag}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/tags/{tag}
#
# operationId: putOrganisationsIdApplicationsAppIdTagsTag
export def "put-organisations-id-applications-app-id-tags-tag" [
  id: string
  app_id: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/tags/{tag}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: tag, var: tag}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, tag: $tag, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/vhosts
#
# Returns: table<fqdn: string>
# operationId: getOrganisationsIdApplicationsAppIdVhosts
export def "get-organisations-id-applications-app-id-vhosts" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/vhosts"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/vhosts/favourite
#
# operationId: deleteOrganisationsIdApplicationsAppIdVhostsFavourite
export def "delete-organisations-id-applications-app-id-vhosts-favourite" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/vhosts/favourite"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/applications/{appId}/vhosts/favourite
#
# Returns: record<fqdn: string>
# operationId: getOrganisationsIdApplicationsAppIdVhostsFavourite
export def "get-organisations-id-applications-app-id-vhosts-favourite" [
  id: string
  app_id: string
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
    path: "/organisations/{id}/applications/{appId}/vhosts/favourite"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/vhosts/favourite
#
# operationId: putOrganisationsIdApplicationsAppIdVhostsFavourite
export def "put-organisations-id-applications-app-id-vhosts-favourite" [
  id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fqdn: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/vhosts/favourite"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fqdn, var: fqdn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, fqdn: $fqdn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/applications/{appId}/vhosts/{domain}
#
# operationId: deleteOrganisationsIdApplicationsAppIdVhostsDomain
export def "delete-organisations-id-applications-app-id-vhosts-domain" [
  id: string
  app_id: string
  domain: string
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
    path: "/organisations/{id}/applications/{appId}/vhosts/{domain}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/applications/{appId}/vhosts/{domain}
#
# operationId: putOrganisationsIdApplicationsAppIdVhostsDomain
export def "put-organisations-id-applications-app-id-vhosts-domain" [
  id: string
  app_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fqdn: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/applications/{appId}/vhosts/{domain}"
    path_params: [{name: id, var: id}, {name: appId, var: app_id}, {name: domain, var: domain}]
    body: {content_type: "application/json", kind: json, fields: [{name: fqdn, var: fqdn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, domain: $domain, fqdn: $fqdn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If you want to upload an image from your computer, send the image in the body of the request without anything else.
#
# PUT /organisations/{id}/avatar
# operationId: putOrganisationsIdAvatar
export def "put-organisations-id-avatar" [
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
    method: put
    path: "/organisations/{id}/avatar"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/consumers
#
# Returns: table<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>
# operationId: getOrganisationsIdConsumers
export def "get-organisations-id-consumers" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/consumers"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/consumers
#
# operationId: postOrganisationsIdConsumers
export def "post-organisations-id-consumers" [
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
  --body-base-url: record # Must be a valid HTTP URL — shape: {url: string} (spec name: baseUrl)
  --description: string
  name: string
  --picture: string
  rights: record # shape: {activated: bool, right: string}
  url: record # Must be a valid HTTP URL — shape: {url: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/organisations/{id}/consumers"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: baseUrl, var: body_base_url, required: true}, {name: description, var: description}, {name: name, var: name}, {name: picture, var: picture}, {name: rights, var: rights}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body_base_url: $body_base_url, description: $description, name: $name, picture: $picture, rights: $rights, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/consumers/{key}
#
# operationId: deleteOrganisationsIdConsumersKey
export def "delete-organisations-id-consumers-key" [
  id: string
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
    path: "/organisations/{id}/consumers/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/consumers/{key}
#
# Returns: record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>
# operationId: getOrganisationsIdConsumersKey
export def "get-organisations-id-consumers-key" [
  id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/consumers/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/consumers/{key}
#
# operationId: putOrganisationsIdConsumersKey
export def "put-organisations-id-consumers-key" [
  id: string
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
  --body-base-url: record # Must be a valid HTTP URL — shape: {url: string} (spec name: baseUrl)
  --description: string
  name: string
  --picture: string
  rights: record # shape: {activated: bool, right: string}
  url: record # Must be a valid HTTP URL — shape: {url: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/consumers/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: baseUrl, var: body_base_url, required: true}, {name: description, var: description}, {name: name, var: name}, {name: picture, var: picture}, {name: rights, var: rights}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key, body_base_url: $body_base_url, description: $description, name: $name, picture: $picture, rights: $rights, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/consumers/{key}/secret
#
# Returns: record<secret: string, value: string>
# operationId: getOrganisationsIdConsumersKeySecret
export def "get-organisations-id-consumers-key-secret" [
  id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/consumers/{key}/secret"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/consumptions
#
# Returns: record<appId: string, conso: record<conso: string, date: string>>
# operationId: getOrganisationsIdConsumptions
export def "get-organisations-id-consumptions" [
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
  --app-id: string
  --from: string
  --to: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/consumptions"
    path_params: [{name: id, var: id}]
    query: [{name: appId, var: app_id}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, app_id: $app_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/credits
#
# Returns: record<count: float, dropPrice: record<currency: string, value: float>, ownerId: string>
# operationId: getOrganisationsIdCredits
export def "get-organisations-id-credits" [
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
    path: "/organisations/{id}/credits"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/deployments
#
# Returns: record<"{app_id}": table<action: string, author: record, cause: string, commit: string, date: string, id: int, instances: int, state: string, uuid: string>>
# operationId: getOrganisationsIdDeployments
export def "get-organisations-id-deployments" [
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
    path: "/organisations/{id}/deployments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/instances
#
# Returns: record
# operationId: getOrganisationsIdInstances
export def "get-organisations-id-instances" [
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
    path: "/organisations/{id}/instances"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/members
#
# Returns: table<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>
# operationId: getOrganisationsIdMembers
export def "get-organisations-id-members" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organisations/{id}/members"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/members
#
# operationId: postOrganisationsIdMembers
export def "post-organisations-id-members" [
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
  --invitation-key: string
  email: string
  --job: string
  role: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/organisations/{id}/members"
    path_params: [{name: id, var: id}]
    query: [{name: invitationKey, var: invitation_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: job, var: job}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, invitation_key: $invitation_key, email: $email, job: $job, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/members/{userId}
#
# operationId: deleteOrganisationsIdMembersUserId
export def "delete-organisations-id-members-user-id" [
  id: string
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
    path: "/organisations/{id}/members/{userId}"
    path_params: [{name: id, var: id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/members/{userId}
#
# operationId: putOrganisationsIdMembersUserId
export def "put-organisations-id-members-user-id" [
  id: string
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
  email: string
  --job: string
  role: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/members/{userId}"
    path_params: [{name: id, var: id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: job, var: job}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id, email: $email, job: $job, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payment-info
#
# operationId: getOrganisationsIdPaymentInfo
export def "get-organisations-id-payment-info" [
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
    path: "/organisations/{id}/payment-info"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/billings
#
# operationId: getOrganisationsIdPaymentsBillings
export def "get-organisations-id-payments-billings" [
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
    path: "/organisations/{id}/payments/billings"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/payments/billings
#
# operationId: postOrganisationsIdPaymentsBillings
export def "post-organisations-id-payments-billings" [
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
    path: "/organisations/{id}/payments/billings"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/billings/unpaid
export def "get-organisations-id-payments-billings-unpaid" [
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
    path: "/organisations/{id}/payments/billings/unpaid"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/payments/billings/{bid}
#
# operationId: deleteOrganisationsIdPaymentsBillingsBid
export def "delete-organisations-id-payments-billings-bid" [
  id: string
  bid: string
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
    path: "/organisations/{id}/payments/billings/{bid}"
    path_params: [{name: id, var: id}, {name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/billings/{bid}
#
# operationId: getOrganisationsIdPaymentsBillingsBid
export def "get-organisations-id-payments-billings-bid" [
  id: string
  bid: string
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
    path: "/organisations/{id}/payments/billings/{bid}"
    path_params: [{name: id, var: id}, {name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/payments/billings/{bid}
#
# operationId: putOrganisationsIdPaymentsBillingsBid
export def "put-organisations-id-payments-billings-bid" [
  id: string
  bid: string
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
    path: "/organisations/{id}/payments/billings/{bid}"
    path_params: [{name: id, var: id}, {name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/billings/{bid}.pdf
#
# operationId: getOrganisationsIdPaymentsBillingsBidPdf
export def "get-organisations-id-payments-billings-bid-pdf" [
  id: string
  bid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organisations/{id}/payments/billings/{bid}.pdf"
    path_params: [{name: id, var: id}, {name: bid, var: bid}]
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bid: $bid, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/fullprice/{price}
#
# operationId: getOrganisationsIdPaymentsFullPricePrice
export def "get-organisations-id-payments-full-price-price" [
  id: string
  price: string
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
    path: "/organisations/{id}/payments/fullprice/{price}"
    path_params: [{name: id, var: id}, {name: price, var: price}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, price: $price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/methods
export def "get-organisations-id-payments-methods" [
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
    path: "/organisations/{id}/payments/methods"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organisations/{id}/payments/methods
export def "post-organisations-id-payments-methods" [
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
  body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/organisations/{id}/payments/methods"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/methods/default
export def "get-organisations-id-payments-methods-default" [
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
    path: "/organisations/{id}/payments/methods/default"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/payments/methods/default
export def "put-organisations-id-payments-methods-default" [
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
  --device-data: string
  --body-token: string # (spec name: token)
  type: string@type-completer
]: any -> any {
  $in | http-request {
    method: put
    path: "/organisations/{id}/payments/methods/default"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceData, var: device_data}, {name: token, var: body_token, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, device_data: $device_data, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/payments/methods/{mId}
export def "delete-organisations-id-payments-methods-m-id" [
  id: string
  m_id: string
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
    path: "/organisations/{id}/payments/methods/{mId}"
    path_params: [{name: id, var: id}, {name: mId, var: m_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, m_id: $m_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/monthlyinvoice
export def "get-organisations-id-payments-monthlyinvoice" [
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
    path: "/organisations/{id}/payments/monthlyinvoice"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /organisations/{id}/payments/monthlyinvoice/maxcredit
export def "put-organisations-id-payments-monthlyinvoice-maxcredit" [
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
    method: put
    path: "/organisations/{id}/payments/monthlyinvoice/maxcredit"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /organisations/{id}/payments/recurring
#
# operationId: deleteOrganisationsIdPaymentsRecurring
export def "delete-organisations-id-payments-recurring" [
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
    path: "/organisations/{id}/payments/recurring"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organisations/{id}/payments/recurring
export def "get-organisations-id-payments-recurring" [
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
    path: "/organisations/{id}/payments/recurring"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /password_forgotten
#
# operationId: getPasswordForgotten
export def "get-password-forgotten" [
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
    path: "/password_forgotten"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /password_forgotten
#
# operationId: postPasswordForgotten
export def "post-password-forgotten" [
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
  --drop-tokens: string
  --tester-pass: string
]: nothing -> any {
  http-request {
    method: post
    path: "/password_forgotten"
    query: [{name: login, var: login}, {name: drop_tokens, var: drop_tokens}]
    header: [{name: TesterPass, var: tester_pass}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, drop_tokens: $drop_tokens, tester_pass: $tester_pass
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /password_forgotten/{key}
#
# operationId: getPasswordForgottenKey
export def "get-password-forgotten-key" [
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
    method: get
    path: "/password_forgotten/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /password_forgotten/{key}
#
# operationId: postPasswordForgottenKey
export def "post-password-forgotten-key" [
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
  --pass: string
  --pass2: string
]: nothing -> any {
  http-request {
    method: post
    path: "/password_forgotten/{key}"
    path_params: [{name: key, var: key}]
    query: [{name: pass, var: pass}, {name: pass2, var: pass2}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, pass: $pass, pass2: $pass2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /payments/assets/pay_button/{token}/button.png
export def "get-payments-assets-pay-button-token-button-png" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/payments/assets/pay_button/{token}/button.png"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /payments/coupons/{name}
#
# operationId: getPaymentsCouponsName
export def "get-payments-coupons-name" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/payments/coupons/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /payments/providers
#
# Returns: table<comingSoon: bool, imgUrl: string, name: string, title: string>
# operationId: getPaymentsProviders
export def "get-payments-providers" [
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
    path: "/payments/providers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /payments/tokens/stripe
#
# operationId: getPaymentsTokensStripe
export def "get-payments-tokens-stripe" [
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
    path: "/payments/tokens/stripe"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /payments/{bid}/end/stripe
export def "post-payments-bid-end-stripe" [
  bid: string
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
    path: "/payments/{bid}/end/stripe"
    path_params: [{name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/addonproviders
#
# Returns: table<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: getProductsAddonProviders
export def "get-products-addon-providers" [
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
    path: "/products/addonproviders"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/addonproviders/{provider_id}
#
# Returns: record<analyticsId: string, canUpgrade: bool, features: table<name: string, type: string, value: string>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: table<features: list, id: string, name: string, price: int, slug: string>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>
# operationId: getProductsAddonProvidersProviderId
export def "get-products-addon-providers-provider-id" [
  provider_id: string
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
    path: "/products/addonproviders/{provider_id}"
    path_params: [{name: provider_id, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/addonproviders/{provider_id}/versions
export def "get-products-addonproviders-provider-id-versions" [
  provider_id: string
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
    path: "/products/addonproviders/{provider_id}/versions"
    path_params: [{name: provider_id, var: provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/countries
#
# Returns: record<code: string, name: string>
# operationId: getProductsCountries
export def "get-products-countries" [
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
    path: "/products/countries"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/countrycodes
#
# Returns: record<code: string, name: string>
# operationId: getProductsCountrycodes
export def "get-products-countrycodes" [
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
    path: "/products/countrycodes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/instances
#
# Returns: table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>
# operationId: getProductsInstances
export def "get-products-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/instances"
    query: [{name: for, var: for}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    for: $for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/instances/{type}-{version}
#
# Returns: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: table<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>
# operationId: getProductsInstancesTypeVersion
export def "get-products-instances-type-version" [
  type: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for: string
  --app: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/instances/{type}-{version}"
    path_params: [{name: type, var: type}, {name: version, var: version}]
    query: [{name: for, var: for}, {name: app, var: app}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, version: $version, for: $for, app: $app
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/mfa_kinds
export def "get-products-mfa-kinds" [
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
    path: "/products/mfa_kinds"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/packages
#
# operationId: getProductsPackages
export def "get-products-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --coupon: string
  --orga-id: string
  --currency: string
]: nothing -> any {
  http-request {
    method: get
    path: "/products/packages"
    query: [{name: coupon, var: coupon}, {name: orgaId, var: orga_id}, {name: currency, var: currency}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    coupon: $coupon, orga_id: $orga_id, currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/prices
#
# operationId: getProductsPrices
export def "get-products-prices" [
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
    path: "/products/prices"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /products/zones
#
# Returns: table<correspondingRegion: string, internal: bool, name: string>
# operationId: getProductsZones
export def "get-products-zones" [
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
    path: "/products/zones"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self
#
# operationId: deleteSelf
export def "delete-self" [
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
    path: "/self"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about yourself
#
# GET /self
# Returns: record<address: string, admin: bool, avatar: string, canPay: bool, city: string, country: string, creationDate: int, email: string, emailValidated: bool, hasPassword: bool, id: string, lang: string, name: string, oauthApps: list<string>, phone: string, preferredMFA: string, zipcode: string>
# operationId: getSelf
export def "get-self" [
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
    path: "/self"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self
#
# operationId: putSelf
export def "put-self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string
  --city: string
  --country: string
  email: string
  --lang: string
  --name: string
  password: string
  --phone: string
  --terms: oneof<nothing, bool> # default: false
  --zipcode: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: country, var: country}, {name: email, var: email}, {name: lang, var: lang}, {name: name, var: name}, {name: password, var: password}, {name: phone, var: phone}, {name: terms, var: terms, required: true}, {name: zipcode, var: zipcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address, city: $city, country: $country, email: $email, lang: $lang, name: $name, password: $password, phone: $phone, terms: $terms, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Addon
#
# GET /self/addons
# Returns: table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getSelfAddons
export def "get-self-addons" [
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
    path: "/self/addons"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/addons
#
# operationId: postSelfAddons
export def "post-self-addons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/self/addons"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/addons/preorders
export def "post-self-addons-preorders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/self/addons/preorders"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/addons/{addonId}
#
# operationId: deleteSelfAddonsAddonId
export def "delete-self-addons-addon-id" [
  addon_id: string
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
    path: "/self/addons/{addonId}"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specific addon
#
# GET /self/addons/{addonId}
# Returns: record<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list<record>, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list<record>, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list<record>, regions: list<string>, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getSelfAddonsAddonId
export def "get-self-addons-addon-id" [
  addon_id: string
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
    path: "/self/addons/{addonId}"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/addons/{addonId}
#
# operationId: putSelfAddonsAddonId
export def "put-self-addons-addon-id" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  payment: record # shape: {deviceData?: string, token: string, type: "NEW_CARD"|"EXISTING_CARD"}
  plan: string
  provider_id: string
  region: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/addons/{addonId}"
    path_params: [{name: addonId, var: addon_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: payment, var: payment}, {name: plan, var: plan}, {name: providerId, var: provider_id}, {name: region, var: region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, name: $name, payment: $payment, plan: $plan, provider_id: $provider_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/addons/{addonId}/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getSelfAddonsAddonIdApplications
export def "get-self-addons-addon-id-applications" [
  addon_id: string
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
    path: "/self/addons/{addonId}/applications"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/addons/{addonId}/env
#
# Returns: table<name: string, value: string>
# operationId: getSelfAddonsAddonIdEnv
export def "get-self-addons-addon-id-env" [
  addon_id: string
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
    path: "/self/addons/{addonId}/env"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/addons/{addonId}/plan
#
# operationId: putSelfAddonsAddonIdPlan
export def "put-self-addons-addon-id-plan" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  features: list # item shape: {name: string, type: string, value: string}
  name: string
  price: int # format: int64
  slug: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/addons/{addonId}/plan"
    path_params: [{name: addonId, var: addon_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: features, var: features}, {name: name, var: name}, {name: price, var: price}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, features: $features, name: $name, price: $price, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/addons/{addonId}/sso
#
# Returns: record<email: string, id: string, nav-data: string, timestamp: string, token: string, url: string>
# operationId: getSelfAddonsAddonIdSso
export def "get-self-addons-addon-id-sso" [
  addon_id: string
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
    path: "/self/addons/{addonId}/sso"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/addons/{addonId}/tags
#
# Returns: list<string>
# operationId: getSelfAddonsAddonIdTags
export def "get-self-addons-addon-id-tags" [
  addon_id: string
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
    path: "/self/addons/{addonId}/tags"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/addons/{addonId}/tags/{tag}
#
# operationId: deleteSelfAddonsAddonIdTagsTag
export def "delete-self-addons-addon-id-tags-tag" [
  addon_id: string
  tag: string
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
    path: "/self/addons/{addonId}/tags/{tag}"
    path_params: [{name: addonId, var: addon_id}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/addons/{addonId}/tags/{tag}
#
# operationId: putSelfAddonsAddonIdTagsTag
export def "put-self-addons-addon-id-tags-tag" [
  addon_id: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/addons/{addonId}/tags/{tag}"
    path_params: [{name: addonId, var: addon_id}, {name: tag, var: tag}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, tag: $tag, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getSelfApplications
export def "get-self-applications" [
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
    path: "/self/applications"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an application. If you want to create a Github app, you need to replace the oauthApp field with what you will find here: https://github.com/CleverCloud/doc.clever-cloud.com/issues/179
#
# POST /self/applications
# operationId: postSelfApplications
export def "post-self-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # default: false
  --cancel-on-push: oneof<nothing, bool> # default: false
  deploy: string
  --description: string
  --enabled: oneof<nothing, bool> # default: false
  --favourite: oneof<nothing, bool> # default: false
  --homogeneous: oneof<nothing, bool> # default: false
  --instance-type: string
  --instance-variant: string
  --instance-version: string
  --max-flavor: string
  max_instances: int # format: int32
  --min-flavor: string
  min_instances: int # format: int32
  name: string
  --oauth-app: record # shape: {name?: string, owner?: string}
  --oauth-app-id: string
  --oauth-service: string
  --separate-build: oneof<nothing, bool> # default: false
  --shutdownable: oneof<nothing, bool> # default: false
  --sticky-sessions: oneof<nothing, bool> # default: false
  --tags: list<string>
  zone: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/self/applications"
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: cancelOnPush, var: cancel_on_push}, {name: deploy, var: deploy}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: favourite, var: favourite}, {name: homogeneous, var: homogeneous}, {name: instanceType, var: instance_type}, {name: instanceVariant, var: instance_variant}, {name: instanceVersion, var: instance_version}, {name: maxFlavor, var: max_flavor}, {name: maxInstances, var: max_instances}, {name: minFlavor, var: min_flavor}, {name: minInstances, var: min_instances}, {name: name, var: name}, {name: oauthApp, var: oauth_app}, {name: oauthAppId, var: oauth_app_id}, {name: oauthService, var: oauth_service}, {name: separateBuild, var: separate_build}, {name: shutdownable, var: shutdownable}, {name: stickySessions, var: sticky_sessions}, {name: tags, var: tags}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    archived: $archived, cancel_on_push: $cancel_on_push, deploy: $deploy, description: $description, enabled: $enabled, favourite: $favourite, homogeneous: $homogeneous, instance_type: $instance_type, instance_variant: $instance_variant, instance_version: $instance_version, max_flavor: $max_flavor, max_instances: $max_instances, min_flavor: $min_flavor, min_instances: $min_instances, name: $name, oauth_app: $oauth_app, oauth_app_id: $oauth_app_id, oauth_service: $oauth_service, separate_build: $separate_build, shutdownable: $shutdownable, sticky_sessions: $sticky_sessions, tags: $tags, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}
#
# operationId: deleteSelfApplicationsAppId
export def "delete-self-applications-app-id" [
  app_id: string
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
    path: "/self/applications/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}
#
# Returns: record<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: table<fqdn: string>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getSelfApplicationsAppId
export def "get-self-applications-app-id" [
  app_id: string
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
    path: "/self/applications/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}
#
# operationId: putSelfApplicationsAppId
export def "put-self-applications-app-id" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # default: false
  --cancel-on-push: oneof<nothing, bool> # default: false
  deploy: string
  --description: string
  --enabled: oneof<nothing, bool> # default: false
  --favourite: oneof<nothing, bool> # default: false
  --homogeneous: oneof<nothing, bool> # default: false
  --instance-type: string
  --instance-variant: string
  --instance-version: string
  --max-flavor: string
  max_instances: int # format: int32
  --min-flavor: string
  min_instances: int # format: int32
  name: string
  --oauth-app: record # shape: {name?: string, owner?: string}
  --oauth-app-id: string
  --oauth-service: string
  --separate-build: oneof<nothing, bool> # default: false
  --shutdownable: oneof<nothing, bool> # default: false
  --sticky-sessions: oneof<nothing, bool> # default: false
  --tags: list<string>
  zone: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: cancelOnPush, var: cancel_on_push}, {name: deploy, var: deploy}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: favourite, var: favourite}, {name: homogeneous, var: homogeneous}, {name: instanceType, var: instance_type}, {name: instanceVariant, var: instance_variant}, {name: instanceVersion, var: instance_version}, {name: maxFlavor, var: max_flavor}, {name: maxInstances, var: max_instances}, {name: minFlavor, var: min_flavor}, {name: minInstances, var: min_instances}, {name: name, var: name}, {name: oauthApp, var: oauth_app}, {name: oauthAppId, var: oauth_app_id}, {name: oauthService, var: oauth_service}, {name: separateBuild, var: separate_build}, {name: shutdownable, var: shutdownable}, {name: stickySessions, var: sticky_sessions}, {name: tags, var: tags}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, archived: $archived, cancel_on_push: $cancel_on_push, deploy: $deploy, description: $description, enabled: $enabled, favourite: $favourite, homogeneous: $homogeneous, instance_type: $instance_type, instance_variant: $instance_variant, instance_version: $instance_version, max_flavor: $max_flavor, max_instances: $max_instances, min_flavor: $min_flavor, min_instances: $min_instances, name: $name, oauth_app: $oauth_app, oauth_app_id: $oauth_app_id, oauth_service: $oauth_service, separate_build: $separate_build, shutdownable: $shutdownable, sticky_sessions: $sticky_sessions, tags: $tags, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/addons
#
# Returns: table<configKeys: list<string>, creationDate: string, id: string, name: string, plan: record<features: list, id: string, name: string, price: int, slug: string>, provider: record<analyticsId: string, canUpgrade: bool, features: list, googlePlusName: string, id: string, logoUrl: string, longDesc: string, name: string, openInNewTab: bool, plans: list, regions: list, shortDesc: string, status: string, supportEmail: string, twitterName: string, website: string>, realId: string, region: string>
# operationId: getSelfApplicationsAppIdAddons
export def "get-self-applications-app-id-addons" [
  app_id: string
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
    path: "/self/applications/{appId}/addons"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/applications/{appId}/addons
#
# operationId: postSelfApplicationsAppIdAddons
export def "post-self-applications-app-id-addons" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/self/applications/{appId}/addons"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/addons/env
#
# Returns: table<addon_id: string, addon_name: string, env: list<record>, provider_id: string>
# operationId: getSelfApplicationsAppIdAddonsEnv
export def "get-self-applications-app-id-addons-env" [
  app_id: string
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
    path: "/self/applications/{appId}/addons/env"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/addons/{addonId}
#
# operationId: deleteSelfApplicationsAppIdAddonsAddonId
export def "delete-self-applications-app-id-addons-addon-id" [
  app_id: string
  addon_id: string
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
    path: "/self/applications/{appId}/addons/{addonId}"
    path_params: [{name: appId, var: app_id}, {name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/branch
export def "put-self-applications-app-id-branch" [
  app_id: string
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
    path: "/self/applications/{appId}/branch"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/branches
export def "get-self-applications-app-id-branches" [
  app_id: string
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
    path: "/self/applications/{appId}/branches"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/buildflavor
export def "put-self-applications-app-id-buildflavor" [
  app_id: string
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
    path: "/self/applications/{appId}/buildflavor"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/dependencies
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getSelfApplicationsAppIdDependencies
export def "get-self-applications-app-id-dependencies" [
  app_id: string
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
    path: "/self/applications/{appId}/dependencies"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/dependencies/env
#
# Returns: table<app_id: string, app_name: string, env: list<record>>
export def "get-self-applications-app-id-dependencies-env" [
  app_id: string
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
    path: "/self/applications/{appId}/dependencies/env"
    path_params: [{name: appId, var: app_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/dependencies/{dependencyId}
#
# operationId: deleteSelfApplicationsAppIdDependenciesDependencyId
export def "delete-self-applications-app-id-dependencies-dependency-id" [
  app_id: string
  dependency_id: string
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
    path: "/self/applications/{appId}/dependencies/{dependencyId}"
    path_params: [{name: appId, var: app_id}, {name: dependencyId, var: dependency_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, dependency_id: $dependency_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/dependencies/{dependencyId}
#
# operationId: getSelfApplicationsAppIdDependenciesDependencyId
export def "get-self-applications-app-id-dependencies-dependency-id" [
  app_id: string
  dependency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # default: false
  --cancel-on-push: oneof<nothing, bool> # default: false
  deploy: string
  --description: string
  --enabled: oneof<nothing, bool> # default: false
  --favourite: oneof<nothing, bool> # default: false
  --homogeneous: oneof<nothing, bool> # default: false
  --instance-type: string
  --instance-variant: string
  --instance-version: string
  --max-flavor: string
  max_instances: int # format: int32
  --min-flavor: string
  min_instances: int # format: int32
  name: string
  --oauth-app: record # shape: {name?: string, owner?: string}
  --oauth-app-id: string
  --oauth-service: string
  --separate-build: oneof<nothing, bool> # default: false
  --shutdownable: oneof<nothing, bool> # default: false
  --sticky-sessions: oneof<nothing, bool> # default: false
  --tags: list<string>
  zone: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/dependencies/{dependencyId}"
    path_params: [{name: appId, var: app_id}, {name: dependencyId, var: dependency_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: cancelOnPush, var: cancel_on_push}, {name: deploy, var: deploy}, {name: description, var: description}, {name: enabled, var: enabled, required: true}, {name: favourite, var: favourite}, {name: homogeneous, var: homogeneous}, {name: instanceType, var: instance_type}, {name: instanceVariant, var: instance_variant}, {name: instanceVersion, var: instance_version}, {name: maxFlavor, var: max_flavor}, {name: maxInstances, var: max_instances}, {name: minFlavor, var: min_flavor}, {name: minInstances, var: min_instances}, {name: name, var: name}, {name: oauthApp, var: oauth_app}, {name: oauthAppId, var: oauth_app_id}, {name: oauthService, var: oauth_service}, {name: separateBuild, var: separate_build}, {name: shutdownable, var: shutdownable}, {name: stickySessions, var: sticky_sessions}, {name: tags, var: tags}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, dependency_id: $dependency_id, archived: $archived, cancel_on_push: $cancel_on_push, deploy: $deploy, description: $description, enabled: $enabled, favourite: $favourite, homogeneous: $homogeneous, instance_type: $instance_type, instance_variant: $instance_variant, instance_version: $instance_version, max_flavor: $max_flavor, max_instances: $max_instances, min_flavor: $min_flavor, min_instances: $min_instances, name: $name, oauth_app: $oauth_app, oauth_app_id: $oauth_app_id, oauth_service: $oauth_service, separate_build: $separate_build, shutdownable: $shutdownable, sticky_sessions: $sticky_sessions, tags: $tags, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/dependents
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getSelfApplicationsAppIdDependents
export def "get-self-applications-app-id-dependents" [
  app_id: string
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
    path: "/self/applications/{appId}/dependents"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/deployments
#
# Returns: table<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>
# operationId: getSelfApplicationsAppIdDeployments
export def "get-self-applications-app-id-deployments" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --offset: string
  --action: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/self/applications/{appId}/deployments"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: action, var: action}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, limit: $limit, offset: $offset, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/deployments/{deploymentId}
export def "get-self-applications-app-id-deployments-deployment-id" [
  app_id: string
  deployment_id: string
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
    path: "/self/applications/{appId}/deployments/{deploymentId}"
    path_params: [{name: appId, var: app_id}, {name: deploymentId, var: deployment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/deployments/{deploymentId}/instances
#
# operationId: deleteSelfApplicationsAppIdDeploymentsDeploymentIdInstances
export def "delete-self-applications-app-id-deployments-deployment-id-instances" [
  app_id: string
  deployment_id: string
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
    path: "/self/applications/{appId}/deployments/{deploymentId}/instances"
    path_params: [{name: appId, var: app_id}, {name: deploymentId, var: deployment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/env
#
# Returns: table<name: string, value: string>
# operationId: getSelfApplicationsAppIdEnv
export def "get-self-applications-app-id-env" [
  app_id: string
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
    path: "/self/applications/{appId}/env"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/env
#
# operationId: putSelfApplicationsAppIdEnv
export def "put-self-applications-app-id-env" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/env"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/env/{envName}
#
# operationId: deleteSelfApplicationsAppIdEnvEnvName
export def "delete-self-applications-app-id-env-env-name" [
  app_id: string
  env_name: string
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
    path: "/self/applications/{appId}/env/{envName}"
    path_params: [{name: appId, var: app_id}, {name: envName, var: env_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, env_name: $env_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/env/{envName}
#
# operationId: putSelfApplicationsAppIdEnvEnvName
export def "put-self-applications-app-id-env-env-name" [
  app_id: string
  env_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  value: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/env/{envName}"
    path_params: [{name: appId, var: app_id}, {name: envName, var: env_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, env_name: $env_name, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/exposed_env
export def "get-self-applications-app-id-exposed-env" [
  app_id: string
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
    path: "/self/applications/{appId}/exposed_env"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/exposed_env
export def "put-self-applications-app-id-exposed-env" [
  app_id: string
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
    path: "/self/applications/{appId}/exposed_env"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/instances
#
# operationId: deleteSelfApplicationsAppIdInstances
export def "delete-self-applications-app-id-instances" [
  app_id: string
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
    path: "/self/applications/{appId}/instances"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/instances
#
# Returns: table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>
# operationId: getSelfApplicationsAppIdInstances
export def "get-self-applications-app-id-instances" [
  app_id: string
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
    path: "/self/applications/{appId}/instances"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/applications/{appId}/instances
#
# operationId: postSelfApplicationsAppIdInstances
export def "post-self-applications-app-id-instances" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string
]: nothing -> any {
  http-request {
    method: post
    path: "/self/applications/{appId}/instances"
    path_params: [{name: appId, var: app_id}]
    query: [{name: commit, var: commit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/instances/{instanceId}
export def "get-self-applications-app-id-instances-instance-id" [
  app_id: string
  instance_id: string
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
    path: "/self/applications/{appId}/instances/{instanceId}"
    path_params: [{name: appId, var: app_id}, {name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/tags
#
# Returns: list<string>
# operationId: getSelfApplicationsAppIdTags
export def "get-self-applications-app-id-tags" [
  app_id: string
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
    path: "/self/applications/{appId}/tags"
    path_params: [{name: appId, var: app_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/tags/{tag}
#
# operationId: deleteSelfApplicationsAppIdTagsTag
export def "delete-self-applications-app-id-tags-tag" [
  app_id: string
  tag: string
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
    path: "/self/applications/{appId}/tags/{tag}"
    path_params: [{name: appId, var: app_id}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/tags/{tag}
#
# operationId: putSelfApplicationsAppIdTagsTag
export def "put-self-applications-app-id-tags-tag" [
  app_id: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/tags/{tag}"
    path_params: [{name: appId, var: app_id}, {name: tag, var: tag}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, tag: $tag, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/vhosts
#
# Returns: table<fqdn: string>
# operationId: getSelfApplicationsAppIdVhosts
export def "get-self-applications-app-id-vhosts" [
  app_id: string
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
    path: "/self/applications/{appId}/vhosts"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/vhosts/favourite
#
# operationId: deleteSelfApplicationsAppIdVhostsFavourite
export def "delete-self-applications-app-id-vhosts-favourite" [
  app_id: string
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
    path: "/self/applications/{appId}/vhosts/favourite"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/applications/{appId}/vhosts/favourite
#
# Returns: record<fqdn: string>
# operationId: getSelfApplicationsAppIdVhostsFavourite
export def "get-self-applications-app-id-vhosts-favourite" [
  app_id: string
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
    path: "/self/applications/{appId}/vhosts/favourite"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/vhosts/favourite
#
# operationId: putSelfApplicationsAppIdVhostsFavourite
export def "put-self-applications-app-id-vhosts-favourite" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fqdn: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/vhosts/favourite"
    path_params: [{name: appId, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fqdn, var: fqdn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, fqdn: $fqdn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/applications/{appId}/vhosts/{domain}
#
# operationId: deleteSelfApplicationsAppIdVhostsDomain
export def "delete-self-applications-app-id-vhosts-domain" [
  app_id: string
  domain: string
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
    path: "/self/applications/{appId}/vhosts/{domain}"
    path_params: [{name: appId, var: app_id}, {name: domain, var: domain}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/applications/{appId}/vhosts/{domain}
#
# operationId: putSelfApplicationsAppIdVhostsDomain
export def "put-self-applications-app-id-vhosts-domain" [
  app_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fqdn: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/applications/{appId}/vhosts/{domain}"
    path_params: [{name: appId, var: app_id}, {name: domain, var: domain}]
    body: {content_type: "application/json", kind: json, fields: [{name: fqdn, var: fqdn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, domain: $domain, fqdn: $fqdn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/avatar
#
# operationId: putSelfAvatar
export def "put-self-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: record # shape: {source: string, value: record}
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/avatar"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/change_password
#
# Returns: record<newPassword: string, oldPassword: string>
# operationId: putSelfChangePassword
export def "put-self-change-password" [
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
    method: put
    path: "/self/change_password"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/cli_tokens
export def "get-self-cli-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cli-token: string
]: nothing -> any {
  http-request {
    method: get
    path: "/self/cli_tokens"
    query: [{name: cli_token, var: cli_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cli_token: $cli_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/confirmation_email
#
# operationId: getSelfConfirmationEmail
export def "get-self-confirmation-email" [
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
    path: "/self/confirmation_email"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/consumers
#
# Returns: table<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>
# operationId: getSelfConsumers
export def "get-self-consumers" [
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
    path: "/self/consumers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/consumers
#
# operationId: postSelfConsumers
export def "post-self-consumers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: record # Must be a valid HTTP URL — shape: {url: string} (spec name: baseUrl)
  --description: string
  name: string
  --picture: string
  rights: record # shape: {activated: bool, right: string}
  url: record # Must be a valid HTTP URL — shape: {url: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/self/consumers"
    body: {content_type: "application/json", kind: json, fields: [{name: baseUrl, var: body_base_url, required: true}, {name: description, var: description}, {name: name, var: name}, {name: picture, var: picture}, {name: rights, var: rights}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body_base_url: $body_base_url, description: $description, name: $name, picture: $picture, rights: $rights, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/consumers/{key}
#
# operationId: deleteSelfConsumersKey
export def "delete-self-consumers-key" [
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
    path: "/self/consumers/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/consumers/{key}
#
# Returns: record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record<access_bills: bool, access_consumption_statistics: bool, access_credit_count: bool, access_organisations: bool, access_organisations_bills: bool, access_organisations_consumption_statistics: bool, access_organisations_credit_count: bool, access_personal_information: bool, almighty: bool, manage_applications: bool, manage_organisations: bool, manage_organisations_applications: bool, manage_organisations_members: bool, manage_organisations_services: bool, manage_personal_information: bool, manage_services: bool, manage_ssh_keys: bool>, url: string>
# operationId: getSelfConsumersKey
export def "get-self-consumers-key" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/self/consumers/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/consumers/{key}
#
# operationId: putSelfConsumersKey
export def "put-self-consumers-key" [
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
  --body-base-url: record # Must be a valid HTTP URL — shape: {url: string} (spec name: baseUrl)
  --description: string
  name: string
  --picture: string
  rights: record # shape: {activated: bool, right: string}
  url: record # Must be a valid HTTP URL — shape: {url: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/consumers/{key}"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: baseUrl, var: body_base_url, required: true}, {name: description, var: description}, {name: name, var: name}, {name: picture, var: picture}, {name: rights, var: rights}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, body_base_url: $body_base_url, description: $description, name: $name, picture: $picture, rights: $rights, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/consumers/{key}/secret
#
# Returns: record<secret: string, value: string>
# operationId: getSelfConsumersKeySecret
export def "get-self-consumers-key-secret" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/self/consumers/{key}/secret"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/consumptions
#
# Returns: record<appId: string, conso: record<conso: string, date: string>>
# operationId: getSelfConsumptions
export def "get-self-consumptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string
  --from: string
  --to: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/self/consumptions"
    query: [{name: appId, var: app_id}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/credits
#
# Returns: record<count: float, dropPrice: record<currency: string, value: float>, ownerId: string>
# operationId: getSelfCredits
export def "get-self-credits" [
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
    path: "/self/credits"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/emails
#
# Returns: list<string>
# operationId: getSelfEmails
export def "get-self-emails" [
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
    path: "/self/emails"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/emails/{email}
#
# operationId: deleteSelfEmailsEmail
export def "delete-self-emails-email" [
  email: string
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
    path: "/self/emails/{email}"
    path_params: [{name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/emails/{email}
#
# operationId: putSelfEmailsEmail
export def "put-self-emails-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/emails/{email}"
    path_params: [{name: email, var: email}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/id
#
# Returns: string
# operationId: getSelfId
export def "get-self-id" [
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
    path: "/self/id"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/instances
#
# Returns: table<buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, comingSoon: bool, defaultEnv: record, defaultFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, deployments: list<string>, description: string, enabled: bool, flavors: list<record>, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, maxInstances: int, minFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, minInstances: int, name: string, tags: list<string>, type: string, variant: record<deployType: string, id: string, logo: string, name: string, slug: string>, version: string>
# operationId: getSelfInstances
export def "get-self-instances" [
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
    path: "/self/instances"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/keys
#
# Returns: table<fingerprint: string, key: string, name: string>
# operationId: getSelfKeys
export def "get-self-keys" [
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
    path: "/self/keys"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/keys/{key}
#
# operationId: deleteSelfKeysKey
export def "delete-self-keys-key" [
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
    path: "/self/keys/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/keys/{key}
#
# operationId: putSelfKeysKey
export def "put-self-keys-key" [
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
  body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/self/keys/{key}"
    path_params: [{name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/mfa/{kind}
export def "delete-self-mfa-kind" [
  kind: string
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
    path: "/self/mfa/{kind}"
    path_params: [{name: kind, var: kind}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/mfa/{kind}
export def "post-self-mfa-kind" [
  kind: string
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
    path: "/self/mfa/{kind}"
    path_params: [{name: kind, var: kind}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/mfa/{kind}
export def "put-self-mfa-kind" [
  kind: string
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
    path: "/self/mfa/{kind}"
    path_params: [{name: kind, var: kind}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/mfa/{kind}/backupcodes
export def "get-self-mfa-kind-backupcodes" [
  kind: string
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
    path: "/self/mfa/{kind}/backupcodes"
    path_params: [{name: kind, var: kind}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/mfa/{kind}/confirmation
export def "post-self-mfa-kind-confirmation" [
  kind: string
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
    path: "/self/mfa/{kind}/confirmation"
    path_params: [{name: kind, var: kind}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payment-info
#
# operationId: getSelfPaymentInfo
export def "get-self-payment-info" [
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
    path: "/self/payment-info"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/billings
#
# operationId: getSelfPaymentsBillings
export def "get-self-payments-billings" [
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
    path: "/self/payments/billings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/payments/billings
#
# operationId: postSelfPaymentsBillings
export def "post-self-payments-billings" [
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
    path: "/self/payments/billings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/payments/billings/{bid}
#
# operationId: deleteSelfPaymentsBillingsBid
export def "delete-self-payments-billings-bid" [
  bid: string
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
    path: "/self/payments/billings/{bid}"
    path_params: [{name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/billings/{bid}
#
# operationId: getSelfPaymentsBillingsBid
export def "get-self-payments-billings-bid" [
  bid: string
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
    path: "/self/payments/billings/{bid}"
    path_params: [{name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/payments/billings/{bid}
#
# operationId: putSelfPaymentsBillingsBid
export def "put-self-payments-billings-bid" [
  bid: string
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
    path: "/self/payments/billings/{bid}"
    path_params: [{name: bid, var: bid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bid: $bid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/billings/{bid}.pdf
#
# operationId: getSelfPaymentsBillingsBidPdf
export def "get-self-payments-billings-bid-pdf" [
  bid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/self/payments/billings/{bid}.pdf"
    path_params: [{name: bid, var: bid}]
    query: [{name: token, var: qp_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    bid: $bid, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/fullprice/{price}
#
# operationId: getSelfPaymentsFullpricePrice
export def "get-self-payments-fullprice-price" [
  price: string
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
    path: "/self/payments/fullprice/{price}"
    path_params: [{name: price, var: price}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    price: $price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/methods
#
# operationId: getSelfPaymentsMethods
export def "get-self-payments-methods" [
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
    path: "/self/payments/methods"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /self/payments/methods
#
# operationId: postSelfPaymentsMethods
export def "post-self-payments-methods" [
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
    path: "/self/payments/methods"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/methods/default
export def "get-self-payments-methods-default" [
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
    path: "/self/payments/methods/default"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/payments/methods/default
export def "put-self-payments-methods-default" [
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
    path: "/self/payments/methods/default"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/payments/methods/{mId}
#
# operationId: deleteSelfPaymentsMethodsMId
export def "delete-self-payments-methods-m-id" [
  m_id: string
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
    path: "/self/payments/methods/{mId}"
    path_params: [{name: mId, var: m_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    m_id: $m_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/monthlyinvoice
export def "get-self-payments-monthlyinvoice" [
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
    path: "/self/payments/monthlyinvoice"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /self/payments/monthlyinvoice/maxcredit
export def "put-self-payments-monthlyinvoice-maxcredit" [
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
    path: "/self/payments/monthlyinvoice/maxcredit"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/payments/recurring
#
# operationId: deleteSelfPaymentsRecurring
export def "delete-self-payments-recurring" [
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
    path: "/self/payments/recurring"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/recurring
export def "get-self-payments-recurring" [
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
    path: "/self/payments/recurring"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/payments/tokens/stripe
export def "get-self-payments-tokens-stripe" [
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
    path: "/self/payments/tokens/stripe"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/tokens
#
# operationId: deleteSelfTokens
export def "delete-self-tokens" [
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
    path: "/self/tokens"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/tokens
#
# Returns: table<consumer: record<baseUrl: string, description: string, key: string, name: string, picture: string, rights: record, url: string>, creationDate: int, lastUtilisation: string, rights: record<description: string, name: string>, token: string>
# operationId: getSelfTokens
export def "get-self-tokens" [
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
    path: "/self/tokens"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /self/tokens/{token}
#
# operationId: deleteSelfTokensToken
export def "delete-self-tokens-token" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/self/tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /self/validate_email
#
# operationId: getSelfValidateEmail
export def "get-self-validate-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validation-key: string
]: nothing -> any {
  http-request {
    method: get
    path: "/self/validate_email"
    query: [{name: validationKey, var: validation_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    validation_key: $validation_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /summary
#
# Returns: record<organisations: table<addons: list, applications: list, avatar: string, consumers: list, id: string, name: string, providers: list, role: string>, user: record<addons: list<record>, admin: bool, applications: list<record>, avatar: string, consumers: list<record>, id: string, lang: string, name: string>>
# operationId: getSummary
export def "get-summary" [
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
    path: "/summary"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /users
#
# operationId: postUsers
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
  --invitation-key: string
  --addon-beta-invitation-key: string
  --email: string
  --pass: string
  --url-next: string
  --terms: string
  --address: string
  --city: string
  --country: string
  --body-email: string # (spec name: email)
  --lang: string
  --name: string
  password: string
  --phone: string
  --body-terms: oneof<nothing, bool> # default: false (spec name: terms)
  --zipcode: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/users"
    query: [{name: invitationKey, var: invitation_key}, {name: addonBetaInvitationKey, var: addon_beta_invitation_key}, {name: email, var: email}, {name: pass, var: pass}, {name: url_next, var: url_next}, {name: terms, var: terms}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: country, var: country}, {name: email, var: body_email, required: true}, {name: lang, var: lang}, {name: name, var: name}, {name: password, var: password}, {name: phone, var: phone}, {name: terms, var: body_terms, required: true}, {name: zipcode, var: zipcode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    invitation_key: $invitation_key, addon_beta_invitation_key: $addon_beta_invitation_key, email: $email, pass: $pass, url_next: $url_next, terms: $terms, address: $address, city: $city, country: $country, body_email: $body_email, lang: $lang, name: $name, password: $password, phone: $phone, body_terms: $body_terms, zipcode: $zipcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /users/{id}
#
# Returns: record<address: string, admin: bool, avatar: string, canPay: bool, city: string, country: string, creationDate: int, email: string, emailValidated: bool, hasPassword: bool, id: string, lang: string, name: string, oauthApps: list<string>, phone: string, preferredMFA: string, zipcode: string>
# operationId: getUsersId
export def "get-users-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /users/{id}/applications
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getUsersIdApplications
export def "get-users-id-applications" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/applications"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /users/{userId}/git-info
#
# operationId: getUsersUserIdGitInfo
export def "get-users-user-id-git-info" [
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
    method: get
    path: "/users/{userId}/git-info"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Matomo addon
#
# POST /v2/providers/addon-matomo/resources
# operationId: createMatomo
export def "create-matomo" [
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/providers/addon-matomo/resources"
    body: {content_type: "application/json", kind: json}
    accept: ["*/*"]
    ok: []
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Matomo addon
#
# DELETE /v2/providers/addon-matomo/resources/{matomoId}
# operationId: deleteMatomo
export def "delete-matomo" [
  matomo_id: string
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
    method: delete
    path: "/v2/providers/addon-matomo/resources/{matomoId}"
    path_params: [{name: matomoId, var: matomo_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["*/*"]
    ok: []
    auth: bearer
  } {
    matomo_id: $matomo_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs for a given application
#
# GET /v3/logs/{appId}
export def "get-v3-logs-app-id" [
  app_id: string
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
    path: "/v3/logs/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs drains for a given application
#
# GET /v3/logs/{appId}/drains
export def "get-v3-logs-app-id-drains" [
  app_id: string
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
    path: "/v3/logs/{appId}/drains"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a log drain for a given application
#
# POST /v3/logs/{appId}/drains
export def "post-v3-logs-app-id-drains" [
  app_id: string
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
    path: "/v3/logs/{appId}/drains"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the logs drain by id or url for a given application
#
# DELETE /v3/logs/{appId}/drains/:idOrUrl
export def "delete-v3-logs-app-id-drains-id-or-url" [
  app_id: string
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
    path: "/v3/logs/{appId}/drains/:idOrUrl"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the logs drain by id or url for a given application
#
# GET /v3/logs/{appId}/drains/:idOrUrl
export def "get-v3-logs-app-id-drains-id-or-url" [
  app_id: string
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
    path: "/v3/logs/{appId}/drains/:idOrUrl"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve logs as they come through a chunked, never-ending response
#
# GET /v3/logs/{appId}/logs-chunked
export def "get-v3-logs-app-id-logs-chunked" [
  app_id: string
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
    path: "/v3/logs/{appId}/logs-chunked"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve logs as they come through a websocket connection. To have authorization, you have to send a `{ "message_type": "oauth", "authorization": "oauth authorization string" }` message
#
# GET /v3/logs/{appId}/logs-socket
export def "get-v3-logs-app-id-logs-socket" [
  app_id: string
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
    path: "/v3/logs/{appId}/logs-socket"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Matomo addon
#
# GET /v4/addon-providers/addon-matomo/addons/{matomoId}
# operationId: getMatomo
export def "get-matomo" [
  matomo_id: string
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
    path: "/v4/addon-providers/addon-matomo/addons/{matomoId}"
    path_params: [{name: matomoId, var: matomo_id}]
    accept: ["*/*"]
    ok: []
    auth: bearer
  } {
    matomo_id: $matomo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a keycloak token
#
# GET /v4/addon-providers/addon-matomo/token/validate
# operationId: getMatomoKTokenValidation
export def "get-matomo-k-token-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keycloak-token: string # Environment variable injected on the app with 'KEYCLOAK_TOKEN' name
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/addon-providers/addon-matomo/token/validate"
    query: [{name: keycloakToken, var: keycloak_token}]
    accept: ["*/*"]
    ok: []
    auth: bearer
  } {
    keycloak_token: $keycloak_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Addon provider configuration
#
# GET /v4/addon-providers/config-provider/addons/{configurationProviderId}
# operationId: getConfigProvider
export def "get-config-provider" [
  configuration_provider_id: string
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
    path: "/v4/addon-providers/config-provider/addons/{configurationProviderId}"
    path_params: [{name: configurationProviderId, var: configuration_provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    configuration_provider_id: $configuration_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get provider's addon environment
#
# GET /v4/addon-providers/config-provider/addons/{configurationProviderId}/env
# Returns: list<any>
# operationId: getConfigProviderEnv
export def "get-config-provider-env" [
  configuration_provider_id: string
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
    path: "/v4/addon-providers/config-provider/addons/{configurationProviderId}/env"
    path_params: [{name: configurationProviderId, var: configuration_provider_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    configuration_provider_id: $configuration_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update provider's addon environment
#
# PUT /v4/addon-providers/config-provider/addons/{configurationProviderId}/env
# Returns: list<any>
# operationId: updateConfigProviderEnv
export def "update-config-provider-env" [
  configuration_provider_id: string
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
    method: put
    path: "/v4/addon-providers/config-provider/addons/{configurationProviderId}/env"
    path_params: [{name: configurationProviderId, var: configuration_provider_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    configuration_provider_id: $configuration_provider_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Network Groups
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups
# Returns: list<any>
# operationId: listNetworkGroups
export def "list-network-groups" [
  owner_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups"
    path_params: [{name: ownerId, var: owner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Network Group
#
# POST /v4/networkgroups/organisations/{ownerId}/networkgroups
# operationId: createNetworkGroup
export def "create-network-group" [
  owner_id: string
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups"
    path_params: [{name: ownerId, var: owner_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    owner_id: $owner_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Network Group
#
# DELETE /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}
# operationId: deleteNetworkGroup
export def "delete-network-group" [
  owner_id: string
  network_group_id: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Network Group
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}
# operationId: getNetworkGroup
export def "get-network-group" [
  owner_id: string
  network_group_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add external peer
#
# POST /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/external-peers
# operationId: createNetworkGroupExternalPeer
export def "create-network-group-external-peer" [
  owner_id: string
  network_group_id: string
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/external-peers"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove external peer
#
# DELETE /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/external-peers/{peerId}
# operationId: deleteNetworkGroupExternalPeer
export def "delete-network-group-external-peer" [
  owner_id: string
  network_group_id: string
  peer_id: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/external-peers/{peerId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: peerId, var: peer_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, peer_id: $peer_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List members
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members
# Returns: table<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>
# operationId: listNetworkGroupMembers
export def "list-network-group-members" [
  owner_id: string
  network_group_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add member
#
# POST /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members
# operationId: createNetworkGroupMember
export def "create-network-group-member" [
  owner_id: string
  network_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  --job: string
  role: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: job, var: job}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, email: $email, job: $job, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove member
#
# DELETE /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members/{memberId}
# operationId: deleteNetworkGroupMember
export def "delete-network-group-member" [
  owner_id: string
  network_group_id: string
  member_id: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members/{memberId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, member_id: $member_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get member
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members/{memberId}
# Returns: record<job: string, member: record<avatar: string, email: string, id: string, name: string>, role: string>
# operationId: getNetworkGroupMember
export def "get-network-group-member" [
  owner_id: string
  network_group_id: string
  member_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/members/{memberId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List peers
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers
# Returns: list<any>
# operationId: listNetworkGroupPeers
export def "list-network-group-peers" [
  owner_id: string
  network_group_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove peer
#
# DELETE /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}
# operationId: deleteNetworkGroupPeer
export def "delete-network-group-peer" [
  owner_id: string
  network_group_id: string
  peer_id: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: peerId, var: peer_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, peer_id: $peer_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get peer
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}
# operationId: getNetworkGroupPeer
export def "get-network-group-peer" [
  owner_id: string
  network_group_id: string
  peer_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: peerId, var: peer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, peer_id: $peer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get WireGuard® configuration
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}/wireguard/configuration
# operationId: getNetworkGroupWireGuardConfiguration
export def "get-network-group-wire-guard-configuration" [
  owner_id: string
  network_group_id: string
  peer_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}/wireguard/configuration"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: peerId, var: peer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, peer_id: $peer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get WireGuard® configuration
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}/wireguard/configuration/stream
# operationId: getNetworkGroupWireGuardConfigurationStream
export def "get-network-group-wire-guard-configuration-stream" [
  owner_id: string
  network_group_id: string
  peer_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/peers/{peerId}/wireguard/configuration/stream"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}, {name: peerId, var: peer_id}]
    accept: ["text/event-stream"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id, peer_id: $peer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Network Group SSE
#
# GET /v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/stream
# operationId: getNetworkGroupStream
export def "get-network-group-stream" [
  owner_id: string
  network_group_id: string
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
    path: "/v4/networkgroups/organisations/{ownerId}/networkgroups/{networkGroupId}/stream"
    path_params: [{name: ownerId, var: owner_id}, {name: networkGroupId, var: network_group_id}]
    accept: ["text/event-stream"]
    ok: [200]
    auth: none
  } {
    owner_id: $owner_id, network_group_id: $network_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /vendor//addons
export def "post-vendor-addons" [
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
    path: "/vendor//addons"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /vendor//apps/{addonId}/logscollector
export def "get-vendor-apps-addon-id-logscollector" [
  addon_id: string
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
    path: "/vendor//apps/{addonId}/logscollector"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /vendor/apps
#
# Returns: table<archived: bool, branch: string, buildFlavor: record<available: bool, cpus: int, disk: int, mem: int, microservice: bool, name: string, nice: float, price: float>, cancelOnPush: bool, commitId: string, creationDate: string, deployUrl: string, deployment: record<httpUrl: string, repoState: string, shutdownable: bool, type: string, url: string>, description: string, favourite: bool, homogeneous: bool, id: string, instance: record<buildFlavor: record, comingSoon: bool, defaultEnv: record, defaultFlavor: record, deployments: list, description: string, enabled: bool, flavors: list, instanceAndVersion: string, maxAllowedInstances: int, maxFlavor: record, maxInstances: int, minFlavor: record, minInstances: int, name: string, tags: list, type: string, variant: record, version: string>, last_deploy: int, name: string, ownerId: string, separateBuild: bool, state: string, stickySessions: bool, vhosts: list<record>, webhookSecret: string, webhookUrl: string, zone: string>
# operationId: getVendorApps
export def "get-vendor-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/vendor/apps"
    query: [{name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /vendor/apps/{addonId}
#
# operationId: getVendorAppsAddonId
export def "get-vendor-apps-addon-id" [
  addon_id: string
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
    path: "/vendor/apps/{addonId}"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /vendor/apps/{addonId}
#
# operationId: putVendorAppsAddonId
export def "put-vendor-apps-addon-id" [
  addon_id: string
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
    path: "/vendor/apps/{addonId}"
    path_params: [{name: addonId, var: addon_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /vendor/apps/{addonId}/consumptions
#
# operationId: postVendorBillingOwnerId
export def "post-vendor-billing-owner-id" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cost: float # format: double
]: any -> any {
  $in | http-request {
    method: post
    path: "/vendor/apps/{addonId}/consumptions"
    path_params: [{name: addonId, var: addon_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cost, var: cost}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, cost: $cost
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /vendor/apps/{addonId}/migration_callback
export def "put-vendor-apps-addon-id-migration-callback" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string
  --region: string
]: nothing -> any {
  http-request {
    method: put
    path: "/vendor/apps/{addonId}/migration_callback"
    path_params: [{name: addonId, var: addon_id}]
    query: [{name: plan_id, var: plan_id}, {name: region, var: region}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_id: $addon_id, plan_id: $plan_id, region: $region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
