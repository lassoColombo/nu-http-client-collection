# Auto-generated client for AWS License Manager v2018-08-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/license-manager/2018-08-01/openapi.json
# Auth: --token flag or $env.AWS_LICENSE_MANAGER_TOKEN

const CLIENT = {
  base_url: "http://license-manager.us-east-1.amazonaws.com"
  token_env_var: "AWS_LICENSE_MANAGER_TOKEN"
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

def base-url-completer [] { ["http://license-manager.us-east-1.amazonaws.com" "http://license-manager.us-east-2.amazonaws.com" "http://license-manager.us-west-1.amazonaws.com" "http://license-manager.us-west-2.amazonaws.com" "http://license-manager.us-gov-west-1.amazonaws.com" "http://license-manager.us-gov-east-1.amazonaws.com" "http://license-manager.ca-central-1.amazonaws.com" "http://license-manager.eu-north-1.amazonaws.com" "http://license-manager.eu-west-1.amazonaws.com" "http://license-manager.eu-west-2.amazonaws.com" "http://license-manager.eu-west-3.amazonaws.com" "http://license-manager.eu-central-1.amazonaws.com" "http://license-manager.eu-south-1.amazonaws.com" "http://license-manager.af-south-1.amazonaws.com" "http://license-manager.ap-northeast-1.amazonaws.com" "http://license-manager.ap-northeast-2.amazonaws.com" "http://license-manager.ap-northeast-3.amazonaws.com" "http://license-manager.ap-southeast-1.amazonaws.com" "http://license-manager.ap-southeast-2.amazonaws.com" "http://license-manager.ap-east-1.amazonaws.com" "http://license-manager.ap-south-1.amazonaws.com" "http://license-manager.sa-east-1.amazonaws.com" "http://license-manager.me-south-1.amazonaws.com" "https://license-manager.us-east-1.amazonaws.com" "https://license-manager.us-east-2.amazonaws.com" "https://license-manager.us-west-1.amazonaws.com" "https://license-manager.us-west-2.amazonaws.com" "https://license-manager.us-gov-west-1.amazonaws.com" "https://license-manager.us-gov-east-1.amazonaws.com" "https://license-manager.ca-central-1.amazonaws.com" "https://license-manager.eu-north-1.amazonaws.com" "https://license-manager.eu-west-1.amazonaws.com" "https://license-manager.eu-west-2.amazonaws.com" "https://license-manager.eu-west-3.amazonaws.com" "https://license-manager.eu-central-1.amazonaws.com" "https://license-manager.eu-south-1.amazonaws.com" "https://license-manager.af-south-1.amazonaws.com" "https://license-manager.ap-northeast-1.amazonaws.com" "https://license-manager.ap-northeast-2.amazonaws.com" "https://license-manager.ap-northeast-3.amazonaws.com" "https://license-manager.ap-southeast-1.amazonaws.com" "https://license-manager.ap-southeast-2.amazonaws.com" "https://license-manager.ap-east-1.amazonaws.com" "https://license-manager.ap-south-1.amazonaws.com" "https://license-manager.sa-east-1.amazonaws.com" "https://license-manager.me-south-1.amazonaws.com" "http://license-manager.cn-north-1.amazonaws.com.cn" "http://license-manager.cn-northwest-1.amazonaws.com.cn" "https://license-manager.cn-north-1.amazonaws.com.cn" "https://license-manager.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSLicenseManager.AcceptGrant"] }
def x-amz-target-completer-1 [] { ["AWSLicenseManager.CheckInLicense"] }
def digital-signature-method-completer [] { ["JWT_PS384"] }
def x-amz-target-completer-2 [] { ["AWSLicenseManager.CheckoutBorrowLicense"] }
def checkout-type-completer [] { ["PERPETUAL" "PROVISIONAL"] }
def x-amz-target-completer-3 [] { ["AWSLicenseManager.CheckoutLicense"] }
def x-amz-target-completer-4 [] { ["AWSLicenseManager.CreateGrant"] }
def status-completer [] { ["ACTIVE" "DELETED" "DISABLED" "FAILED_WORKFLOW" "PENDING_ACCEPT" "PENDING_DELETE" "PENDING_WORKFLOW" "REJECTED" "WORKFLOW_COMPLETED"] }
def x-amz-target-completer-5 [] { ["AWSLicenseManager.CreateGrantVersion"] }
def x-amz-target-completer-6 [] { ["AWSLicenseManager.CreateLicense"] }
def license-counting-type-completer [] { ["Core" "Instance" "Socket" "vCPU"] }
def x-amz-target-completer-7 [] { ["AWSLicenseManager.CreateLicenseConfiguration"] }
def x-amz-target-completer-8 [] { ["AWSLicenseManager.CreateLicenseConversionTaskForResource"] }
def x-amz-target-completer-9 [] { ["AWSLicenseManager.CreateLicenseManagerReportGenerator"] }
def status-completer-1 [] { ["AVAILABLE" "DEACTIVATED" "DELETED" "EXPIRED" "PENDING_AVAILABLE" "PENDING_DELETE" "SUSPENDED"] }
def x-amz-target-completer-10 [] { ["AWSLicenseManager.CreateLicenseVersion"] }
def x-amz-target-completer-11 [] { ["AWSLicenseManager.CreateToken"] }
def x-amz-target-completer-12 [] { ["AWSLicenseManager.DeleteGrant"] }
def x-amz-target-completer-13 [] { ["AWSLicenseManager.DeleteLicense"] }
def x-amz-target-completer-14 [] { ["AWSLicenseManager.DeleteLicenseConfiguration"] }
def x-amz-target-completer-15 [] { ["AWSLicenseManager.DeleteLicenseManagerReportGenerator"] }
def x-amz-target-completer-16 [] { ["AWSLicenseManager.DeleteToken"] }
def x-amz-target-completer-17 [] { ["AWSLicenseManager.ExtendLicenseConsumption"] }
def x-amz-target-completer-18 [] { ["AWSLicenseManager.GetAccessToken"] }
def x-amz-target-completer-19 [] { ["AWSLicenseManager.GetGrant"] }
def x-amz-target-completer-20 [] { ["AWSLicenseManager.GetLicense"] }
def x-amz-target-completer-21 [] { ["AWSLicenseManager.GetLicenseConfiguration"] }
def x-amz-target-completer-22 [] { ["AWSLicenseManager.GetLicenseConversionTask"] }
def x-amz-target-completer-23 [] { ["AWSLicenseManager.GetLicenseManagerReportGenerator"] }
def x-amz-target-completer-24 [] { ["AWSLicenseManager.GetLicenseUsage"] }
def x-amz-target-completer-25 [] { ["AWSLicenseManager.GetServiceSettings"] }
def x-amz-target-completer-26 [] { ["AWSLicenseManager.ListAssociationsForLicenseConfiguration"] }
def x-amz-target-completer-27 [] { ["AWSLicenseManager.ListDistributedGrants"] }
def x-amz-target-completer-28 [] { ["AWSLicenseManager.ListFailuresForLicenseConfigurationOperations"] }
def x-amz-target-completer-29 [] { ["AWSLicenseManager.ListLicenseConfigurations"] }
def x-amz-target-completer-30 [] { ["AWSLicenseManager.ListLicenseConversionTasks"] }
def x-amz-target-completer-31 [] { ["AWSLicenseManager.ListLicenseManagerReportGenerators"] }
def x-amz-target-completer-32 [] { ["AWSLicenseManager.ListLicenseSpecificationsForResource"] }
def x-amz-target-completer-33 [] { ["AWSLicenseManager.ListLicenseVersions"] }
def x-amz-target-completer-34 [] { ["AWSLicenseManager.ListLicenses"] }
def x-amz-target-completer-35 [] { ["AWSLicenseManager.ListReceivedGrants"] }
def x-amz-target-completer-36 [] { ["AWSLicenseManager.ListReceivedGrantsForOrganization"] }
def x-amz-target-completer-37 [] { ["AWSLicenseManager.ListReceivedLicenses"] }
def x-amz-target-completer-38 [] { ["AWSLicenseManager.ListReceivedLicensesForOrganization"] }
def x-amz-target-completer-39 [] { ["AWSLicenseManager.ListResourceInventory"] }
def x-amz-target-completer-40 [] { ["AWSLicenseManager.ListTagsForResource"] }
def x-amz-target-completer-41 [] { ["AWSLicenseManager.ListTokens"] }
def x-amz-target-completer-42 [] { ["AWSLicenseManager.ListUsageForLicenseConfiguration"] }
def x-amz-target-completer-43 [] { ["AWSLicenseManager.RejectGrant"] }
def x-amz-target-completer-44 [] { ["AWSLicenseManager.TagResource"] }
def x-amz-target-completer-45 [] { ["AWSLicenseManager.UntagResource"] }
def license-configuration-status-completer [] { ["AVAILABLE" "DISABLED"] }
def x-amz-target-completer-46 [] { ["AWSLicenseManager.UpdateLicenseConfiguration"] }
def x-amz-target-completer-47 [] { ["AWSLicenseManager.UpdateLicenseManagerReportGenerator"] }
def x-amz-target-completer-48 [] { ["AWSLicenseManager.UpdateLicenseSpecificationsForResource"] }
def x-amz-target-completer-49 [] { ["AWSLicenseManager.UpdateServiceSettings"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-grant: "record<GrantArn: string, Status: string, Version: string>"
    check-in-license: "record"
    checkout-borrow-license: "record<LicenseArn: string, LicenseConsumptionToken: string, EntitlementsAllowed: table<Name: string, Value: string, Unit: string>, NodeId: string, SignedToken: string, IssuedAt: string, Expiration: string, CheckoutMetadata: table<Name: string, Value: string>>"
    checkout-license: "record<CheckoutType: string, LicenseConsumptionToken: string, EntitlementsAllowed: table<Name: string, Value: string, Unit: string>, SignedToken: string, NodeId: string, IssuedAt: string, Expiration: string, LicenseArn: string>"
    create-grant: "record<GrantArn: string, Status: string, Version: string>"
    create-grant-version: "record<GrantArn: string, Status: string, Version: string>"
    create-license: "record<LicenseArn: string, Status: string, Version: string>"
    create-license-configuration: "record<LicenseConfigurationArn: string>"
    create-license-conversion-task-for-resource: "record<LicenseConversionTaskId: string>"
    create-license-manager-report-generator: "record<LicenseManagerReportGeneratorArn: string>"
    create-license-version: "record<LicenseArn: string, Version: string, Status: string>"
    create-token: "record<TokenId: string, TokenType: string, Token: string>"
    delete-grant: "record<GrantArn: string, Status: string, Version: string>"
    delete-license: "record<Status: string, DeletionDate: string>"
    delete-license-configuration: "record"
    delete-license-manager-report-generator: "record"
    delete-token: "record"
    extend-license-consumption: "record<LicenseConsumptionToken: string, Expiration: string>"
    get-access-token: "record<AccessToken: string>"
    get-grant: "record<Grant: record<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list<string>, Options: record<ActivationOverrideBehavior: string>>>"
    get-license: "record<License: record<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record<Name: string, SignKey: string, KeyFingerprint: string>, HomeRegion: string, Status: string, Validity: record<Begin: string, End: string>, Beneficiary: string, Entitlements: list<record>, ConsumptionConfiguration: record<RenewType: string, ProvisionalConfiguration: record, BorrowConfiguration: record>, LicenseMetadata: list<record>, CreateTime: string, Version: string>>"
    get-license-configuration: "record<LicenseConfigurationId: string, LicenseConfigurationArn: string, Name: string, Description: string, LicenseCountingType: string, LicenseRules: list<string>, LicenseCount: int, LicenseCountHardLimit: bool, ConsumedLicenses: int, Status: string, OwnerAccountId: string, ConsumedLicenseSummaryList: table<ResourceType: string, ConsumedLicenses: int>, ManagedResourceSummaryList: table<ResourceType: string, AssociationCount: int>, Tags: table<Key: string, Value: string>, ProductInformationList: table<ResourceType: string, ProductInformationFilterList: list>, AutomatedDiscoveryInformation: record<LastRunTime: string>, DisassociateWhenNotFound: bool>"
    get-license-conversion-task: "record<LicenseConversionTaskId: string, ResourceArn: string, SourceLicenseContext: record<UsageOperation: string>, DestinationLicenseContext: record<UsageOperation: string>, StatusMessage: string, Status: string, StartTime: string, LicenseConversionTime: string, EndTime: string>"
    get-license-manager-report-generator: "record<ReportGenerator: record<ReportGeneratorName: string, ReportType: list<string>, ReportContext: record<licenseConfigurationArns: list>, ReportFrequency: record<value: int, period: string>, LicenseManagerReportGeneratorArn: string, LastRunStatus: string, LastRunFailureReason: string, LastReportGenerationTime: string, ReportCreatorAccount: string, Description: string, S3Location: record<bucket: string, keyPrefix: string>, CreateTime: string, Tags: list<record>>>"
    get-license-usage: "record<LicenseUsage: record<EntitlementUsages: list<record>>>"
    get-service-settings: "record<S3BucketArn: string, SnsTopicArn: string, OrganizationConfiguration: record<EnableIntegration: bool>, EnableCrossAccountsDiscovery: bool, LicenseManagerResourceShareArn: string>"
    list-associations-for-license-configuration: "record<LicenseConfigurationAssociations: table<ResourceArn: string, ResourceType: string, ResourceOwnerId: string, AssociationTime: string, AmiAssociationScope: string>, NextToken: string>"
    list-distributed-grants: "record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>"
    list-failures-for-license-configuration-operations: "record<LicenseOperationFailureList: table<ResourceArn: string, ResourceType: string, ErrorMessage: string, FailureTime: string, OperationName: string, ResourceOwnerId: string, OperationRequestedBy: string, MetadataList: list>, NextToken: string>"
    list-license-configurations: "record<LicenseConfigurations: table<LicenseConfigurationId: string, LicenseConfigurationArn: string, Name: string, Description: string, LicenseCountingType: string, LicenseRules: list, LicenseCount: int, LicenseCountHardLimit: bool, DisassociateWhenNotFound: bool, ConsumedLicenses: int, Status: string, OwnerAccountId: string, ConsumedLicenseSummaryList: list, ManagedResourceSummaryList: list, ProductInformationList: list, AutomatedDiscoveryInformation: record>, NextToken: string>"
    list-license-conversion-tasks: "record<LicenseConversionTasks: table<LicenseConversionTaskId: string, ResourceArn: string, SourceLicenseContext: record, DestinationLicenseContext: record, Status: string, StatusMessage: string, StartTime: string, LicenseConversionTime: string, EndTime: string>, NextToken: string>"
    list-license-manager-report-generators: "record<ReportGenerators: table<ReportGeneratorName: string, ReportType: list, ReportContext: record, ReportFrequency: record, LicenseManagerReportGeneratorArn: string, LastRunStatus: string, LastRunFailureReason: string, LastReportGenerationTime: string, ReportCreatorAccount: string, Description: string, S3Location: record, CreateTime: string, Tags: list>, NextToken: string>"
    list-license-specifications-for-resource: "record<LicenseSpecifications: table<LicenseConfigurationArn: string, AmiAssociationScope: string>, NextToken: string>"
    list-license-versions: "record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string>, NextToken: string>"
    list-licenses: "record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string>, NextToken: string>"
    list-received-grants: "record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>"
    list-received-grants-for-organization: "record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>"
    list-received-licenses: "record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string, ReceivedMetadata: record>, NextToken: string>"
    list-received-licenses-for-organization: "record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string, ReceivedMetadata: record>, NextToken: string>"
    list-resource-inventory: "record<ResourceInventoryList: table<ResourceId: string, ResourceType: string, ResourceArn: string, Platform: string, PlatformVersion: string, ResourceOwningAccountId: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>>"
    list-tokens: "record<Tokens: table<TokenId: string, TokenType: string, LicenseArn: string, ExpirationTime: string, TokenProperties: list, RoleArns: list, Status: string>, NextToken: string>"
    list-usage-for-license-configuration: "record<LicenseConfigurationUsageList: table<ResourceArn: string, ResourceType: string, ResourceStatus: string, ResourceOwnerId: string, AssociationTime: string, ConsumedLicenses: int>, NextToken: string>"
    reject-grant: "record<GrantArn: string, Status: string, Version: string>"
    tag-resource: "record"
    untag-resource: "record"
    update-license-configuration: "record"
    update-license-manager-report-generator: "record"
    update-license-specifications-for-resource: "record"
    update-service-settings: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-grant" "check-in-license" "checkout-borrow-license" "checkout-license" "create-grant" "create-grant-version" "create-license" "create-license-configuration" "create-license-conversion-task-for-resource" "create-license-manager-report-generator" "create-license-version" "create-token" "delete-grant" "delete-license" "delete-license-configuration" "delete-license-manager-report-generator" "delete-token" "extend-license-consumption" "get-access-token" "get-grant" "get-license" "get-license-configuration" "get-license-conversion-task" "get-license-manager-report-generator" "get-license-usage" "get-service-settings" "list-associations-for-license-configuration" "list-distributed-grants" "list-failures-for-license-configuration-operations" "list-license-configurations" "list-license-conversion-tasks" "list-license-manager-report-generators" "list-license-specifications-for-resource" "list-license-versions" "list-licenses" "list-received-grants" "list-received-grants-for-organization" "list-received-licenses" "list-received-licenses-for-organization" "list-resource-inventory" "list-tags-for-resource" "list-tokens" "list-usage-for-license-configuration" "reject-grant" "tag-resource" "untag-resource" "update-license-configuration" "update-license-manager-report-generator" "update-license-specifications-for-resource" "update-service-settings" "commands"] | sort) } | get name | first)
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

# Accepts the specified grant.
#
# POST /
# Returns: record<GrantArn: string, Status: string, Version: string>
# operationId: AcceptGrant
export def "accept-grant" [
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
  --x-amz-target: string@x-amz-target-completer # required
  grant_arn: string # Amazon Resource Name (ARN) of the grant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.AcceptGrant"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArn, var: grant_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arn: $grant_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks in the specified license. Check in a license when it is no longer in use.
#
# POST /
# Returns: record
# operationId: CheckInLicense
export def "check-in-license" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  license_consumption_token: string # License consumption token.
  --beneficiary: string # License beneficiary.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CheckInLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConsumptionToken, var: license_consumption_token}, {name: Beneficiary, var: beneficiary}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_consumption_token: $license_consumption_token, beneficiary: $beneficiary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks out the specified license for offline use.
#
# POST /
# Returns: record<LicenseArn: string, LicenseConsumptionToken: string, EntitlementsAllowed: table<Name: string, Value: string, Unit: string>, NodeId: string, SignedToken: string, IssuedAt: string, Expiration: string, CheckoutMetadata: table<Name: string, Value: string>>
# operationId: CheckoutBorrowLicense
export def "checkout-borrow-license" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  license_arn: string # Amazon Resource Name (ARN) of the license. The license must use the borrow consumption configuration.
  entitlements: list # License entitlements. Partial checkouts are not supported. — item shape: {Name: string, Value?: string, Unit: "Count"|"None"|"Seconds"|"Microseconds"|"Milliseconds"|"Bytes"|"Kilobytes"|"Megabytes"|"Gigabytes"|"Terabytes"|"Bits"|"Kilobits"|"Megabits"|"Gigabits"|"Terabits"|"Percent"|"Bytes/Second"|"Kilobytes/Second"|"Megabytes/Second"|"Gigabytes/Second"|"Terabytes/Second"|"Bits/Second"|"Kilobits/Second"|"Megabits/Second"|"Gigabits/Second"|"Terabits/Second"|"Count/Second"}
  digital_signature_method: string@digital-signature-method-completer # Digital signature method. The possible value is JSON Web Signature (JWS) algorithm PS384. For more information, see RFC 7518 Digital Signature with RSASSA-PSS (https://tools.ietf.org/html/rfc7518#section-3.5).
  --node-id: string # Node ID.
  --checkout-metadata: list # Information about constraints. — item shape: {Name?: string, Value?: string}
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CheckoutBorrowLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: Entitlements, var: entitlements}, {name: DigitalSignatureMethod, var: digital_signature_method}, {name: NodeId, var: node_id}, {name: CheckoutMetadata, var: checkout_metadata}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, entitlements: $entitlements, digital_signature_method: $digital_signature_method, node_id: $node_id, checkout_metadata: $checkout_metadata, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks out the specified license. If the account that created the license is the same that is performing the check out, you must specify the account as the beneficiary.
#
# POST /
# Returns: record<CheckoutType: string, LicenseConsumptionToken: string, EntitlementsAllowed: table<Name: string, Value: string, Unit: string>, SignedToken: string, NodeId: string, IssuedAt: string, Expiration: string, LicenseArn: string>
# operationId: CheckoutLicense
export def "checkout-license" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  product_sku: string # Product SKU.
  checkout_type: string@checkout-type-completer # Checkout type.
  key_fingerprint: string # Key fingerprint identifying the license.
  entitlements: list # License entitlements. — item shape: {Name: string, Value?: string, Unit: "Count"|"None"|"Seconds"|"Microseconds"|"Milliseconds"|"Bytes"|"Kilobytes"|"Megabytes"|"Gigabytes"|"Terabytes"|"Bits"|"Kilobits"|"Megabits"|"Gigabits"|"Terabits"|"Percent"|"Bytes/Second"|"Kilobytes/Second"|"Megabytes/Second"|"Gigabytes/Second"|"Terabytes/Second"|"Bits/Second"|"Kilobits/Second"|"Megabits/Second"|"Gigabits/Second"|"Terabits/Second"|"Count/Second"}
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --beneficiary: string # License beneficiary.
  --node-id: string # Node ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CheckoutLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProductSKU, var: product_sku}, {name: CheckoutType, var: checkout_type}, {name: KeyFingerprint, var: key_fingerprint}, {name: Entitlements, var: entitlements}, {name: ClientToken, var: client_token}, {name: Beneficiary, var: beneficiary}, {name: NodeId, var: node_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, product_sku: $product_sku, checkout_type: $checkout_type, key_fingerprint: $key_fingerprint, entitlements: $entitlements, client_token: $client_token, beneficiary: $beneficiary, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a grant for the specified license. A grant shares the use of license entitlements with a specific Amazon Web Services account, an organization, or an organizational unit (OU). For more information, see Granted licenses in License Manager (https://docs.aws.amazon.com/license-manager/latest/userguide/granted-licenses.html) in the License Manager User Guide.
#
# POST /
# Returns: record<GrantArn: string, Status: string, Version: string>
# operationId: CreateGrant
export def "create-grant" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  grant_name: string # Grant name.
  license_arn: string # Amazon Resource Name (ARN) of the license.
  principals: list<string> # The grant principals. You can specify one of the following as an Amazon Resource Name (ARN): An Amazon Web Services account, which includes only the account specified. An organizational unit (OU), which includes all accounts in the OU. An organization, which will include all accounts across your organization.
  home_region: string # Home Region of the grant.
  allowed_operations: list<string> # Allowed operations for the grant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateGrant"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: GrantName, var: grant_name}, {name: LicenseArn, var: license_arn}, {name: Principals, var: principals}, {name: HomeRegion, var: home_region}, {name: AllowedOperations, var: allowed_operations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, grant_name: $grant_name, license_arn: $license_arn, principals: $principals, home_region: $home_region, allowed_operations: $allowed_operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of the specified grant. For more information, see Granted licenses in License Manager (https://docs.aws.amazon.com/license-manager/latest/userguide/granted-licenses.html) in the License Manager User Guide.
#
# POST /
# Returns: record<GrantArn: string, Status: string, Version: string>
# operationId: CreateGrantVersion
export def "create-grant-version" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  grant_arn: string # Amazon Resource Name (ARN) of the grant.
  --grant-name: string # Grant name.
  --allowed-operations: list<string> # Allowed operations for the grant.
  --status: string@status-completer # Grant status.
  --status-reason: string # Grant status reason.
  --source-version: string # Current version of the grant.
  --options: record # The options you can specify when you create a new version of a grant, such as activation override behavior. For more information, see Granted licenses in License Manager (https://docs.aws.amazon.com/license-manager/latest/userguide/granted-licenses.html) in the License Manager User Guide. — shape: {ActivationOverrideBehavior?: "DISTRIBUTED_GRANTS_ONLY"|"ALL_GRANTS_PERMITTED_BY_ISSUER"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateGrantVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClientToken, var: client_token}, {name: GrantArn, var: grant_arn}, {name: GrantName, var: grant_name}, {name: AllowedOperations, var: allowed_operations}, {name: Status, var: status}, {name: StatusReason, var: status_reason}, {name: SourceVersion, var: source_version}, {name: Options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, grant_arn: $grant_arn, grant_name: $grant_name, allowed_operations: $allowed_operations, status: $status, status_reason: $status_reason, source_version: $source_version, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a license.
#
# POST /
# Returns: record<LicenseArn: string, Status: string, Version: string>
# operationId: CreateLicense
export def "create-license" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  license_name: string # License name.
  product_name: string # Product name.
  product_sku: string # Product SKU.
  issuer: record # Details about the issuer of a license. — shape: {Name: string, SignKey?: string}
  home_region: string # Home Region for the license.
  validity: record # Describes a time range, in ISO8601-UTC format. — shape: {Begin: string, End?: string}
  entitlements: list # License entitlements. — item shape: {Name: string, Value?: string, MaxCount?: int, Overage?: bool, Unit: "Count"|"None"|"Seconds"|"Microseconds"|"Milliseconds"|"Bytes"|"Kilobytes"|"Megabytes"|"Gigabytes"|"Terabytes"|"Bits"|"Kilobits"|"Megabits"|"Gigabits"|"Terabits"|"Percent"|"Bytes/Second"|"Kilobytes/Second"|"Megabytes/Second"|"Gigabytes/Second"|"Terabytes/Second"|"Bits/Second"|"Kilobits/Second"|"Megabits/Second"|"Gigabits/Second"|"Terabits/Second"|"Count/Second", AllowCheckIn?: bool}
  beneficiary: string # License beneficiary.
  consumption_configuration: record # Details about a consumption configuration. — shape: {RenewType?: "None"|"Weekly"|"Monthly", ProvisionalConfiguration?: record, BorrowConfiguration?: record}
  --license-metadata: list # Information about the license. — item shape: {Name?: string, Value?: string}
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseName, var: license_name}, {name: ProductName, var: product_name}, {name: ProductSKU, var: product_sku}, {name: Issuer, var: issuer}, {name: HomeRegion, var: home_region}, {name: Validity, var: validity}, {name: Entitlements, var: entitlements}, {name: Beneficiary, var: beneficiary}, {name: ConsumptionConfiguration, var: consumption_configuration}, {name: LicenseMetadata, var: license_metadata}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_name: $license_name, product_name: $product_name, product_sku: $product_sku, issuer: $issuer, home_region: $home_region, validity: $validity, entitlements: $entitlements, beneficiary: $beneficiary, consumption_configuration: $consumption_configuration, license_metadata: $license_metadata, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a license configuration. A license configuration is an abstraction of a customer license agreement that can be consumed and enforced by License Manager. Components include specifications for the license type (licensing by instance, socket, CPU, or vCPU), allowed tenancy (shared tenancy, Dedicated Instance, Dedicated Host, or all of these), license affinity to host (how long a license must be associated with a host), and the number of licenses purchased and used.
#
# POST /
# Returns: record<LicenseConfigurationArn: string>
# operationId: CreateLicenseConfiguration
export def "create-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  name: string # Name of the license configuration.
  --description: string # Description of the license configuration.
  license_counting_type: string@license-counting-type-completer # Dimension used to track the license inventory.
  --license-count: int # Number of licenses managed by the license configuration.
  --license-count-hard-limit: oneof<nothing, bool> # Indicates whether hard or soft license enforcement is used. Exceeding a hard limit blocks the launch of new instances.
  --license-rules: list<string> # License rules. The syntax is #name=value (for example, #allowedTenancy=EC2-DedicatedHost). The available rules vary by dimension, as follows. Cores dimension: allowedTenancy | licenseAffinityToHost | maximumCores | minimumCores Instances dimension: allowedTenancy | maximumCores | minimumCores | maximumSockets | minimumSockets | maximumVcpus | minimumVcpus Sockets dimension: allowedTenancy | licenseAffinityToHost | maximumSockets | minimumSockets vCPUs dimension: allowedTenancy | honorVcpuOptimization | maximumVcpus | minimumVcpus The unit for licenseAffinityToHost is days and the range is 1 to 180. The possible values for allowedTenancy are EC2-Default, EC2-DedicatedHost, and EC2-DedicatedInstance. The possible values for honorVcpuOptimization are True and False.
  --tags: list # Tags to add to the license configuration. — item shape: {Key?: string, Value?: string}
  --disassociate-when-not-found: oneof<nothing, bool> # When true, disassociates a resource when software is uninstalled.
  --product-information-list: list # Product information. — item shape: {ResourceType: string, ProductInformationFilterList: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Description, var: description}, {name: LicenseCountingType, var: license_counting_type}, {name: LicenseCount, var: license_count}, {name: LicenseCountHardLimit, var: license_count_hard_limit}, {name: LicenseRules, var: license_rules}, {name: Tags, var: tags}, {name: DisassociateWhenNotFound, var: disassociate_when_not_found}, {name: ProductInformationList, var: product_information_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, license_counting_type: $license_counting_type, license_count: $license_count, license_count_hard_limit: $license_count_hard_limit, license_rules: $license_rules, tags: $tags, disassociate_when_not_found: $disassociate_when_not_found, product_information_list: $product_information_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new license conversion task.
#
# POST /
# Returns: record<LicenseConversionTaskId: string>
# operationId: CreateLicenseConversionTaskForResource
export def "create-license-conversion-task-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource you are converting the license type for.
  source_license_context: record # Information about a license type conversion task. — shape: {UsageOperation?: string}
  destination_license_context: record # Information about a license type conversion task. — shape: {UsageOperation?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateLicenseConversionTaskForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: SourceLicenseContext, var: source_license_context}, {name: DestinationLicenseContext, var: destination_license_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, source_license_context: $source_license_context, destination_license_context: $destination_license_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a report generator.
#
# POST /
# Returns: record<LicenseManagerReportGeneratorArn: string>
# operationId: CreateLicenseManagerReportGenerator
export def "create-license-manager-report-generator" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  report_generator_name: string # Name of the report generator.
  type: list<string> # Type of reports to generate. The following report types an be generated: License configuration report - Reports the number and details of consumed licenses for a license configuration. Resource report - Reports the tracked licenses and resource consumption for a license configuration.
  report_context: record # Details of the license configuration that this generator reports on. — shape: {licenseConfigurationArns: list<string>}
  report_frequency: record # Details about how frequently reports are generated. — shape: {value?: int, period?: "DAY"|"WEEK"|"MONTH"}
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --description: string # Description of the report generator.
  --tags: list # Tags to add to the report generator. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateLicenseManagerReportGenerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReportGeneratorName, var: report_generator_name}, {name: Type, var: type}, {name: ReportContext, var: report_context}, {name: ReportFrequency, var: report_frequency}, {name: ClientToken, var: client_token}, {name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_generator_name: $report_generator_name, type: $type, report_context: $report_context, report_frequency: $report_frequency, client_token: $client_token, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of the specified license.
#
# POST /
# Returns: record<LicenseArn: string, Version: string, Status: string>
# operationId: CreateLicenseVersion
export def "create-license-version" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  license_arn: string # Amazon Resource Name (ARN) of the license.
  license_name: string # License name.
  product_name: string # Product name.
  issuer: record # Details about the issuer of a license. — shape: {Name: string, SignKey?: string}
  home_region: string # Home Region of the license.
  validity: record # Describes a time range, in ISO8601-UTC format. — shape: {Begin: string, End?: string}
  --license-metadata: list # Information about the license. — item shape: {Name?: string, Value?: string}
  entitlements: list # License entitlements. — item shape: {Name: string, Value?: string, MaxCount?: int, Overage?: bool, Unit: "Count"|"None"|"Seconds"|"Microseconds"|"Milliseconds"|"Bytes"|"Kilobytes"|"Megabytes"|"Gigabytes"|"Terabytes"|"Bits"|"Kilobits"|"Megabits"|"Gigabits"|"Terabits"|"Percent"|"Bytes/Second"|"Kilobytes/Second"|"Megabytes/Second"|"Gigabytes/Second"|"Terabytes/Second"|"Bits/Second"|"Kilobits/Second"|"Megabits/Second"|"Gigabits/Second"|"Terabits/Second"|"Count/Second", AllowCheckIn?: bool}
  consumption_configuration: record # Details about a consumption configuration. — shape: {RenewType?: "None"|"Weekly"|"Monthly", ProvisionalConfiguration?: record, BorrowConfiguration?: record}
  status: string@status-completer-1 # License status.
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --source-version: string # Current version of the license.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateLicenseVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: LicenseName, var: license_name}, {name: ProductName, var: product_name}, {name: Issuer, var: issuer}, {name: HomeRegion, var: home_region}, {name: Validity, var: validity}, {name: LicenseMetadata, var: license_metadata}, {name: Entitlements, var: entitlements}, {name: ConsumptionConfiguration, var: consumption_configuration}, {name: Status, var: status}, {name: ClientToken, var: client_token}, {name: SourceVersion, var: source_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, license_name: $license_name, product_name: $product_name, issuer: $issuer, home_region: $home_region, validity: $validity, license_metadata: $license_metadata, entitlements: $entitlements, consumption_configuration: $consumption_configuration, status: $status, client_token: $client_token, source_version: $source_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a long-lived token. A refresh token is a JWT token used to get an access token. With an access token, you can call AssumeRoleWithWebIdentity to get role credentials that you can use to call License Manager to manage the specified license.
#
# POST /
# Returns: record<TokenId: string, TokenType: string, Token: string>
# operationId: CreateToken
export def "create-token" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  license_arn: string # Amazon Resource Name (ARN) of the license. The ARN is mapped to the aud claim of the JWT token.
  --role-arns: list<string> # Amazon Resource Name (ARN) of the IAM roles to embed in the token. License Manager does not check whether the roles are in use.
  --expiration-in-days: int # Token expiration, in days, counted from token creation. The default is 365 days.
  --token-properties: list<string> # Data specified by the caller to be included in the JWT token. The data is mapped to the amr claim of the JWT token.
  client_token: string # Idempotency token, valid for 10 minutes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.CreateToken"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: RoleArns, var: role_arns}, {name: ExpirationInDays, var: expiration_in_days}, {name: TokenProperties, var: token_properties}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, role_arns: $role_arns, expiration_in_days: $expiration_in_days, token_properties: $token_properties, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified grant.
#
# POST /
# Returns: record<GrantArn: string, Status: string, Version: string>
# operationId: DeleteGrant
export def "delete-grant" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  grant_arn: string # Amazon Resource Name (ARN) of the grant.
  --status-reason: string # The Status reason for the delete request.
  version: string # Current version of the grant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.DeleteGrant"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArn, var: grant_arn}, {name: StatusReason, var: status_reason}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arn: $grant_arn, status_reason: $status_reason, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified license.
#
# POST /
# Returns: record<Status: string, DeletionDate: string>
# operationId: DeleteLicense
export def "delete-license" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  license_arn: string # Amazon Resource Name (ARN) of the license.
  source_version: string # Current version of the license.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.DeleteLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: SourceVersion, var: source_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, source_version: $source_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified license configuration. You cannot delete a license configuration that is in use.
#
# POST /
# Returns: record
# operationId: DeleteLicenseConfiguration
export def "delete-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  license_configuration_arn: string # ID of the license configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.DeleteLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified report generator. This action deletes the report generator, which stops it from generating future reports. The action cannot be reversed. It has no effect on the previous reports from this generator.
#
# POST /
# Returns: record
# operationId: DeleteLicenseManagerReportGenerator
export def "delete-license-manager-report-generator" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  license_manager_report_generator_arn: string # Amazon Resource Name (ARN) of the report generator to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.DeleteLicenseManagerReportGenerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseManagerReportGeneratorArn, var: license_manager_report_generator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_manager_report_generator_arn: $license_manager_report_generator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified token. Must be called in the license home Region.
#
# POST /
# Returns: record
# operationId: DeleteToken
export def "delete-token" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  token_id: string # Token ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.DeleteToken"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TokenId, var: token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extends the expiration date for license consumption.
#
# POST /
# Returns: record<LicenseConsumptionToken: string, Expiration: string>
# operationId: ExtendLicenseConsumption
export def "extend-license-consumption" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  license_consumption_token: string # License consumption token.
  --body-dry-run: oneof<nothing, bool> # Checks whether you have the required permissions for the action, without actually making the request. Provides an error response if you do not have the required permissions. (spec name: DryRun)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ExtendLicenseConsumption"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConsumptionToken, var: license_consumption_token}, {name: DryRun, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_consumption_token: $license_consumption_token, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a temporary access token to use with AssumeRoleWithWebIdentity. Access tokens are valid for one hour.
#
# POST /
# Returns: record<AccessToken: string>
# operationId: GetAccessToken
export def "get-access-token" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  --body-token: string # Refresh token, encoded as a JWT token. (spec name: Token)
  --token-properties: list<string> # Token properties to validate against those present in the JWT token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetAccessToken"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Token, var: body_token, required: true}, {name: TokenProperties, var: token_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_token: $body_token, token_properties: $token_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets detailed information about the specified grant.
#
# POST /
# Returns: record<Grant: record<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list<string>, Options: record<ActivationOverrideBehavior: string>>>
# operationId: GetGrant
export def "get-grant" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  grant_arn: string # Amazon Resource Name (ARN) of the grant.
  --version: string # Grant version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetGrant"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArn, var: grant_arn}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arn: $grant_arn, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets detailed information about the specified license.
#
# POST /
# Returns: record<License: record<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record<Name: string, SignKey: string, KeyFingerprint: string>, HomeRegion: string, Status: string, Validity: record<Begin: string, End: string>, Beneficiary: string, Entitlements: list<record>, ConsumptionConfiguration: record<RenewType: string, ProvisionalConfiguration: record, BorrowConfiguration: record>, LicenseMetadata: list<record>, CreateTime: string, Version: string>>
# operationId: GetLicense
export def "get-license" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  license_arn: string # Amazon Resource Name (ARN) of the license.
  --version: string # License version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetLicense"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: Version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets detailed information about the specified license configuration.
#
# POST /
# Returns: record<LicenseConfigurationId: string, LicenseConfigurationArn: string, Name: string, Description: string, LicenseCountingType: string, LicenseRules: list<string>, LicenseCount: int, LicenseCountHardLimit: bool, ConsumedLicenses: int, Status: string, OwnerAccountId: string, ConsumedLicenseSummaryList: table<ResourceType: string, ConsumedLicenses: int>, ManagedResourceSummaryList: table<ResourceType: string, AssociationCount: int>, Tags: table<Key: string, Value: string>, ProductInformationList: table<ResourceType: string, ProductInformationFilterList: list>, AutomatedDiscoveryInformation: record<LastRunTime: string>, DisassociateWhenNotFound: bool>
# operationId: GetLicenseConfiguration
export def "get-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  license_configuration_arn: string # Amazon Resource Name (ARN) of the license configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified license type conversion task.
#
# POST /
# Returns: record<LicenseConversionTaskId: string, ResourceArn: string, SourceLicenseContext: record<UsageOperation: string>, DestinationLicenseContext: record<UsageOperation: string>, StatusMessage: string, Status: string, StartTime: string, LicenseConversionTime: string, EndTime: string>
# operationId: GetLicenseConversionTask
export def "get-license-conversion-task" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  license_conversion_task_id: string # ID of the license type conversion task to retrieve information on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetLicenseConversionTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConversionTaskId, var: license_conversion_task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_conversion_task_id: $license_conversion_task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified report generator.
#
# POST /
# Returns: record<ReportGenerator: record<ReportGeneratorName: string, ReportType: list<string>, ReportContext: record<licenseConfigurationArns: list>, ReportFrequency: record<value: int, period: string>, LicenseManagerReportGeneratorArn: string, LastRunStatus: string, LastRunFailureReason: string, LastReportGenerationTime: string, ReportCreatorAccount: string, Description: string, S3Location: record<bucket: string, keyPrefix: string>, CreateTime: string, Tags: list<record>>>
# operationId: GetLicenseManagerReportGenerator
export def "get-license-manager-report-generator" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  license_manager_report_generator_arn: string # Amazon Resource Name (ARN) of the report generator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetLicenseManagerReportGenerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseManagerReportGeneratorArn, var: license_manager_report_generator_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_manager_report_generator_arn: $license_manager_report_generator_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets detailed information about the usage of the specified license.
#
# POST /
# Returns: record<LicenseUsage: record<EntitlementUsages: list<record>>>
# operationId: GetLicenseUsage
export def "get-license-usage" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  license_arn: string # Amazon Resource Name (ARN) of the license.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetLicenseUsage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the License Manager settings for the current Region.
#
# POST /
# Returns: record<S3BucketArn: string, SnsTopicArn: string, OrganizationConfiguration: record<EnableIntegration: bool>, EnableCrossAccountsDiscovery: bool, LicenseManagerResourceShareArn: string>
# operationId: GetServiceSettings
export def "get-service-settings" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.GetServiceSettings"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resource associations for the specified license configuration. Resource associations need not consume licenses from a license configuration. For example, an AMI or a stopped instance might not consume a license (depending on the license rules).
#
# POST /
# Returns: record<LicenseConfigurationAssociations: table<ResourceArn: string, ResourceType: string, ResourceOwnerId: string, AssociationTime: string, AmiAssociationScope: string>, NextToken: string>
# operationId: ListAssociationsForLicenseConfiguration
export def "list-associations-for-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  license_configuration_arn: string # Amazon Resource Name (ARN) of a license configuration.
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListAssociationsForLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the grants distributed for the specified license.
#
# POST /
# Returns: record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>
# operationId: ListDistributedGrants
export def "list-distributed-grants" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  --grant-arns: list<string> # Amazon Resource Names (ARNs) of the grants.
  --filters: list # Filters to scope the results. The following filters are supported: LicenseArn GrantStatus GranteePrincipalARN ProductSKU LicenseIssuerName — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListDistributedGrants"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArns, var: grant_arns}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arns: $grant_arns, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the license configuration operations that failed.
#
# POST /
# Returns: record<LicenseOperationFailureList: table<ResourceArn: string, ResourceType: string, ErrorMessage: string, FailureTime: string, OperationName: string, ResourceOwnerId: string, OperationRequestedBy: string, MetadataList: list>, NextToken: string>
# operationId: ListFailuresForLicenseConfigurationOperations
export def "list-failures-for-license-configuration-operations" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  license_configuration_arn: string # Amazon Resource Name of the license configuration.
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListFailuresForLicenseConfigurationOperations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the license configurations for your account.
#
# POST /
# Returns: record<LicenseConfigurations: table<LicenseConfigurationId: string, LicenseConfigurationArn: string, Name: string, Description: string, LicenseCountingType: string, LicenseRules: list, LicenseCount: int, LicenseCountHardLimit: bool, DisassociateWhenNotFound: bool, ConsumedLicenses: int, Status: string, OwnerAccountId: string, ConsumedLicenseSummaryList: list, ManagedResourceSummaryList: list, ProductInformationList: list, AutomatedDiscoveryInformation: record>, NextToken: string>
# operationId: ListLicenseConfigurations
export def "list-license-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --license-configuration-arns: list<string> # Amazon Resource Names (ARN) of the license configurations.
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
  --filters: list # Filters to scope the results. The following filters and logical operators are supported: licenseCountingType - The dimension for which licenses are counted. Possible values are vCPU | Instance | Core | Socket. Logical operators are EQUALS | NOT_EQUALS. enforceLicenseCount - A Boolean value that indicates whether hard license enforcement is used. Logical operators are EQUALS | NOT_EQUALS. usagelimitExceeded - A Boolean value that indicates whether the available licenses have been exceeded. Logical operators are EQUALS | NOT_EQUALS. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenseConfigurations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArns, var: license_configuration_arns}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arns: $license_configuration_arns, max_results: $max_results, next_token: $next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the license type conversion tasks for your account.
#
# POST /
# Returns: record<LicenseConversionTasks: table<LicenseConversionTaskId: string, ResourceArn: string, SourceLicenseContext: record, DestinationLicenseContext: record, Status: string, StatusMessage: string, StartTime: string, LicenseConversionTime: string, EndTime: string>, NextToken: string>
# operationId: ListLicenseConversionTasks
export def "list-license-conversion-tasks" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
  --filters: list # Filters to scope the results. Valid filters are ResourceArns and Status. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenseConversionTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, next_token: $next_token, max_results: $max_results, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the report generators for your account.
#
# POST /
# Returns: record<ReportGenerators: table<ReportGeneratorName: string, ReportType: list, ReportContext: record, ReportFrequency: record, LicenseManagerReportGeneratorArn: string, LastRunStatus: string, LastRunFailureReason: string, LastReportGenerationTime: string, ReportCreatorAccount: string, Description: string, S3Location: record, CreateTime: string, Tags: list>, NextToken: string>
# operationId: ListLicenseManagerReportGenerators
export def "list-license-manager-report-generators" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  --filters: list # Filters to scope the results. The following filters are supported: LicenseConfigurationArn — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenseManagerReportGenerators"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the license configurations for the specified resource.
#
# POST /
# Returns: record<LicenseSpecifications: table<LicenseConfigurationArn: string, AmiAssociationScope: string>, NextToken: string>
# operationId: ListLicenseSpecificationsForResource
export def "list-license-specifications-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resource_arn: string # Amazon Resource Name (ARN) of a resource that has an associated license configuration.
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenseSpecificationsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all versions of the specified license.
#
# POST /
# Returns: record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string>, NextToken: string>
# operationId: ListLicenseVersions
export def "list-license-versions" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  license_arn: string # Amazon Resource Name (ARN) of the license.
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenseVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the licenses for your account.
#
# POST /
# Returns: record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string>, NextToken: string>
# operationId: ListLicenses
export def "list-licenses" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  --license-arns: list<string> # Amazon Resource Names (ARNs) of the licenses.
  --filters: list # Filters to scope the results. The following filters are supported: Beneficiary ProductSKU Fingerprint Status — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListLicenses"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArns, var: license_arns}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arns: $license_arns, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists grants that are received. Received grants are grants created while specifying the recipient as this Amazon Web Services account, your organization, or an organizational unit (OU) to which this member account belongs.
#
# POST /
# Returns: record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>
# operationId: ListReceivedGrants
export def "list-received-grants" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  --grant-arns: list<string> # Amazon Resource Names (ARNs) of the grants.
  --filters: list # Filters to scope the results. The following filters are supported: ProductSKU LicenseIssuerName LicenseArn GrantStatus GranterAccountId — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListReceivedGrants"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArns, var: grant_arns}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arns: $grant_arns, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the grants received for all accounts in the organization.
#
# POST /
# Returns: record<Grants: table<GrantArn: string, GrantName: string, ParentArn: string, LicenseArn: string, GranteePrincipalArn: string, HomeRegion: string, GrantStatus: string, StatusReason: string, Version: string, GrantedOperations: list, Options: record>, NextToken: string>
# operationId: ListReceivedGrantsForOrganization
export def "list-received-grants-for-organization" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  license_arn: string # The Amazon Resource Name (ARN) of the received license.
  --filters: list # Filters to scope the results. The following filters are supported: ParentArn GranteePrincipalArn — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListReceivedGrantsForOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArn, var: license_arn}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arn: $license_arn, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists received licenses.
#
# POST /
# Returns: record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string, ReceivedMetadata: record>, NextToken: string>
# operationId: ListReceivedLicenses
export def "list-received-licenses" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  --license-arns: list<string> # Amazon Resource Names (ARNs) of the licenses.
  --filters: list # Filters to scope the results. The following filters are supported: ProductSKU Status Fingerprint IssuerName Beneficiary — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListReceivedLicenses"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseArns, var: license_arns}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_arns: $license_arns, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the licenses received for all accounts in the organization.
#
# POST /
# Returns: record<Licenses: table<LicenseArn: string, LicenseName: string, ProductName: string, ProductSKU: string, Issuer: record, HomeRegion: string, Status: string, Validity: record, Beneficiary: string, Entitlements: list, ConsumptionConfiguration: record, LicenseMetadata: list, CreateTime: string, Version: string, ReceivedMetadata: record>, NextToken: string>
# operationId: ListReceivedLicensesForOrganization
export def "list-received-licenses-for-organization" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  --filters: list # Filters to scope the results. The following filters are supported: Beneficiary ProductSKU — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListReceivedLicensesForOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists resources managed using Systems Manager inventory.
#
# POST /
# Returns: record<ResourceInventoryList: table<ResourceId: string, ResourceType: string, ResourceArn: string, Platform: string, PlatformVersion: string, ResourceOwningAccountId: string>, NextToken: string>
# operationId: ListResourceInventory
export def "list-resource-inventory" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
  --filters: list # Filters to scope the results. The following filters and logical operators are supported: account_id - The ID of the Amazon Web Services account that owns the resource. Logical operators are EQUALS | NOT_EQUALS. application_name - The name of the application. Logical operators are EQUALS | BEGINS_WITH. license_included - The type of license included. Logical operators are EQUALS | NOT_EQUALS. Possible values are sql-server-enterprise | sql-server-standard | sql-server-web | windows-server-datacenter. platform - The platform of the resource. Logical operators are EQUALS | BEGINS_WITH. resource_id - The ID of the resource. Logical operators are EQUALS | NOT_EQUALS. tag:<key> - The key/value combination of a tag assigned to the resource. Logical operators are EQUALS (single account) or EQUALS | NOT_EQUALS (cross account). — item shape: {Name: string, Condition: "EQUALS"|"NOT_EQUALS"|"BEGINS_WITH"|"CONTAINS", Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListResourceInventory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, max_results: $max_results, next_token: $next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for the specified license configuration.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  resource_arn: string # Amazon Resource Name (ARN) of the license configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your tokens.
#
# POST /
# Returns: record<Tokens: table<TokenId: string, TokenType: string, LicenseArn: string, ExpirationTime: string, TokenProperties: list, RoleArns: list, Status: string>, NextToken: string>
# operationId: ListTokens
export def "list-tokens" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  --token-ids: list<string> # Token IDs.
  --filters: list # Filters to scope the results. The following filter is supported: LicenseArns — item shape: {Name?: string, Values?: list<string>}
  --next-token: string # Token for the next set of results.
  --max-results: int # Maximum number of results to return in a single call.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListTokens"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TokenIds, var: token_ids}, {name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, token_ids: $token_ids, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all license usage records for a license configuration, displaying license consumption details by resource at a selected point in time. Use this action to audit the current license consumption for any license inventory and configuration.
#
# POST /
# Returns: record<LicenseConfigurationUsageList: table<ResourceArn: string, ResourceType: string, ResourceStatus: string, ResourceOwnerId: string, AssociationTime: string, ConsumedLicenses: int>, NextToken: string>
# operationId: ListUsageForLicenseConfiguration
export def "list-usage-for-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  license_configuration_arn: string # Amazon Resource Name (ARN) of the license configuration.
  --max-results: int # Maximum number of results to return in a single call.
  --next-token: string # Token for the next set of results.
  --filters: list # Filters to scope the results. The following filters and logical operators are supported: resourceArn - The ARN of the license configuration resource. Logical operators are EQUALS | NOT_EQUALS. resourceType - The resource type (EC2_INSTANCE | EC2_HOST | EC2_AMI | SYSTEMS_MANAGER_MANAGED_INSTANCE). Logical operators are EQUALS | NOT_EQUALS. resourceAccount - The ID of the account that owns the resource. Logical operators are EQUALS | NOT_EQUALS. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.ListUsageForLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn, max_results: $max_results, next_token: $next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects the specified grant.
#
# POST /
# Returns: record<GrantArn: string, Status: string, Version: string>
# operationId: RejectGrant
export def "reject-grant" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  grant_arn: string # Amazon Resource Name (ARN) of the grant.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.RejectGrant"}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantArn, var: grant_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, grant_arn: $grant_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tags to the specified license configuration.
#
# POST /
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  resource_arn: string # Amazon Resource Name (ARN) of the license configuration.
  tags: list # One or more tags. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified tags from the specified license configuration.
#
# POST /
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  resource_arn: string # Amazon Resource Name (ARN) of the license configuration.
  tag_keys: list<string> # Keys identifying the tags to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the attributes of an existing license configuration.
#
# POST /
# Returns: record
# operationId: UpdateLicenseConfiguration
export def "update-license-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  license_configuration_arn: string # Amazon Resource Name (ARN) of the license configuration.
  --license-configuration-status: string@license-configuration-status-completer # New status of the license configuration.
  --license-rules: list<string> # New license rule. The only rule that you can add after you create a license configuration is licenseAffinityToHost.
  --license-count: int # New number of licenses managed by the license configuration.
  --license-count-hard-limit: oneof<nothing, bool> # New hard limit of the number of available licenses.
  --name: string # New name of the license configuration.
  --description: string # New description of the license configuration.
  --product-information-list: list # New product information. — item shape: {ResourceType: string, ProductInformationFilterList: list}
  --disassociate-when-not-found: oneof<nothing, bool> # When true, disassociates a resource when software is uninstalled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.UpdateLicenseConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseConfigurationArn, var: license_configuration_arn}, {name: LicenseConfigurationStatus, var: license_configuration_status}, {name: LicenseRules, var: license_rules}, {name: LicenseCount, var: license_count}, {name: LicenseCountHardLimit, var: license_count_hard_limit}, {name: Name, var: name}, {name: Description, var: description}, {name: ProductInformationList, var: product_information_list}, {name: DisassociateWhenNotFound, var: disassociate_when_not_found}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_configuration_arn: $license_configuration_arn, license_configuration_status: $license_configuration_status, license_rules: $license_rules, license_count: $license_count, license_count_hard_limit: $license_count_hard_limit, name: $name, description: $description, product_information_list: $product_information_list, disassociate_when_not_found: $disassociate_when_not_found
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a report generator. After you make changes to a report generator, it starts generating new reports within 60 minutes of being updated.
#
# POST /
# Returns: record
# operationId: UpdateLicenseManagerReportGenerator
export def "update-license-manager-report-generator" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  license_manager_report_generator_arn: string # Amazon Resource Name (ARN) of the report generator to update.
  report_generator_name: string # Name of the report generator.
  type: list<string> # Type of reports to generate. The following report types are supported: License configuration report - Reports the number and details of consumed licenses for a license configuration. Resource report - Reports the tracked licenses and resource consumption for a license configuration.
  report_context: record # Details of the license configuration that this generator reports on. — shape: {licenseConfigurationArns: list<string>}
  report_frequency: record # Details about how frequently reports are generated. — shape: {value?: int, period?: "DAY"|"WEEK"|"MONTH"}
  client_token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --description: string # Description of the report generator.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.UpdateLicenseManagerReportGenerator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LicenseManagerReportGeneratorArn, var: license_manager_report_generator_arn}, {name: ReportGeneratorName, var: report_generator_name}, {name: Type, var: type}, {name: ReportContext, var: report_context}, {name: ReportFrequency, var: report_frequency}, {name: ClientToken, var: client_token}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, license_manager_report_generator_arn: $license_manager_report_generator_arn, report_generator_name: $report_generator_name, type: $type, report_context: $report_context, report_frequency: $report_frequency, client_token: $client_token, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or removes the specified license configurations for the specified Amazon Web Services resource. You can update the license specifications of AMIs, instances, and hosts. You cannot update the license specifications for launch templates and CloudFormation templates, as they send license configurations to the operation that creates the resource.
#
# POST /
# Returns: record
# operationId: UpdateLicenseSpecificationsForResource
export def "update-license-specifications-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  resource_arn: string # Amazon Resource Name (ARN) of the Amazon Web Services resource.
  --add-license-specifications: list # ARNs of the license configurations to add. — item shape: {LicenseConfigurationArn: string, AmiAssociationScope?: string}
  --remove-license-specifications: list # ARNs of the license configurations to remove. — item shape: {LicenseConfigurationArn: string, AmiAssociationScope?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.UpdateLicenseSpecificationsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: AddLicenseSpecifications, var: add_license_specifications}, {name: RemoveLicenseSpecifications, var: remove_license_specifications}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, add_license_specifications: $add_license_specifications, remove_license_specifications: $remove_license_specifications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates License Manager settings for the current Region.
#
# POST /
# Returns: record
# operationId: UpdateServiceSettings
export def "update-service-settings" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --s3-bucket-arn: string # Amazon Resource Name (ARN) of the Amazon S3 bucket where the License Manager information is stored.
  --sns-topic-arn: string # Amazon Resource Name (ARN) of the Amazon SNS topic used for License Manager alerts.
  --organization-configuration: record # Configuration information for Organizations. — shape: {EnableIntegration: bool}
  --enable-cross-accounts-discovery: oneof<nothing, bool> # Activates cross-account discovery.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSLicenseManager.UpdateServiceSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: S3BucketArn, var: s3_bucket_arn}, {name: SnsTopicArn, var: sns_topic_arn}, {name: OrganizationConfiguration, var: organization_configuration}, {name: EnableCrossAccountsDiscovery, var: enable_cross_accounts_discovery}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, s3_bucket_arn: $s3_bucket_arn, sns_topic_arn: $sns_topic_arn, organization_configuration: $organization_configuration, enable_cross_accounts_discovery: $enable_cross_accounts_discovery
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
