# Auto-generated client for AWS Direct Connect v2012-10-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/directconnect/2012-10-25/openapi.json
# Auth: --token flag or $env.AWS_DIRECT_CONNECT_TOKEN

const CLIENT = {
  base_url: "http://directconnect.us-east-1.amazonaws.com"
  token_env_var: "AWS_DIRECT_CONNECT_TOKEN"
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

def base-url-completer [] { ["http://directconnect.us-east-1.amazonaws.com" "http://directconnect.us-east-2.amazonaws.com" "http://directconnect.us-west-1.amazonaws.com" "http://directconnect.us-west-2.amazonaws.com" "http://directconnect.us-gov-west-1.amazonaws.com" "http://directconnect.us-gov-east-1.amazonaws.com" "http://directconnect.ca-central-1.amazonaws.com" "http://directconnect.eu-north-1.amazonaws.com" "http://directconnect.eu-west-1.amazonaws.com" "http://directconnect.eu-west-2.amazonaws.com" "http://directconnect.eu-west-3.amazonaws.com" "http://directconnect.eu-central-1.amazonaws.com" "http://directconnect.eu-south-1.amazonaws.com" "http://directconnect.af-south-1.amazonaws.com" "http://directconnect.ap-northeast-1.amazonaws.com" "http://directconnect.ap-northeast-2.amazonaws.com" "http://directconnect.ap-northeast-3.amazonaws.com" "http://directconnect.ap-southeast-1.amazonaws.com" "http://directconnect.ap-southeast-2.amazonaws.com" "http://directconnect.ap-east-1.amazonaws.com" "http://directconnect.ap-south-1.amazonaws.com" "http://directconnect.sa-east-1.amazonaws.com" "http://directconnect.me-south-1.amazonaws.com" "https://directconnect.us-east-1.amazonaws.com" "https://directconnect.us-east-2.amazonaws.com" "https://directconnect.us-west-1.amazonaws.com" "https://directconnect.us-west-2.amazonaws.com" "https://directconnect.us-gov-west-1.amazonaws.com" "https://directconnect.us-gov-east-1.amazonaws.com" "https://directconnect.ca-central-1.amazonaws.com" "https://directconnect.eu-north-1.amazonaws.com" "https://directconnect.eu-west-1.amazonaws.com" "https://directconnect.eu-west-2.amazonaws.com" "https://directconnect.eu-west-3.amazonaws.com" "https://directconnect.eu-central-1.amazonaws.com" "https://directconnect.eu-south-1.amazonaws.com" "https://directconnect.af-south-1.amazonaws.com" "https://directconnect.ap-northeast-1.amazonaws.com" "https://directconnect.ap-northeast-2.amazonaws.com" "https://directconnect.ap-northeast-3.amazonaws.com" "https://directconnect.ap-southeast-1.amazonaws.com" "https://directconnect.ap-southeast-2.amazonaws.com" "https://directconnect.ap-east-1.amazonaws.com" "https://directconnect.ap-south-1.amazonaws.com" "https://directconnect.sa-east-1.amazonaws.com" "https://directconnect.me-south-1.amazonaws.com" "http://directconnect.cn-north-1.amazonaws.com.cn" "http://directconnect.cn-northwest-1.amazonaws.com.cn" "https://directconnect.cn-north-1.amazonaws.com.cn" "https://directconnect.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["OvertureService.AcceptDirectConnectGatewayAssociationProposal"] }
def x-amz-target-completer-1 [] { ["OvertureService.AllocateConnectionOnInterconnect"] }
def x-amz-target-completer-2 [] { ["OvertureService.AllocateHostedConnection"] }
def x-amz-target-completer-3 [] { ["OvertureService.AllocatePrivateVirtualInterface"] }
def x-amz-target-completer-4 [] { ["OvertureService.AllocatePublicVirtualInterface"] }
def x-amz-target-completer-5 [] { ["OvertureService.AllocateTransitVirtualInterface"] }
def x-amz-target-completer-6 [] { ["OvertureService.AssociateConnectionWithLag"] }
def x-amz-target-completer-7 [] { ["OvertureService.AssociateHostedConnection"] }
def x-amz-target-completer-8 [] { ["OvertureService.AssociateMacSecKey"] }
def x-amz-target-completer-9 [] { ["OvertureService.AssociateVirtualInterface"] }
def x-amz-target-completer-10 [] { ["OvertureService.ConfirmConnection"] }
def x-amz-target-completer-11 [] { ["OvertureService.ConfirmCustomerAgreement"] }
def x-amz-target-completer-12 [] { ["OvertureService.ConfirmPrivateVirtualInterface"] }
def x-amz-target-completer-13 [] { ["OvertureService.ConfirmPublicVirtualInterface"] }
def x-amz-target-completer-14 [] { ["OvertureService.ConfirmTransitVirtualInterface"] }
def x-amz-target-completer-15 [] { ["OvertureService.CreateBGPPeer"] }
def x-amz-target-completer-16 [] { ["OvertureService.CreateConnection"] }
def x-amz-target-completer-17 [] { ["OvertureService.CreateDirectConnectGateway"] }
def x-amz-target-completer-18 [] { ["OvertureService.CreateDirectConnectGatewayAssociation"] }
def x-amz-target-completer-19 [] { ["OvertureService.CreateDirectConnectGatewayAssociationProposal"] }
def x-amz-target-completer-20 [] { ["OvertureService.CreateInterconnect"] }
def x-amz-target-completer-21 [] { ["OvertureService.CreateLag"] }
def x-amz-target-completer-22 [] { ["OvertureService.CreatePrivateVirtualInterface"] }
def x-amz-target-completer-23 [] { ["OvertureService.CreatePublicVirtualInterface"] }
def x-amz-target-completer-24 [] { ["OvertureService.CreateTransitVirtualInterface"] }
def x-amz-target-completer-25 [] { ["OvertureService.DeleteBGPPeer"] }
def x-amz-target-completer-26 [] { ["OvertureService.DeleteConnection"] }
def x-amz-target-completer-27 [] { ["OvertureService.DeleteDirectConnectGateway"] }
def x-amz-target-completer-28 [] { ["OvertureService.DeleteDirectConnectGatewayAssociation"] }
def x-amz-target-completer-29 [] { ["OvertureService.DeleteDirectConnectGatewayAssociationProposal"] }
def x-amz-target-completer-30 [] { ["OvertureService.DeleteInterconnect"] }
def x-amz-target-completer-31 [] { ["OvertureService.DeleteLag"] }
def x-amz-target-completer-32 [] { ["OvertureService.DeleteVirtualInterface"] }
def loa-content-type-completer [] { ["application/pdf"] }
def x-amz-target-completer-33 [] { ["OvertureService.DescribeConnectionLoa"] }
def x-amz-target-completer-34 [] { ["OvertureService.DescribeConnections"] }
def x-amz-target-completer-35 [] { ["OvertureService.DescribeConnectionsOnInterconnect"] }
def x-amz-target-completer-36 [] { ["OvertureService.DescribeCustomerMetadata"] }
def x-amz-target-completer-37 [] { ["OvertureService.DescribeDirectConnectGatewayAssociationProposals"] }
def x-amz-target-completer-38 [] { ["OvertureService.DescribeDirectConnectGatewayAssociations"] }
def x-amz-target-completer-39 [] { ["OvertureService.DescribeDirectConnectGatewayAttachments"] }
def x-amz-target-completer-40 [] { ["OvertureService.DescribeDirectConnectGateways"] }
def x-amz-target-completer-41 [] { ["OvertureService.DescribeHostedConnections"] }
def x-amz-target-completer-42 [] { ["OvertureService.DescribeInterconnectLoa"] }
def x-amz-target-completer-43 [] { ["OvertureService.DescribeInterconnects"] }
def x-amz-target-completer-44 [] { ["OvertureService.DescribeLags"] }
def x-amz-target-completer-45 [] { ["OvertureService.DescribeLoa"] }
def x-amz-target-completer-46 [] { ["OvertureService.DescribeLocations"] }
def x-amz-target-completer-47 [] { ["OvertureService.DescribeRouterConfiguration"] }
def x-amz-target-completer-48 [] { ["OvertureService.DescribeTags"] }
def x-amz-target-completer-49 [] { ["OvertureService.DescribeVirtualGateways"] }
def x-amz-target-completer-50 [] { ["OvertureService.DescribeVirtualInterfaces"] }
def x-amz-target-completer-51 [] { ["OvertureService.DisassociateConnectionFromLag"] }
def x-amz-target-completer-52 [] { ["OvertureService.DisassociateMacSecKey"] }
def x-amz-target-completer-53 [] { ["OvertureService.ListVirtualInterfaceTestHistory"] }
def x-amz-target-completer-54 [] { ["OvertureService.StartBgpFailoverTest"] }
def x-amz-target-completer-55 [] { ["OvertureService.StopBgpFailoverTest"] }
def x-amz-target-completer-56 [] { ["OvertureService.TagResource"] }
def x-amz-target-completer-57 [] { ["OvertureService.UntagResource"] }
def x-amz-target-completer-58 [] { ["OvertureService.UpdateConnection"] }
def x-amz-target-completer-59 [] { ["OvertureService.UpdateDirectConnectGateway"] }
def x-amz-target-completer-60 [] { ["OvertureService.UpdateDirectConnectGatewayAssociation"] }
def x-amz-target-completer-61 [] { ["OvertureService.UpdateLag"] }
def x-amz-target-completer-62 [] { ["OvertureService.UpdateVirtualInterfaceAttributes"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-direct-connect-gateway-association-proposal: "record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>"
    allocate-connection-on-interconnect: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    allocate-hosted-connection: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    allocate-private-virtual-interface: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
    allocate-public-virtual-interface: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
    allocate-transit-virtual-interface: "record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>"
    associate-connection-with-lag: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    associate-hosted-connection: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    associate-mac-sec-key: "record<connectionId: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    associate-virtual-interface: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
    confirm-connection: "record<connectionState: string>"
    confirm-customer-agreement: "record<status: string>"
    confirm-private-virtual-interface: "record<virtualInterfaceState: string>"
    confirm-public-virtual-interface: "record<virtualInterfaceState: string>"
    confirm-transit-virtual-interface: "record<virtualInterfaceState: string>"
    create-bgp-peer: "record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>"
    create-connection: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    create-direct-connect-gateway: "record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>"
    create-direct-connect-gateway-association: "record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>"
    create-direct-connect-gateway-association-proposal: "record<directConnectGatewayAssociationProposal: record<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, existingAllowedPrefixesToDirectConnectGateway: list<record>, requestedAllowedPrefixesToDirectConnectGateway: list<record>>>"
    create-interconnect: "record<interconnectId: string, interconnectName: string, interconnectState: string, region: string, location: string, bandwidth: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string>"
    create-lag: "record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    create-private-virtual-interface: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
    create-public-virtual-interface: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
    create-transit-virtual-interface: "record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>"
    delete-bgp-peer: "record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>"
    delete-connection: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    delete-direct-connect-gateway: "record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>"
    delete-direct-connect-gateway-association: "record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>"
    delete-direct-connect-gateway-association-proposal: "record<directConnectGatewayAssociationProposal: record<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, existingAllowedPrefixesToDirectConnectGateway: list<record>, requestedAllowedPrefixesToDirectConnectGateway: list<record>>>"
    delete-interconnect: "record<interconnectState: string>"
    delete-lag: "record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    delete-virtual-interface: "record<virtualInterfaceState: string>"
    describe-connection-loa: "record<loa: record<loaContent: string, loaContentType: string>>"
    describe-connections: "record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>"
    describe-connections-on-interconnect: "record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>"
    describe-customer-metadata: "record<agreements: table<agreementName: string, status: string>, nniPartnerType: string>"
    describe-direct-connect-gateway-association-proposals: "record<directConnectGatewayAssociationProposals: table<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record, existingAllowedPrefixesToDirectConnectGateway: list, requestedAllowedPrefixesToDirectConnectGateway: list>, nextToken: string>"
    describe-direct-connect-gateway-associations: "record<directConnectGatewayAssociations: table<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record, associationId: string, allowedPrefixesToDirectConnectGateway: list, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>, nextToken: string>"
    describe-direct-connect-gateway-attachments: "record<directConnectGatewayAttachments: table<directConnectGatewayId: string, virtualInterfaceId: string, virtualInterfaceRegion: string, virtualInterfaceOwnerAccount: string, attachmentState: string, attachmentType: string, stateChangeError: string>, nextToken: string>"
    describe-direct-connect-gateways: "record<directConnectGateways: table<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>, nextToken: string>"
    describe-hosted-connections: "record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>"
    describe-interconnect-loa: "record<loa: record<loaContent: string, loaContentType: string>>"
    describe-interconnects: "record<interconnects: table<interconnectId: string, interconnectName: string, interconnectState: string, region: string, location: string, bandwidth: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string>>"
    describe-lags: "record<lags: table<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: list, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: list>>"
    describe-loa: "record<loaContent: string, loaContentType: string>"
    describe-locations: "record<locations: table<locationCode: string, locationName: string, region: string, availablePortSpeeds: list, availableProviders: list, availableMacSecPortSpeeds: list>>"
    describe-router-configuration: "record<customerRouterConfig: string, router: record<vendor: string, platform: string, software: string, xsltTemplateName: string, xsltTemplateNameForMacSec: string, routerTypeIdentifier: string>, virtualInterfaceId: string, virtualInterfaceName: string>"
    describe-tags: "record<resourceTags: table<resourceArn: string, tags: list>>"
    describe-virtual-gateways: "record<virtualGateways: table<virtualGatewayId: string, virtualGatewayState: string>>"
    describe-virtual-interfaces: "record<virtualInterfaces: table<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list, bgpPeers: list, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list, siteLinkEnabled: bool>>"
    disassociate-connection-from-lag: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    disassociate-mac-sec-key: "record<connectionId: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    list-virtual-interface-test-history: "record<virtualInterfaceTestHistory: table<testId: string, virtualInterfaceId: string, bgpPeers: list, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>, nextToken: string>"
    start-bgp-failover-test: "record<virtualInterfaceTest: record<testId: string, virtualInterfaceId: string, bgpPeers: list<string>, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>>"
    stop-bgp-failover-test: "record<virtualInterfaceTest: record<testId: string, virtualInterfaceId: string, bgpPeers: list<string>, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>>"
    tag-resource: "record"
    untag-resource: "record"
    update-connection: "record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    update-direct-connect-gateway: "record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>"
    update-direct-connect-gateway-association: "record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>"
    update-lag: "record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>"
    update-virtual-interface-attributes: "record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-direct-connect-gateway-association-proposal" "allocate-connection-on-interconnect" "allocate-hosted-connection" "allocate-private-virtual-interface" "allocate-public-virtual-interface" "allocate-transit-virtual-interface" "associate-connection-with-lag" "associate-hosted-connection" "associate-mac-sec-key" "associate-virtual-interface" "confirm-connection" "confirm-customer-agreement" "confirm-private-virtual-interface" "confirm-public-virtual-interface" "confirm-transit-virtual-interface" "create-bgp-peer" "create-connection" "create-direct-connect-gateway" "create-direct-connect-gateway-association" "create-direct-connect-gateway-association-proposal" "create-interconnect" "create-lag" "create-private-virtual-interface" "create-public-virtual-interface" "create-transit-virtual-interface" "delete-bgp-peer" "delete-connection" "delete-direct-connect-gateway" "delete-direct-connect-gateway-association" "delete-direct-connect-gateway-association-proposal" "delete-interconnect" "delete-lag" "delete-virtual-interface" "describe-connection-loa" "describe-connections" "describe-connections-on-interconnect" "describe-customer-metadata" "describe-direct-connect-gateway-association-proposals" "describe-direct-connect-gateway-associations" "describe-direct-connect-gateway-attachments" "describe-direct-connect-gateways" "describe-hosted-connections" "describe-interconnect-loa" "describe-interconnects" "describe-lags" "describe-loa" "describe-locations" "describe-router-configuration" "describe-tags" "describe-virtual-gateways" "describe-virtual-interfaces" "disassociate-connection-from-lag" "disassociate-mac-sec-key" "list-virtual-interface-test-history" "start-bgp-failover-test" "stop-bgp-failover-test" "tag-resource" "untag-resource" "update-connection" "update-direct-connect-gateway" "update-direct-connect-gateway-association" "update-lag" "update-virtual-interface-attributes" "commands"] | sort) } | get name | first)
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

# Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
#
# POST /
# Returns: record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>
# operationId: AcceptDirectConnectGatewayAssociationProposal
export def "accept-direct-connect-gateway-association-proposal" [
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
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway.
  proposal_id: string # The ID of the request proposal.
  associated_gateway_owner_account: string # The ID of the Amazon Web Services account that owns the virtual private gateway or transit gateway.
  --override-allowed-prefixes-to-direct-connect-gateway: list # Overrides the Amazon VPC prefixes advertised to the Direct Connect gateway. For information about how to set the prefixes, see Allowed Prefixes (https://docs.aws.amazon.com/directconnect/latest/UserGuide/multi-account-associate-vgw.html#allowed-prefixes) in the Direct Connect User Guide. — item shape: {cidr?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AcceptDirectConnectGatewayAssociationProposal"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: proposalId, var: proposal_id}, {name: associatedGatewayOwnerAccount, var: associated_gateway_owner_account}, {name: overrideAllowedPrefixesToDirectConnectGateway, var: override_allowed_prefixes_to_direct_connect_gateway}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, proposal_id: $proposal_id, associated_gateway_owner_account: $associated_gateway_owner_account, override_allowed_prefixes_to_direct_connect_gateway: $override_allowed_prefixes_to_direct_connect_gateway
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Use AllocateHostedConnection instead. Creates a hosted connection on an interconnect. Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect. Intended for use by Direct Connect Partners only.
#
# POST /
# DEPRECATED
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: AllocateConnectionOnInterconnect
@deprecated
export def "allocate-connection-on-interconnect" [
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
  bandwidth: string # The bandwidth of the connection. The possible values are 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, and 10Gbps. Note that only those Direct Connect Partners who have met specific requirements are allowed to create a 1Gbps, 2Gbps, 5Gbps or 10Gbps hosted connection.
  connection_name: string # The name of the provisioned connection.
  owner_account: string # The ID of the Amazon Web Services account of the customer for whom the connection will be provisioned.
  interconnect_id: string # The ID of the interconnect on which the connection will be provisioned.
  vlan: int # The dedicated VLAN provisioned to the connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AllocateConnectionOnInterconnect"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bandwidth, var: bandwidth}, {name: connectionName, var: connection_name}, {name: ownerAccount, var: owner_account}, {name: interconnectId, var: interconnect_id}, {name: vlan, var: vlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bandwidth: $bandwidth, connection_name: $connection_name, owner_account: $owner_account, interconnect_id: $interconnect_id, vlan: $vlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects. Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. Amazon Web Services polices the hosted connection for the specified capacity and the Direct Connect Partner must also police the hosted connection for the specified capacity. Intended for use by Direct Connect Partners only.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: AllocateHostedConnection
export def "allocate-hosted-connection" [
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
  connection_id: string # The ID of the interconnect or LAG.
  owner_account: string # The ID of the Amazon Web Services account ID of the customer for the connection.
  bandwidth: string # The bandwidth of the connection. The possible values are 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, and 10Gbps. Note that only those Direct Connect Partners who have met specific requirements are allowed to create a 1Gbps, 2Gbps, 5Gbps or 10Gbps hosted connection.
  connection_name: string # The name of the hosted connection.
  vlan: int # The dedicated VLAN provisioned to the hosted connection.
  --tags: list # The tags associated with the connection. — item shape: {key: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AllocateHostedConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: ownerAccount, var: owner_account}, {name: bandwidth, var: bandwidth}, {name: connectionName, var: connection_name}, {name: vlan, var: vlan}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, owner_account: $owner_account, bandwidth: $bandwidth, connection_name: $connection_name, vlan: $vlan, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a private virtual interface to be owned by the specified Amazon Web Services account. Virtual interfaces created using this action must be confirmed by the owner using ConfirmPrivateVirtualInterface. Until then, the virtual interface is in the Confirming state and is not available to handle traffic.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: AllocatePrivateVirtualInterface
export def "allocate-private-virtual-interface" [
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
  connection_id: string # The ID of the connection on which the private virtual interface is provisioned.
  owner_account: string # The ID of the Amazon Web Services account that owns the virtual private interface.
  new_private_virtual_interface_allocation: record # Information about a private virtual interface to be provisioned on a connection. — shape: {virtualInterfaceName: string, vlan: int, asn: int, mtu?: int, authKey?: string, amazonAddress?: string, addressFamily?: "ipv4"|"ipv6", customerAddress?: string, tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AllocatePrivateVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: ownerAccount, var: owner_account}, {name: newPrivateVirtualInterfaceAllocation, var: new_private_virtual_interface_allocation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, owner_account: $owner_account, new_private_virtual_interface_allocation: $new_private_virtual_interface_allocation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a public virtual interface to be owned by the specified Amazon Web Services account. The owner of a connection calls this function to provision a public virtual interface to be owned by the specified Amazon Web Services account. Virtual interfaces created using this function must be confirmed by the owner using ConfirmPublicVirtualInterface. Until this step has been completed, the virtual interface is in the confirming state and is not available to handle traffic. When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: AllocatePublicVirtualInterface
export def "allocate-public-virtual-interface" [
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
  connection_id: string # The ID of the connection on which the public virtual interface is provisioned.
  owner_account: string # The ID of the Amazon Web Services account that owns the public virtual interface.
  new_public_virtual_interface_allocation: record # Information about a public virtual interface to be provisioned on a connection. — shape: {virtualInterfaceName: string, vlan: int, asn: int, authKey?: string, amazonAddress?: string, customerAddress?: string, addressFamily?: "ipv4"|"ipv6", routeFilterPrefixes?: list, tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AllocatePublicVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: ownerAccount, var: owner_account}, {name: newPublicVirtualInterfaceAllocation, var: new_public_virtual_interface_allocation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, owner_account: $owner_account, new_public_virtual_interface_allocation: $new_public_virtual_interface_allocation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a transit virtual interface to be owned by the specified Amazon Web Services account. Use this type of interface to connect a transit gateway to your Direct Connect gateway. The owner of a connection provisions a transit virtual interface to be owned by the specified Amazon Web Services account. After you create a transit virtual interface, it must be confirmed by the owner using ConfirmTransitVirtualInterface. Until this step has been completed, the transit virtual interface is in the requested state and is not available to handle traffic.
#
# POST /
# Returns: record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>
# operationId: AllocateTransitVirtualInterface
export def "allocate-transit-virtual-interface" [
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
  connection_id: string # The ID of the connection on which the transit virtual interface is provisioned.
  owner_account: string # The ID of the Amazon Web Services account that owns the transit virtual interface.
  new_transit_virtual_interface_allocation: record # Information about a transit virtual interface to be provisioned on a connection. — shape: {virtualInterfaceName?: string, vlan?: int, asn?: int, mtu?: int, authKey?: string, amazonAddress?: string, customerAddress?: string, addressFamily?: "ipv4"|"ipv6", tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AllocateTransitVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: ownerAccount, var: owner_account}, {name: newTransitVirtualInterfaceAllocation, var: new_transit_virtual_interface_allocation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, owner_account: $owner_account, new_transit_virtual_interface_allocation: $new_transit_virtual_interface_allocation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to Amazon Web Services is interrupted). The connection must be hosted on the same Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails. Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG. For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: AssociateConnectionWithLag
export def "associate-connection-with-lag" [
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
  connection_id: string # The ID of the connection.
  lag_id: string # The ID of the LAG with which to associate the connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AssociateConnectionWithLag"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: lagId, var: lag_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, lag_id: $lag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to Amazon Web Services as it is being migrated. Intended for use by Direct Connect Partners only.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: AssociateHostedConnection
export def "associate-hosted-connection" [
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
  connection_id: string # The ID of the hosted connection.
  parent_connection_id: string # The ID of the interconnect or the LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AssociateHostedConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: parentConnectionId, var: parent_connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, parent_connection_id: $parent_connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a MAC Security (MACsec) Connection Key Name (CKN)/ Connectivity Association Key (CAK) pair with an Direct Connect dedicated connection. You must supply either the secretARN, or the CKN/CAK (ckn and cak) pair in the request. For information about MAC Security (MACsec) key considerations, see MACsec pre-shared CKN/CAK key considerations (https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-mac-sec-getting-started.html#mac-sec-key-consideration) in the Direct Connect User Guide.
#
# POST /
# Returns: record<connectionId: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: AssociateMacSecKey
export def "associate-mac-sec-key" [
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
  connection_id: string # The ID of the dedicated connection (dxcon-xxxx), or the ID of the LAG (dxlag-xxxx). You can use DescribeConnections or DescribeLags to retrieve connection ID.
  --secret-arn: string # The Amazon Resource Name (ARN) of the MAC Security (MACsec) secret key to associate with the dedicated connection. You can use DescribeConnections or DescribeLags to retrieve the MAC Security (MACsec) secret key. If you use this request parameter, you do not use the ckn and cak request parameters.
  --ckn: string # The MAC Security (MACsec) CKN to associate with the dedicated connection. You can create the CKN/CAK pair using an industry standard tool. The valid values are 64 hexadecimal characters (0-9, A-E). If you use this request parameter, you must use the cak request parameter and not use the secretARN request parameter.
  --cak: string # The MAC Security (MACsec) CAK to associate with the dedicated connection. You can create the CKN/CAK pair using an industry standard tool. The valid values are 64 hexadecimal characters (0-9, A-E). If you use this request parameter, you must use the ckn request parameter and not use the secretARN request parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AssociateMacSecKey"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: secretARN, var: secret_arn}, {name: ckn, var: ckn}, {name: cak, var: cak}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, secret_arn: $secret_arn, ckn: $ckn, cak: $cak
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to Amazon Web Services is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails. Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using AssociateHostedConnection. To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: AssociateVirtualInterface
export def "associate-virtual-interface" [
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
  virtual_interface_id: string # The ID of the virtual interface.
  connection_id: string # The ID of the LAG or connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.AssociateVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms the creation of the specified hosted connection on an interconnect. Upon creation, the hosted connection is initially in the Ordering state, and remains in this state until the owner confirms creation of the hosted connection.
#
# POST /
# Returns: record<connectionState: string>
# operationId: ConfirmConnection
export def "confirm-connection" [
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
  connection_id: string # The ID of the hosted connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ConfirmConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The confirmation of the terms of agreement when creating the connection/link aggregation group (LAG).
#
# POST /
# Returns: record<status: string>
# operationId: ConfirmCustomerAgreement
export def "confirm-customer-agreement" [
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
  --agreement-name: string # The name of the customer agreement.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ConfirmCustomerAgreement"}]
    body: {content_type: "application/json", kind: json, fields: [{name: agreementName, var: agreement_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, agreement_name: $agreement_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts ownership of a private virtual interface created by another Amazon Web Services account. After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.
#
# POST /
# Returns: record<virtualInterfaceState: string>
# operationId: ConfirmPrivateVirtualInterface
export def "confirm-private-virtual-interface" [
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
  virtual_interface_id: string # The ID of the virtual interface.
  --virtual-gateway-id: string # The ID of the virtual private gateway.
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ConfirmPrivateVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: virtualGatewayId, var: virtual_gateway_id}, {name: directConnectGatewayId, var: direct_connect_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, virtual_gateway_id: $virtual_gateway_id, direct_connect_gateway_id: $direct_connect_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts ownership of a public virtual interface created by another Amazon Web Services account. After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.
#
# POST /
# Returns: record<virtualInterfaceState: string>
# operationId: ConfirmPublicVirtualInterface
export def "confirm-public-virtual-interface" [
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
  virtual_interface_id: string # The ID of the virtual interface.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ConfirmPublicVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts ownership of a transit virtual interface created by another Amazon Web Services account. After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.
#
# POST /
# Returns: record<virtualInterfaceState: string>
# operationId: ConfirmTransitVirtualInterface
export def "confirm-transit-virtual-interface" [
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
  virtual_interface_id: string # The ID of the virtual interface.
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ConfirmTransitVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: directConnectGatewayId, var: direct_connect_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, direct_connect_gateway_id: $direct_connect_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a BGP peer on the specified virtual interface. You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access Amazon Web Services resources that also use that address family. If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface. When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses. If you let Amazon Web Services auto-assign IPv4 addresses, a /30 CIDR will be allocated from 169.254.0.0/16. Amazon Web Services does not recommend this option if you intend to use the customer router peer IP address as the source and destination for traffic. Instead you should use RFC 1918 or other addressing, and specify the address yourself. For more information about RFC 1918 see Address Allocation for Private Internets (https://datatracker.ietf.org/doc/html/rfc1918). For a public virtual interface, the Autonomous System Number (ASN) must be private or already on the allow list for the virtual interface.
#
# POST /
# Returns: record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>
# operationId: CreateBGPPeer
export def "create-bgp-peer" [
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
  --virtual-interface-id: string # The ID of the virtual interface.
  --new-bgp-peer: record # Information about a new BGP peer. — shape: {asn?: int, authKey?: string, addressFamily?: "ipv4"|"ipv6", amazonAddress?: string, customerAddress?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateBGPPeer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: newBGPPeer, var: new_bgp_peer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, new_bgp_peer: $new_bgp_peer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connection between a customer network and a specific Direct Connect location. A connection links your internal network to an Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an Direct Connect router. To find the locations for your Region, use DescribeLocations. You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: CreateConnection
export def "create-connection" [
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
  location: string # The location of the connection.
  bandwidth: string # The bandwidth of the connection.
  connection_name: string # The name of the connection.
  --lag-id: string # The ID of the LAG.
  --tags: list # The tags to associate with the lag. — item shape: {key: string, value?: string}
  --provider-name: string # The name of the service provider associated with the requested connection.
  --request-mac-sec: oneof<nothing, bool> # Indicates whether you want the connection to support MAC Security (MACsec). MAC Security (MACsec) is only available on dedicated connections. For information about MAC Security (MACsec) prerequisties, see MACsec prerequisties (https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-mac-sec-getting-started.html#mac-sec-prerequisites) in the Direct Connect User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: bandwidth, var: bandwidth}, {name: connectionName, var: connection_name}, {name: lagId, var: lag_id}, {name: tags, var: tags}, {name: providerName, var: provider_name}, {name: requestMACSec, var: request_mac_sec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, location: $location, bandwidth: $bandwidth, connection_name: $connection_name, lag_id: $lag_id, tags: $tags, provider_name: $provider_name, request_mac_sec: $request_mac_sec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any Amazon Web Services Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different Amazon Web Services Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
#
# POST /
# Returns: record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>
# operationId: CreateDirectConnectGateway
export def "create-direct-connect-gateway" [
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
  direct_connect_gateway_name: string # The name of the Direct Connect gateway.
  --amazon-side-asn: int # The autonomous system number (ASN) for Border Gateway Protocol (BGP) to be configured on the Amazon side of the connection. The ASN must be in the private range of 64,512 to 65,534 or 4,200,000,000 to 4,294,967,294. The default is 64512.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateDirectConnectGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayName, var: direct_connect_gateway_name}, {name: amazonSideAsn, var: amazon_side_asn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_name: $direct_connect_gateway_name, amazon_side_asn: $amazon_side_asn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
#
# POST /
# Returns: record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>
# operationId: CreateDirectConnectGatewayAssociation
export def "create-direct-connect-gateway-association" [
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
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway.
  --gateway-id: string # The ID of the virtual private gateway or transit gateway.
  --add-allowed-prefixes-to-direct-connect-gateway: list # The Amazon VPC prefixes to advertise to the Direct Connect gateway This parameter is required when you create an association to a transit gateway. For information about how to set the prefixes, see Allowed Prefixes (https://docs.aws.amazon.com/directconnect/latest/UserGuide/multi-account-associate-vgw.html#allowed-prefixes) in the Direct Connect User Guide. — item shape: {cidr?: string}
  --virtual-gateway-id: string # The ID of the virtual private gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateDirectConnectGatewayAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: gatewayId, var: gateway_id}, {name: addAllowedPrefixesToDirectConnectGateway, var: add_allowed_prefixes_to_direct_connect_gateway}, {name: virtualGatewayId, var: virtual_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, gateway_id: $gateway_id, add_allowed_prefixes_to_direct_connect_gateway: $add_allowed_prefixes_to_direct_connect_gateway, virtual_gateway_id: $virtual_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway. You can associate a Direct Connect gateway and virtual private gateway or transit gateway that is owned by any Amazon Web Services account.
#
# POST /
# Returns: record<directConnectGatewayAssociationProposal: record<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, existingAllowedPrefixesToDirectConnectGateway: list<record>, requestedAllowedPrefixesToDirectConnectGateway: list<record>>>
# operationId: CreateDirectConnectGatewayAssociationProposal
export def "create-direct-connect-gateway-association-proposal" [
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
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway.
  direct_connect_gateway_owner_account: string # The ID of the Amazon Web Services account that owns the Direct Connect gateway.
  gateway_id: string # The ID of the virtual private gateway or transit gateway.
  --add-allowed-prefixes-to-direct-connect-gateway: list # The Amazon VPC prefixes to advertise to the Direct Connect gateway. — item shape: {cidr?: string}
  --remove-allowed-prefixes-to-direct-connect-gateway: list # The Amazon VPC prefixes to no longer advertise to the Direct Connect gateway. — item shape: {cidr?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateDirectConnectGatewayAssociationProposal"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: directConnectGatewayOwnerAccount, var: direct_connect_gateway_owner_account}, {name: gatewayId, var: gateway_id}, {name: addAllowedPrefixesToDirectConnectGateway, var: add_allowed_prefixes_to_direct_connect_gateway}, {name: removeAllowedPrefixesToDirectConnectGateway, var: remove_allowed_prefixes_to_direct_connect_gateway}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, direct_connect_gateway_owner_account: $direct_connect_gateway_owner_account, gateway_id: $gateway_id, add_allowed_prefixes_to_direct_connect_gateway: $add_allowed_prefixes_to_direct_connect_gateway, remove_allowed_prefixes_to_direct_connect_gateway: $remove_allowed_prefixes_to_direct_connect_gateway
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an interconnect between an Direct Connect Partner's network and a specific Direct Connect location. An interconnect is a connection that is capable of hosting other connections. The Direct Connect Partner can use an interconnect to provide Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an Direct Connect router. You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created. For each end customer, the Direct Connect Partner provisions a connection on their interconnect by calling AllocateHostedConnection. The end customer can then connect to Amazon Web Services resources by creating a virtual interface on their connection, using the VLAN assigned to them by the Direct Connect Partner. Intended for use by Direct Connect Partners only.
#
# POST /
# Returns: record<interconnectId: string, interconnectName: string, interconnectState: string, region: string, location: string, bandwidth: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string>
# operationId: CreateInterconnect
export def "create-interconnect" [
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
  interconnect_name: string # The name of the interconnect.
  bandwidth: string # The port bandwidth, in Gbps. The possible values are 1 and 10.
  location: string # The location of the interconnect.
  --lag-id: string # The ID of the LAG.
  --tags: list # The tags to associate with the interconnect. — item shape: {key: string, value?: string}
  --provider-name: string # The name of the service provider associated with the interconnect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateInterconnect"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interconnectName, var: interconnect_name}, {name: bandwidth, var: bandwidth}, {name: location, var: location}, {name: lagId, var: lag_id}, {name: tags, var: tags}, {name: providerName, var: provider_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, interconnect_name: $interconnect_name, bandwidth: $bandwidth, location: $location, lag_id: $lag_id, tags: $tags, provider_name: $provider_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a link aggregation group (LAG) with the specified number of bundled physical dedicated connections between the customer network and a specific Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface. All connections in a LAG must use the same bandwidth (either 1Gbps or 10Gbps) and must terminate at the same Direct Connect endpoint. You can have up to 10 dedicated connections per LAG. Regardless of this limit, if you request more connections for the LAG than Direct Connect can allocate on a single endpoint, no LAG is created. You can specify an existing physical dedicated connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical dedicated connection, and re-establishes them as a member of the LAG. The LAG will be created on the same Direct Connect endpoint to which the dedicated connection terminates. Any virtual interfaces associated with the dedicated connection are automatically disassociated and re-associated with the LAG. The connection ID does not change. If the Amazon Web Services account used to create a LAG is a registered Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.
#
# POST /
# Returns: record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: CreateLag
export def "create-lag" [
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
  number_of_connections: int # The number of physical dedicated connections initially provisioned and bundled by the LAG.
  location: string # The location for the LAG.
  connections_bandwidth: string # The bandwidth of the individual physical dedicated connections bundled by the LAG. The possible values are 1Gbps and 10Gbps.
  lag_name: string # The name of the LAG.
  --connection-id: string # The ID of an existing dedicated connection to migrate to the LAG.
  --tags: list # The tags to associate with the LAG. — item shape: {key: string, value?: string}
  --child-connection-tags: list # The tags to associate with the automtically created LAGs. — item shape: {key: string, value?: string}
  --provider-name: string # The name of the service provider associated with the LAG.
  --request-mac-sec: oneof<nothing, bool> # Indicates whether the connection will support MAC Security (MACsec). All connections in the LAG must be capable of supporting MAC Security (MACsec). For information about MAC Security (MACsec) prerequisties, see MACsec prerequisties (https://docs.aws.amazon.com/directconnect/latest/UserGuide/direct-connect-mac-sec-getting-started.html#mac-sec-prerequisites) in the Direct Connect User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateLag"}]
    body: {content_type: "application/json", kind: json, fields: [{name: numberOfConnections, var: number_of_connections}, {name: location, var: location}, {name: connectionsBandwidth, var: connections_bandwidth}, {name: lagName, var: lag_name}, {name: connectionId, var: connection_id}, {name: tags, var: tags}, {name: childConnectionTags, var: child_connection_tags}, {name: providerName, var: provider_name}, {name: requestMACSec, var: request_mac_sec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, number_of_connections: $number_of_connections, location: $location, connections_bandwidth: $connections_bandwidth, lag_name: $lag_name, connection_id: $connection_id, tags: $tags, child_connection_tags: $child_connection_tags, provider_name: $provider_name, request_mac_sec: $request_mac_sec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a private virtual interface. A virtual interface is the VLAN that transports Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different Amazon Web Services Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region. Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call DescribeConnections. To check whether your virtual interface supports jumbo frames, call DescribeVirtualInterfaces.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: CreatePrivateVirtualInterface
export def "create-private-virtual-interface" [
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
  connection_id: string # The ID of the connection.
  new_private_virtual_interface: record # Information about a private virtual interface. — shape: {virtualInterfaceName: string, vlan: int, asn: int, mtu?: int, authKey?: string, amazonAddress?: string, customerAddress?: string, addressFamily?: "ipv4"|"ipv6", virtualGatewayId?: string, directConnectGatewayId?: string, tags?: list, enableSiteLink?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreatePrivateVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: newPrivateVirtualInterface, var: new_private_virtual_interface}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, new_private_virtual_interface: $new_private_virtual_interface
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a public virtual interface. A virtual interface is the VLAN that transports Direct Connect traffic. A public virtual interface supports sending traffic to public services of Amazon Web Services such as Amazon S3. When creating an IPv6 public virtual interface (addressFamily is ipv6), leave the customer and amazon address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: CreatePublicVirtualInterface
export def "create-public-virtual-interface" [
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
  connection_id: string # The ID of the connection.
  new_public_virtual_interface: record # Information about a public virtual interface. — shape: {virtualInterfaceName: string, vlan: int, asn: int, authKey?: string, amazonAddress?: string, customerAddress?: string, addressFamily?: "ipv4"|"ipv6", routeFilterPrefixes?: list, tags?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreatePublicVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: newPublicVirtualInterface, var: new_public_virtual_interface}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, new_public_virtual_interface: $new_public_virtual_interface
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway. If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails. A jumbo MTU value must be either 1500 or 8500. No other values will be accepted. Setting the MTU of a virtual interface to 8500 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call DescribeConnections. To check whether your virtual interface supports jumbo frames, call DescribeVirtualInterfaces.
#
# POST /
# Returns: record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>
# operationId: CreateTransitVirtualInterface
export def "create-transit-virtual-interface" [
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
  connection_id: string # The ID of the connection.
  new_transit_virtual_interface: record # Information about a transit virtual interface. — shape: {virtualInterfaceName?: string, vlan?: int, asn?: int, mtu?: int, authKey?: string, amazonAddress?: string, customerAddress?: string, addressFamily?: "ipv4"|"ipv6", directConnectGatewayId?: string, tags?: list, enableSiteLink?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.CreateTransitVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: newTransitVirtualInterface, var: new_transit_virtual_interface}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, new_transit_virtual_interface: $new_transit_virtual_interface
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN. You cannot delete the last BGP peer from a virtual interface.
#
# POST /
# Returns: record<virtualInterface: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list<record>, bgpPeers: list<record>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list<record>, siteLinkEnabled: bool>>
# operationId: DeleteBGPPeer
export def "delete-bgp-peer" [
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
  --virtual-interface-id: string # The ID of the virtual interface.
  --asn: int # The autonomous system (AS) number for Border Gateway Protocol (BGP) configuration.
  --customer-address: string # The IP address assigned to the customer interface.
  --bgp-peer-id: string # The ID of the BGP peer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteBGPPeer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: asn, var: asn}, {name: customerAddress, var: customer_address}, {name: bgpPeerId, var: bgp_peer_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, asn: $asn, customer_address: $customer_address, bgp_peer_id: $bgp_peer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified connection. Deleting a connection only stops the Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the Direct Connect location, you must cancel your service with them separately.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: DeleteConnection
export def "delete-connection" [
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
  connection_id: string # The ID of the connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
#
# POST /
# Returns: record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>
# operationId: DeleteDirectConnectGateway
export def "delete-direct-connect-gateway" [
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
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteDirectConnectGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the association between the specified Direct Connect gateway and virtual private gateway. We recommend that you specify the associationID to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the virtualGatewayId and directConnectGatewayId to delete an association.
#
# POST /
# Returns: record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>
# operationId: DeleteDirectConnectGatewayAssociation
export def "delete-direct-connect-gateway-association" [
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
  --association-id: string # The ID of the Direct Connect gateway association.
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
  --virtual-gateway-id: string # The ID of the virtual private gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteDirectConnectGatewayAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: associationId, var: association_id}, {name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: virtualGatewayId, var: virtual_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, direct_connect_gateway_id: $direct_connect_gateway_id, virtual_gateway_id: $virtual_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
#
# POST /
# Returns: record<directConnectGatewayAssociationProposal: record<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, existingAllowedPrefixesToDirectConnectGateway: list<record>, requestedAllowedPrefixesToDirectConnectGateway: list<record>>>
# operationId: DeleteDirectConnectGatewayAssociationProposal
export def "delete-direct-connect-gateway-association-proposal" [
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
  proposal_id: string # The ID of the proposal.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteDirectConnectGatewayAssociationProposal"}]
    body: {content_type: "application/json", kind: json, fields: [{name: proposalId, var: proposal_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, proposal_id: $proposal_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified interconnect. Intended for use by Direct Connect Partners only.
#
# POST /
# Returns: record<interconnectState: string>
# operationId: DeleteInterconnect
export def "delete-interconnect" [
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
  interconnect_id: string # The ID of the interconnect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteInterconnect"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interconnectId, var: interconnect_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, interconnect_id: $interconnect_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
#
# POST /
# Returns: record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: DeleteLag
export def "delete-lag" [
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
  lag_id: string # The ID of the LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteLag"}]
    body: {content_type: "application/json", kind: json, fields: [{name: lagId, var: lag_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, lag_id: $lag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a virtual interface.
#
# POST /
# Returns: record<virtualInterfaceState: string>
# operationId: DeleteVirtualInterface
export def "delete-virtual-interface" [
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
  virtual_interface_id: string # The ID of the virtual interface.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DeleteVirtualInterface"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Use DescribeLoa instead. Gets the LOA-CFA for a connection. The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to Amazon Web Services at the colocation facility. For more information, see Requesting Cross Connects at Direct Connect Locations (https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html) in the Direct Connect User Guide.
#
# POST /
# DEPRECATED
# Returns: record<loa: record<loaContent: string, loaContentType: string>>
# operationId: DescribeConnectionLoa
@deprecated
export def "describe-connection-loa" [
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
  connection_id: string # The ID of the connection.
  --provider-name: string # The name of the APN partner or service provider who establishes connectivity on your behalf. If you specify this parameter, the LOA-CFA lists the provider name alongside your company name as the requester of the cross connect.
  --loa-content-type: string@loa-content-type-completer # The standard media type for the LOA-CFA document. The only supported value is application/pdf.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeConnectionLoa"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: providerName, var: provider_name}, {name: loaContentType, var: loa_content_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, provider_name: $provider_name, loa_content_type: $loa_content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the specified connection or all connections in this Region.
#
# POST /
# Returns: record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>
# operationId: DescribeConnections
export def "describe-connections" [
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
  --connection-id: string # The ID of the connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Use DescribeHostedConnections instead. Lists the connections that have been provisioned on the specified interconnect. Intended for use by Direct Connect Partners only.
#
# POST /
# DEPRECATED
# Returns: record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>
# operationId: DescribeConnectionsOnInterconnect
@deprecated
export def "describe-connections-on-interconnect" [
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
  interconnect_id: string # The ID of the interconnect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeConnectionsOnInterconnect"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interconnectId, var: interconnect_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, interconnect_id: $interconnect_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get and view a list of customer agreements, along with their signed status and whether the customer is an NNIPartner, NNIPartnerV2, or a nonPartner.
#
# POST /
# Returns: record<agreements: table<agreementName: string, status: string>, nniPartnerType: string>
# operationId: DescribeCustomerMetadata
export def "describe-customer-metadata" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeCustomerMetadata"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway.
#
# POST /
# Returns: record<directConnectGatewayAssociationProposals: table<proposalId: string, directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, proposalState: string, associatedGateway: record, existingAllowedPrefixesToDirectConnectGateway: list, requestedAllowedPrefixesToDirectConnectGateway: list>, nextToken: string>
# operationId: DescribeDirectConnectGatewayAssociationProposals
export def "describe-direct-connect-gateway-association-proposals" [
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
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
  --proposal-id: string # The ID of the proposal.
  --associated-gateway-id: string # The ID of the associated gateway.
  --max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. If MaxResults is given a value larger than 100, only 100 results are returned.
  --next-token: string # The token for the next page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeDirectConnectGatewayAssociationProposals"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: proposalId, var: proposal_id}, {name: associatedGatewayId, var: associated_gateway_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, proposal_id: $proposal_id, associated_gateway_id: $associated_gateway_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the associations between your Direct Connect gateways and virtual private gateways and transit gateways. You must specify one of the following: A Direct Connect gateway The response contains all virtual private gateways and transit gateways associated with the Direct Connect gateway. A virtual private gateway The response contains the Direct Connect gateway. A transit gateway The response contains the Direct Connect gateway. A Direct Connect gateway and a virtual private gateway The response contains the association between the Direct Connect gateway and virtual private gateway. A Direct Connect gateway and a transit gateway The response contains the association between the Direct Connect gateway and transit gateway.
#
# POST /
# Returns: record<directConnectGatewayAssociations: table<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record, associationId: string, allowedPrefixesToDirectConnectGateway: list, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>, nextToken: string>
# operationId: DescribeDirectConnectGatewayAssociations
export def "describe-direct-connect-gateway-associations" [
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
  --association-id: string # The ID of the Direct Connect gateway association.
  --associated-gateway-id: string # The ID of the associated gateway.
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
  --max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. If MaxResults is given a value larger than 100, only 100 results are returned.
  --next-token: string # The token provided in the previous call to retrieve the next page.
  --virtual-gateway-id: string # The ID of the virtual private gateway or transit gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeDirectConnectGatewayAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: associationId, var: association_id}, {name: associatedGatewayId, var: associated_gateway_id}, {name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: virtualGatewayId, var: virtual_gateway_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, associated_gateway_id: $associated_gateway_id, direct_connect_gateway_id: $direct_connect_gateway_id, max_results: $max_results, next_token: $next_token, virtual_gateway_id: $virtual_gateway_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
#
# POST /
# Returns: record<directConnectGatewayAttachments: table<directConnectGatewayId: string, virtualInterfaceId: string, virtualInterfaceRegion: string, virtualInterfaceOwnerAccount: string, attachmentState: string, attachmentType: string, stateChangeError: string>, nextToken: string>
# operationId: DescribeDirectConnectGatewayAttachments
export def "describe-direct-connect-gateway-attachments" [
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
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
  --virtual-interface-id: string # The ID of the virtual interface.
  --max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. If MaxResults is given a value larger than 100, only 100 results are returned.
  --next-token: string # The token provided in the previous call to retrieve the next page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeDirectConnectGatewayAttachments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: virtualInterfaceId, var: virtual_interface_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, virtual_interface_id: $virtual_interface_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
#
# POST /
# Returns: record<directConnectGateways: table<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>, nextToken: string>
# operationId: DescribeDirectConnectGateways
export def "describe-direct-connect-gateways" [
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
  --direct-connect-gateway-id: string # The ID of the Direct Connect gateway.
  --max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. If MaxResults is given a value larger than 100, only 100 results are returned.
  --next-token: string # The token provided in the previous call to retrieve the next page.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeDirectConnectGateways"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG). Intended for use by Direct Connect Partners only.
#
# POST /
# Returns: record<connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>>
# operationId: DescribeHostedConnections
export def "describe-hosted-connections" [
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
  connection_id: string # The ID of the interconnect or LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeHostedConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Use DescribeLoa instead. Gets the LOA-CFA for the specified interconnect. The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to Amazon Web Services at the colocation facility. For more information, see Requesting Cross Connects at Direct Connect Locations (https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html) in the Direct Connect User Guide.
#
# POST /
# DEPRECATED
# Returns: record<loa: record<loaContent: string, loaContentType: string>>
# operationId: DescribeInterconnectLoa
@deprecated
export def "describe-interconnect-loa" [
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
  interconnect_id: string # The ID of the interconnect.
  --provider-name: string # The name of the service provider who establishes connectivity on your behalf. If you supply this parameter, the LOA-CFA lists the provider name alongside your company name as the requester of the cross connect.
  --loa-content-type: string@loa-content-type-completer # The standard media type for the LOA-CFA document. The only supported value is application/pdf.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeInterconnectLoa"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interconnectId, var: interconnect_id}, {name: providerName, var: provider_name}, {name: loaContentType, var: loa_content_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, interconnect_id: $interconnect_id, provider_name: $provider_name, loa_content_type: $loa_content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the interconnects owned by the Amazon Web Services account or only the specified interconnect.
#
# POST /
# Returns: record<interconnects: table<interconnectId: string, interconnectName: string, interconnectState: string, region: string, location: string, bandwidth: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string>>
# operationId: DescribeInterconnects
export def "describe-interconnects" [
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
  --interconnect-id: string # The ID of the interconnect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeInterconnects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: interconnectId, var: interconnect_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, interconnect_id: $interconnect_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes all your link aggregation groups (LAG) or the specified LAG.
#
# POST /
# Returns: record<lags: table<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: list, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: list>>
# operationId: DescribeLags
export def "describe-lags" [
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
  --lag-id: string # The ID of the LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeLags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: lagId, var: lag_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, lag_id: $lag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG). The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to Amazon Web Services at the colocation facility. For more information, see Requesting Cross Connects at Direct Connect Locations (https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html) in the Direct Connect User Guide.
#
# POST /
# Returns: record<loaContent: string, loaContentType: string>
# operationId: DescribeLoa
export def "describe-loa" [
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
  connection_id: string # The ID of a connection, LAG, or interconnect.
  --provider-name: string # The name of the service provider who establishes connectivity on your behalf. If you specify this parameter, the LOA-CFA lists the provider name alongside your company name as the requester of the cross connect.
  --loa-content-type: string@loa-content-type-completer # The standard media type for the LOA-CFA document. The only supported value is application/pdf.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeLoa"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: providerName, var: provider_name}, {name: loaContentType, var: loa_content_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, provider_name: $provider_name, loa_content_type: $loa_content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Direct Connect locations in the current Amazon Web Services Region. These are the locations that can be selected when calling CreateConnection or CreateInterconnect.
#
# POST /
# Returns: record<locations: table<locationCode: string, locationName: string, region: string, availablePortSpeeds: list, availableProviders: list, availableMacSecPortSpeeds: list>>
# operationId: DescribeLocations
export def "describe-locations" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeLocations"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details about the router.
#
# POST /
# Returns: record<customerRouterConfig: string, router: record<vendor: string, platform: string, software: string, xsltTemplateName: string, xsltTemplateNameForMacSec: string, routerTypeIdentifier: string>, virtualInterfaceId: string, virtualInterfaceName: string>
# operationId: DescribeRouterConfiguration
export def "describe-router-configuration" [
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
  virtual_interface_id: string # The ID of the virtual interface.
  --router-type-identifier: string # Identifies the router by a combination of vendor, platform, and software version. For example, CiscoSystemsInc-2900SeriesRouters-IOS124.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeRouterConfiguration"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: routerTypeIdentifier, var: router_type_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, router_type_identifier: $router_type_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the tags associated with the specified Direct Connect resources.
#
# POST /
# Returns: record<resourceTags: table<resourceArn: string, tags: list>>
# operationId: DescribeTags
export def "describe-tags" [
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
  resource_arns: list<string> # The Amazon Resource Names (ARNs) of the resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArns, var: resource_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arns: $resource_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the virtual private gateways owned by the Amazon Web Services account. You can create one or more Direct Connect private virtual interfaces linked to a virtual private gateway.
#
# POST /
# Returns: record<virtualGateways: table<virtualGatewayId: string, virtualGatewayState: string>>
# operationId: DescribeVirtualGateways
export def "describe-virtual-gateways" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeVirtualGateways"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays all virtual interfaces for an Amazon Web Services account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned. A virtual interface (VLAN) transmits the traffic between the Direct Connect location and the customer network.
#
# POST /
# Returns: record<virtualInterfaces: table<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: list, bgpPeers: list, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: list, siteLinkEnabled: bool>>
# operationId: DescribeVirtualInterfaces
export def "describe-virtual-interfaces" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --connection-id: string # The ID of the connection.
  --virtual-interface-id: string # The ID of the virtual interface.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DescribeVirtualInterfaces"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: virtualInterfaceId, var: virtual_interface_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, virtual_interface_id: $virtual_interface_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the DeleteConnection request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an Direct Connect Partner is automatically converted to an interconnect. If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: DisassociateConnectionFromLag
export def "disassociate-connection-from-lag" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  connection_id: string # The ID of the connection.
  lag_id: string # The ID of the LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DisassociateConnectionFromLag"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: lagId, var: lag_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, lag_id: $lag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association between a MAC Security (MACsec) security key and an Direct Connect dedicated connection.
#
# POST /
# Returns: record<connectionId: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: DisassociateMacSecKey
export def "disassociate-mac-sec-key" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  connection_id: string # The ID of the dedicated connection (dxcon-xxxx), or the ID of the LAG (dxlag-xxxx). You can use DescribeConnections or DescribeLags to retrieve connection ID.
  secret_arn: string # The Amazon Resource Name (ARN) of the MAC Security (MACsec) secret key. You can use DescribeConnections to retrieve the ARN of the MAC Security (MACsec) secret key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.DisassociateMacSecKey"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: secretARN, var: secret_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, secret_arn: $secret_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the virtual interface failover test history.
#
# POST /
# Returns: record<virtualInterfaceTestHistory: table<testId: string, virtualInterfaceId: string, bgpPeers: list, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>, nextToken: string>
# operationId: ListVirtualInterfaceTestHistory
export def "list-virtual-interface-test-history" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --test-id: string # The ID of the virtual interface failover test.
  --virtual-interface-id: string # The ID of the virtual interface that was tested.
  --bgp-peers: list<string> # The BGP peers that were placed in the DOWN state during the virtual interface failover test.
  --status: string # The status of the virtual interface failover test.
  --max-results: int # The maximum number of results to return with a single call. To retrieve the remaining results, make another call with the returned nextToken value. If MaxResults is given a value larger than 100, only 100 results are returned.
  --next-token: string # The token for the next page of results.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.ListVirtualInterfaceTestHistory"}]
    body: {content_type: "application/json", kind: json, fields: [{name: testId, var: test_id}, {name: virtualInterfaceId, var: virtual_interface_id}, {name: bgpPeers, var: bgp_peers}, {name: status, var: status}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, test_id: $test_id, virtual_interface_id: $virtual_interface_id, bgp_peers: $bgp_peers, status: $status, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the virtual interface failover test that verifies your configuration meets your resiliency requirements by placing the BGP peering session in the DOWN state. You can then send traffic to verify that there are no outages. You can run the test on public, private, transit, and hosted virtual interfaces. You can use ListVirtualInterfaceTestHistory (https://docs.aws.amazon.com/directconnect/latest/APIReference/API_ListVirtualInterfaceTestHistory.html) to view the virtual interface test history. If you need to stop the test before the test interval completes, use StopBgpFailoverTest (https://docs.aws.amazon.com/directconnect/latest/APIReference/API_StopBgpFailoverTest.html).
#
# POST /
# Returns: record<virtualInterfaceTest: record<testId: string, virtualInterfaceId: string, bgpPeers: list<string>, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>>
# operationId: StartBgpFailoverTest
export def "start-bgp-failover-test" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  virtual_interface_id: string # The ID of the virtual interface you want to test.
  --bgp-peers: list<string> # The BGP peers to place in the DOWN state.
  --test-duration-in-minutes: int # The time in minutes that the virtual interface failover test will last. Maximum value: 4,320 minutes (72 hours). Default: 180 minutes (3 hours).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.StartBgpFailoverTest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: bgpPeers, var: bgp_peers}, {name: testDurationInMinutes, var: test_duration_in_minutes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, bgp_peers: $bgp_peers, test_duration_in_minutes: $test_duration_in_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the virtual interface failover test.
#
# POST /
# Returns: record<virtualInterfaceTest: record<testId: string, virtualInterfaceId: string, bgpPeers: list<string>, status: string, ownerAccount: string, testDurationInMinutes: int, startTime: string, endTime: string>>
# operationId: StopBgpFailoverTest
export def "stop-bgp-failover-test" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  virtual_interface_id: string # The ID of the virtual interface you no longer want to test.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.StopBgpFailoverTest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the specified tags to the specified Direct Connect resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tags: list # The tags to add. — item shape: {key: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from the specified Direct Connect resource.
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource.
  tag_keys: list<string> # The tag keys of the tags to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Direct Connect dedicated connection configuration. You can update the following parameters for a connection: The connection name The connection's MAC Security (MACsec) encryption mode.
#
# POST /
# Returns: record<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: UpdateConnection
export def "update-connection" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  connection_id: string # The ID of the dedicated connection. You can use DescribeConnections to retrieve the connection ID.
  --connection-name: string # The name of the connection.
  --encryption-mode: string # The connection MAC Security (MACsec) encryption mode. The valid values are no_encrypt, should_encrypt, and must_encrypt.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UpdateConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionId, var: connection_id}, {name: connectionName, var: connection_name}, {name: encryptionMode, var: encryption_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_id: $connection_id, connection_name: $connection_name, encryption_mode: $encryption_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of a current Direct Connect gateway.
#
# POST /
# Returns: record<directConnectGateway: record<directConnectGatewayId: string, directConnectGatewayName: string, amazonSideAsn: int, ownerAccount: string, directConnectGatewayState: string, stateChangeError: string>>
# operationId: UpdateDirectConnectGateway
export def "update-direct-connect-gateway" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  direct_connect_gateway_id: string # The ID of the Direct Connect gateway to update.
  new_direct_connect_gateway_name: string # The new name for the Direct Connect gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UpdateDirectConnectGateway"}]
    body: {content_type: "application/json", kind: json, fields: [{name: directConnectGatewayId, var: direct_connect_gateway_id}, {name: newDirectConnectGatewayName, var: new_direct_connect_gateway_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, direct_connect_gateway_id: $direct_connect_gateway_id, new_direct_connect_gateway_name: $new_direct_connect_gateway_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes of the Direct Connect gateway association. Add or remove prefixes from the association.
#
# POST /
# Returns: record<directConnectGatewayAssociation: record<directConnectGatewayId: string, directConnectGatewayOwnerAccount: string, associationState: string, stateChangeError: string, associatedGateway: record<id: string, type: string, ownerAccount: string, region: string>, associationId: string, allowedPrefixesToDirectConnectGateway: list<record>, virtualGatewayId: string, virtualGatewayRegion: string, virtualGatewayOwnerAccount: string>>
# operationId: UpdateDirectConnectGatewayAssociation
export def "update-direct-connect-gateway-association" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  --association-id: string # The ID of the Direct Connect gateway association.
  --add-allowed-prefixes-to-direct-connect-gateway: list # The Amazon VPC prefixes to advertise to the Direct Connect gateway. — item shape: {cidr?: string}
  --remove-allowed-prefixes-to-direct-connect-gateway: list # The Amazon VPC prefixes to no longer advertise to the Direct Connect gateway. — item shape: {cidr?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UpdateDirectConnectGatewayAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: associationId, var: association_id}, {name: addAllowedPrefixesToDirectConnectGateway, var: add_allowed_prefixes_to_direct_connect_gateway}, {name: removeAllowedPrefixesToDirectConnectGateway, var: remove_allowed_prefixes_to_direct_connect_gateway}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, association_id: $association_id, add_allowed_prefixes_to_direct_connect_gateway: $add_allowed_prefixes_to_direct_connect_gateway, remove_allowed_prefixes_to_direct_connect_gateway: $remove_allowed_prefixes_to_direct_connect_gateway
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the attributes of the specified link aggregation group (LAG). You can update the following LAG attributes: The name of the LAG. The value for the minimum number of connections that must be operational for the LAG itself to be operational. The LAG's MACsec encryption mode. Amazon Web Services assigns this value to each connection which is part of the LAG. The tags If you adjust the threshold value for the minimum number of operational connections, ensure that the new value does not cause the LAG to fall below the threshold and become non-operational.
#
# POST /
# Returns: record<connectionsBandwidth: string, numberOfConnections: int, lagId: string, ownerAccount: string, lagName: string, lagState: string, location: string, region: string, minimumLinks: int, awsDevice: string, awsDeviceV2: string, awsLogicalDeviceId: string, connections: table<ownerAccount: string, connectionId: string, connectionName: string, connectionState: string, region: string, location: string, bandwidth: string, vlan: int, partnerName: string, loaIssueTime: string, lagId: string, awsDevice: string, jumboFrameCapable: bool, awsDeviceV2: string, awsLogicalDeviceId: string, hasLogicalRedundancy: string, tags: list, providerName: string, macSecCapable: bool, portEncryptionStatus: string, encryptionMode: string, macSecKeys: list>, allowsHostedConnections: bool, jumboFrameCapable: bool, hasLogicalRedundancy: string, tags: table<key: string, value: string>, providerName: string, macSecCapable: bool, encryptionMode: string, macSecKeys: table<secretARN: string, ckn: string, state: string, startOn: string>>
# operationId: UpdateLag
export def "update-lag" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  lag_id: string # The ID of the LAG.
  --lag-name: string # The name of the LAG.
  --minimum-links: int # The minimum number of physical connections that must be operational for the LAG itself to be operational.
  --encryption-mode: string # The LAG MAC Security (MACsec) encryption mode. Amazon Web Services applies the value to all connections which are part of the LAG.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UpdateLag"}]
    body: {content_type: "application/json", kind: json, fields: [{name: lagId, var: lag_id}, {name: lagName, var: lag_name}, {name: minimumLinks, var: minimum_links}, {name: encryptionMode, var: encryption_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, lag_id: $lag_id, lag_name: $lag_name, minimum_links: $minimum_links, encryption_mode: $encryption_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes of the specified virtual private interface. Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call DescribeConnections. To check whether your virtual q interface supports jumbo frames, call DescribeVirtualInterfaces.
#
# POST /
# Returns: record<ownerAccount: string, virtualInterfaceId: string, location: string, connectionId: string, virtualInterfaceType: string, virtualInterfaceName: string, vlan: int, asn: int, amazonSideAsn: int, authKey: string, amazonAddress: string, customerAddress: string, addressFamily: string, virtualInterfaceState: string, customerRouterConfig: string, mtu: int, jumboFrameCapable: bool, virtualGatewayId: string, directConnectGatewayId: string, routeFilterPrefixes: table<cidr: string>, bgpPeers: table<bgpPeerId: string, asn: int, authKey: string, addressFamily: string, amazonAddress: string, customerAddress: string, bgpPeerState: string, bgpStatus: string, awsDeviceV2: string, awsLogicalDeviceId: string>, region: string, awsDeviceV2: string, awsLogicalDeviceId: string, tags: table<key: string, value: string>, siteLinkEnabled: bool>
# operationId: UpdateVirtualInterfaceAttributes
export def "update-virtual-interface-attributes" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  virtual_interface_id: string # The ID of the virtual private interface.
  --mtu: int # The maximum transmission unit (MTU), in bytes. The supported values are 1500 and 9001. The default value is 1500.
  --enable-site-link: oneof<nothing, bool> # Indicates whether to enable or disable SiteLink.
  --virtual-interface-name: string # The name of the virtual private interface.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "OvertureService.UpdateVirtualInterfaceAttributes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: virtualInterfaceId, var: virtual_interface_id}, {name: mtu, var: mtu}, {name: enableSiteLink, var: enable_site_link}, {name: virtualInterfaceName, var: virtual_interface_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, virtual_interface_id: $virtual_interface_id, mtu: $mtu, enable_site_link: $enable_site_link, virtual_interface_name: $virtual_interface_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
