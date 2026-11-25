# Auto-generated client for AWS IoT v2015-05-28
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iot/2015-05-28/openapi.json
# Auth: --token flag or $env.AWS_IOT_TOKEN

const CLIENT = {
  base_url: "http://iot.us-east-1.amazonaws.com"
  token_env_var: "AWS_IOT_TOKEN"
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

def base-url-completer [] { ["http://iot.us-east-1.amazonaws.com" "http://iot.us-east-2.amazonaws.com" "http://iot.us-west-1.amazonaws.com" "http://iot.us-west-2.amazonaws.com" "http://iot.us-gov-west-1.amazonaws.com" "http://iot.us-gov-east-1.amazonaws.com" "http://iot.ca-central-1.amazonaws.com" "http://iot.eu-north-1.amazonaws.com" "http://iot.eu-west-1.amazonaws.com" "http://iot.eu-west-2.amazonaws.com" "http://iot.eu-west-3.amazonaws.com" "http://iot.eu-central-1.amazonaws.com" "http://iot.eu-south-1.amazonaws.com" "http://iot.af-south-1.amazonaws.com" "http://iot.ap-northeast-1.amazonaws.com" "http://iot.ap-northeast-2.amazonaws.com" "http://iot.ap-northeast-3.amazonaws.com" "http://iot.ap-southeast-1.amazonaws.com" "http://iot.ap-southeast-2.amazonaws.com" "http://iot.ap-east-1.amazonaws.com" "http://iot.ap-south-1.amazonaws.com" "http://iot.sa-east-1.amazonaws.com" "http://iot.me-south-1.amazonaws.com" "https://iot.us-east-1.amazonaws.com" "https://iot.us-east-2.amazonaws.com" "https://iot.us-west-1.amazonaws.com" "https://iot.us-west-2.amazonaws.com" "https://iot.us-gov-west-1.amazonaws.com" "https://iot.us-gov-east-1.amazonaws.com" "https://iot.ca-central-1.amazonaws.com" "https://iot.eu-north-1.amazonaws.com" "https://iot.eu-west-1.amazonaws.com" "https://iot.eu-west-2.amazonaws.com" "https://iot.eu-west-3.amazonaws.com" "https://iot.eu-central-1.amazonaws.com" "https://iot.eu-south-1.amazonaws.com" "https://iot.af-south-1.amazonaws.com" "https://iot.ap-northeast-1.amazonaws.com" "https://iot.ap-northeast-2.amazonaws.com" "https://iot.ap-northeast-3.amazonaws.com" "https://iot.ap-southeast-1.amazonaws.com" "https://iot.ap-southeast-2.amazonaws.com" "https://iot.ap-east-1.amazonaws.com" "https://iot.ap-south-1.amazonaws.com" "https://iot.sa-east-1.amazonaws.com" "https://iot.me-south-1.amazonaws.com" "http://iot.cn-north-1.amazonaws.com.cn" "http://iot.cn-northwest-1.amazonaws.com.cn" "https://iot.cn-north-1.amazonaws.com.cn" "https://iot.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def metric-type-completer [] { ["ip-address-list" "number" "number-list" "string-list"] }
def type-completer [] { ["TOPIC_FILTER"] }
def service-type-completer [] { ["CREDENTIAL_PROVIDER" "DATA" "JOBS"] }
def domain-configuration-status-completer [] { ["DISABLED" "ENABLED"] }
def unit-completer [] { ["Bits" "Bits/Second" "Bytes" "Bytes/Second" "Count" "Count/Second" "Gigabits" "Gigabits/Second" "Gigabytes" "Gigabytes/Second" "Kilobits" "Kilobits/Second" "Kilobytes" "Kilobytes/Second" "Megabits" "Megabits/Second" "Megabytes" "Megabytes/Second" "Microseconds" "Milliseconds" "None" "Percent" "Seconds" "Terabits" "Terabits/Second" "Terabytes" "Terabytes/Second"] }
def target-selection-completer [] { ["CONTINUOUS" "SNAPSHOT"] }
def type-completer-1 [] { ["FLEET_PROVISIONING" "JITP"] }
def frequency-completer [] { ["BIWEEKLY" "DAILY" "MONTHLY" "WEEKLY"] }
def day-of-week-completer [] { ["FRI" "MON" "SAT" "SUN" "THU" "TUE" "WED"] }
def status-completer-1 [] { ["DELETING" "DISABLED" "ENABLED" "ERROR" "IN_PROGRESS"] }
def new-status-completer [] { ["ACTIVE" "INACTIVE"] }
def new-auto-registration-status-completer [] { ["DISABLE" "ENABLE"] }
def target-type-completer [] { ["CLIENT_ID" "DEFAULT" "PRINCIPAL_ID" "SOURCE_IP" "THING_GROUP"] }
def default-log-level-completer [] { ["DEBUG" "DISABLED" "ERROR" "INFO" "WARN"] }
def behavior-criteria-type-completer [] { ["MACHINE_LEARNING" "STATIC" "STATISTICAL"] }
def verification-state-completer [] { ["BENIGN_POSITIVE" "FALSE_POSITIVE" "TRUE_POSITIVE" "UNKNOWN"] }
def action-status-completer [] { ["CANCELED" "COMPLETED" "FAILED" "IN_PROGRESS" "PENDING" "SKIPPED"] }
def task-status-completer [] { ["CANCELED" "COMPLETED" "FAILED" "IN_PROGRESS"] }
def task-type-completer [] { ["ON_DEMAND_AUDIT_TASK" "SCHEDULED_AUDIT_TASK"] }
def status-completer-2 [] { ["CANCELED" "FAILED" "IN_PROGRESS" "QUEUED" "REJECTED" "REMOVED" "SUCCEEDED" "TIMED_OUT"] }
def status-completer-3 [] { ["CANCELED" "COMPLETED" "DELETION_IN_PROGRESS" "IN_PROGRESS" "SCHEDULED"] }
def dimension-value-operator-completer [] { ["IN" "NOT_IN"] }
def action-type-completer [] { ["ADD_THINGS_TO_THING_GROUP" "ENABLE_IOT_LOGGING" "PUBLISH_FINDING_TO_SNS" "REPLACE_DEFAULT_POLICY_VERSION" "UPDATE_CA_CERTIFICATE" "UPDATE_DEVICE_CERTIFICATE"] }
def ota-update-status-completer [] { ["CREATE_COMPLETE" "CREATE_FAILED" "CREATE_IN_PROGRESS" "CREATE_PENDING" "DELETE_FAILED" "DELETE_IN_PROGRESS"] }
def report-type-completer [] { ["ERRORS" "RESULTS"] }
def status-completer-4 [] { ["Cancelled" "Cancelling" "Completed" "Failed" "InProgress"] }
def log-level-completer [] { ["DEBUG" "DISABLED" "ERROR" "INFO" "WARN"] }
def certificate-mode-completer [] { ["DEFAULT" "SNI_ONLY"] }
def status-completer-5 [] { ["ACTIVE" "INACTIVE" "PENDING_ACTIVATION" "PENDING_TRANSFER" "REGISTER_INACTIVE" "REVOKED"] }
def new-status-completer-1 [] { ["ACTIVE" "INACTIVE" "PENDING_ACTIVATION" "PENDING_TRANSFER" "REGISTER_INACTIVE" "REVOKED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-thing-to-billing-group: "record"
    add-thing-to-thing-group: "record"
    associate-targets-with-job: "record<jobArn: string, jobId: string, description: string>"
    attach-security-profile: "record"
    detach-security-profile: "record"
    attach-thing-principal: "record"
    detach-thing-principal: "record"
    cancel-audit-mitigation-actions-task: "record"
    cancel-audit-task: "record"
    cancel-detect-mitigation-actions-task: "record"
    cancel-job: "record<jobArn: string, jobId: string, description: string>"
    clear-default-authorizer: "record"
    describe-default-authorizer: "record<authorizerDescription: record<authorizerName: string, authorizerArn: string, authorizerFunctionArn: string, tokenKeyName: string, tokenSigningPublicKeys: record, status: string, creationDate: string, lastModifiedDate: string, signingDisabled: bool, enableCachingForHttp: bool>>"
    set-default-authorizer: "record<authorizerName: string, authorizerArn: string>"
    confirm-topic-rule-destination: "record"
    create-audit-suppression: "record"
    create-authorizer: "record<authorizerName: string, authorizerArn: string>"
    delete-authorizer: "record"
    describe-authorizer: "record<authorizerDescription: record<authorizerName: string, authorizerArn: string, authorizerFunctionArn: string, tokenKeyName: string, tokenSigningPublicKeys: record, status: string, creationDate: string, lastModifiedDate: string, signingDisabled: bool, enableCachingForHttp: bool>>"
    update-authorizer: "record<authorizerName: string, authorizerArn: string>"
    create-billing-group: "record<billingGroupName: string, billingGroupArn: string, billingGroupId: string>"
    delete-billing-group: "record"
    describe-billing-group: "record<billingGroupName: string, billingGroupId: string, billingGroupArn: string, version: int, billingGroupProperties: record<billingGroupDescription: string>, billingGroupMetadata: record<creationDate: string>>"
    update-billing-group: "record<version: int>"
    create-certificate-from-csr: "record<certificateArn: string, certificateId: string, certificatePem: string>"
    list-certificates: "record<certificates: table<certificateArn: string, certificateId: string, status: string, certificateMode: string, creationDate: string>, nextMarker: string>"
    create-custom-metric: "record<metricName: string, metricArn: string>"
    delete-custom-metric: "record"
    describe-custom-metric: "record<metricName: string, metricArn: string, metricType: string, displayName: string, creationDate: string, lastModifiedDate: string>"
    update-custom-metric: "record<metricName: string, metricArn: string, metricType: string, displayName: string, creationDate: string, lastModifiedDate: string>"
    create-dimension: "record<name: string, arn: string>"
    delete-dimension: "record"
    describe-dimension: "record<name: string, arn: string, type: string, stringValues: list<string>, creationDate: string, lastModifiedDate: string>"
    update-dimension: "record<name: string, arn: string, type: string, stringValues: list<string>, creationDate: string, lastModifiedDate: string>"
    create-domain-configuration: "record<domainConfigurationName: string, domainConfigurationArn: string>"
    delete-domain-configuration: "record"
    describe-domain-configuration: "record<domainConfigurationName: string, domainConfigurationArn: string, domainName: string, serverCertificates: table<serverCertificateArn: string, serverCertificateStatus: string, serverCertificateStatusDetail: string>, authorizerConfig: record<defaultAuthorizerName: string, allowAuthorizerOverride: bool>, domainConfigurationStatus: string, serviceType: string, domainType: string, lastStatusChangeDate: string>"
    update-domain-configuration: "record<domainConfigurationName: string, domainConfigurationArn: string>"
    create-dynamic-thing-group: "record<thingGroupName: string, thingGroupArn: string, thingGroupId: string, indexName: string, queryString: string, queryVersion: string>"
    delete-dynamic-thing-group: "record"
    update-dynamic-thing-group: "record<version: int>"
    create-fleet-metric: "record<metricName: string, metricArn: string>"
    describe-fleet-metric: "record<metricName: string, queryString: string, aggregationType: record<name: string, values: list<string>>, period: int, aggregationField: string, description: string, queryVersion: string, indexName: string, creationDate: string, lastModifiedDate: string, unit: string, version: int, metricArn: string>"
    create-job: "record<jobArn: string, jobId: string, description: string>"
    describe-job: "record<documentSource: string, job: record<jobArn: string, jobId: string, targetSelection: string, status: string, forceCanceled: bool, reasonCode: string, comment: string, targets: list<string>, description: string, presignedUrlConfig: record<roleArn: string, expiresInSec: int>, jobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record>, abortConfig: record<criteriaList: list>, createdAt: string, lastUpdatedAt: string, completedAt: string, jobProcessDetails: record<processingTargets: list, numberOfCanceledThings: int, numberOfSucceededThings: int, numberOfFailedThings: int, numberOfRejectedThings: int, numberOfQueuedThings: int, numberOfInProgressThings: int, numberOfRemovedThings: int, numberOfTimedOutThings: int>, timeoutConfig: record<inProgressTimeoutInMinutes: int>, namespaceId: string, jobTemplateArn: string, jobExecutionsRetryConfig: record<criteriaList: list>, documentParameters: record, isConcurrent: bool, schedulingConfig: record<startTime: string, endTime: string, endBehavior: string, maintenanceWindows: list>, scheduledJobRollouts: list<record>>>"
    create-job-template: "record<jobTemplateArn: string, jobTemplateId: string>"
    describe-job-template: "record<jobTemplateArn: string, jobTemplateId: string, description: string, documentSource: string, document: string, createdAt: string, presignedUrlConfig: record<roleArn: string, expiresInSec: int>, jobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record<baseRatePerMinute: int, incrementFactor: float, rateIncreaseCriteria: record>>, abortConfig: record<criteriaList: list<record>>, timeoutConfig: record<inProgressTimeoutInMinutes: int>, jobExecutionsRetryConfig: record<criteriaList: list<record>>, maintenanceWindows: table<startTime: string, durationInMinutes: int>>"
    create-keys-and-certificate: "record<certificateArn: string, certificateId: string, certificatePem: string, keyPair: record<PublicKey: string, PrivateKey: string>>"
    create-mitigation-action: "record<actionArn: string, actionId: string>"
    delete-mitigation-action: "record"
    describe-mitigation-action: "record<actionName: string, actionType: string, actionArn: string, actionId: string, roleArn: string, actionParams: record<updateDeviceCertificateParams: record<action: string>, updateCACertificateParams: record<action: string>, addThingsToThingGroupParams: record<thingGroupNames: list, overrideDynamicGroups: bool>, replaceDefaultPolicyVersionParams: record<templateName: string>, enableIoTLoggingParams: record<roleArnForLogging: string, logLevel: string>, publishFindingToSnsParams: record<topicArn: string>>, creationDate: string, lastModifiedDate: string>"
    update-mitigation-action: "record<actionArn: string, actionId: string>"
    create-ota-update: "record<otaUpdateId: string, awsIotJobId: string, otaUpdateArn: string, awsIotJobArn: string, otaUpdateStatus: string>"
    delete-ota-update: "record"
    get-ota-update: "record<otaUpdateInfo: record<otaUpdateId: string, otaUpdateArn: string, creationDate: string, lastModifiedDate: string, description: string, targets: list<string>, protocols: list<string>, awsJobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record>, awsJobPresignedUrlConfig: record<expiresInSec: int>, targetSelection: string, otaUpdateFiles: list<record>, otaUpdateStatus: string, awsIotJobId: string, awsIotJobArn: string, errorInfo: record<code: string, message: string>, additionalParameters: record>>"
    create-policy: "record<policyName: string, policyArn: string, policyDocument: string, policyVersionId: string>"
    get-policy: "record<policyName: string, policyArn: string, policyDocument: string, defaultVersionId: string, creationDate: string, lastModifiedDate: string, generationId: string>"
    create-policy-version: "record<policyArn: string, policyDocument: string, policyVersionId: string, isDefaultVersion: bool>"
    list-policy-versions: "record<policyVersions: table<versionId: string, isDefaultVersion: bool, createDate: string>>"
    create-provisioning-claim: "record<certificateId: string, certificatePem: string, keyPair: record<PublicKey: string, PrivateKey: string>, expiration: string>"
    create-provisioning-template: "record<templateArn: string, templateName: string, defaultVersionId: int>"
    list-provisioning-templates: "record<templates: table<templateArn: string, templateName: string, description: string, creationDate: string, lastModifiedDate: string, enabled: bool, type: string>, nextToken: string>"
    create-provisioning-template-version: "record<templateArn: string, templateName: string, versionId: int, isDefaultVersion: bool>"
    list-provisioning-template-versions: "record<versions: table<versionId: int, creationDate: string, isDefaultVersion: bool>, nextToken: string>"
    create-role-alias: "record<roleAlias: string, roleAliasArn: string>"
    delete-role-alias: "record"
    describe-role-alias: "record<roleAliasDescription: record<roleAlias: string, roleAliasArn: string, roleArn: string, owner: string, credentialDurationSeconds: int, creationDate: string, lastModifiedDate: string>>"
    update-role-alias: "record<roleAlias: string, roleAliasArn: string>"
    create-scheduled-audit: "record<scheduledAuditArn: string>"
    delete-scheduled-audit: "record"
    describe-scheduled-audit: "record<frequency: string, dayOfMonth: string, dayOfWeek: string, targetCheckNames: list<string>, scheduledAuditName: string, scheduledAuditArn: string>"
    update-scheduled-audit: "record<scheduledAuditArn: string>"
    create-security-profile: "record<securityProfileName: string, securityProfileArn: string>"
    delete-security-profile: "record"
    describe-security-profile: "record<securityProfileName: string, securityProfileArn: string, securityProfileDescription: string, behaviors: table<name: string, metric: string, metricDimension: record, criteria: record, suppressAlerts: bool>, alertTargets: record, additionalMetricsToRetain: list<string>, additionalMetricsToRetainV2: table<metric: string, metricDimension: record>, version: int, creationDate: string, lastModifiedDate: string>"
    update-security-profile: "record<securityProfileName: string, securityProfileArn: string, securityProfileDescription: string, behaviors: table<name: string, metric: string, metricDimension: record, criteria: record, suppressAlerts: bool>, alertTargets: record, additionalMetricsToRetain: list<string>, additionalMetricsToRetainV2: table<metric: string, metricDimension: record>, version: int, creationDate: string, lastModifiedDate: string>"
    create-stream: "record<streamId: string, streamArn: string, description: string, streamVersion: int>"
    delete-stream: "record"
    describe-stream: "record<streamInfo: record<streamId: string, streamArn: string, streamVersion: int, description: string, files: list<record>, createdAt: string, lastUpdatedAt: string, roleArn: string>>"
    update-stream: "record<streamId: string, streamArn: string, description: string, streamVersion: int>"
    create-thing: "record<thingName: string, thingArn: string, thingId: string>"
    delete-thing: "record"
    describe-thing: "record<defaultClientId: string, thingName: string, thingId: string, thingArn: string, thingTypeName: string, attributes: record, version: int, billingGroupName: string>"
    update-thing: "record"
    create-thing-group: "record<thingGroupName: string, thingGroupArn: string, thingGroupId: string>"
    delete-thing-group: "record"
    describe-thing-group: "record<thingGroupName: string, thingGroupId: string, thingGroupArn: string, version: int, thingGroupProperties: record<thingGroupDescription: string, attributePayload: record<attributes: record, merge: bool>>, thingGroupMetadata: record<parentGroupName: string, rootToParentThingGroups: list<record>, creationDate: string>, indexName: string, queryString: string, queryVersion: string, status: string>"
    update-thing-group: "record<version: int>"
    create-thing-type: "record<thingTypeName: string, thingTypeArn: string, thingTypeId: string>"
    delete-thing-type: "record"
    describe-thing-type: "record<thingTypeName: string, thingTypeId: string, thingTypeArn: string, thingTypeProperties: record<thingTypeDescription: string, searchableAttributes: list<string>>, thingTypeMetadata: record<deprecated: bool, deprecationDate: string, creationDate: string>>"
    get-topic-rule: "record<ruleArn: string, rule: record<ruleName: string, sql: string, description: string, createdAt: string, actions: list<record>, ruleDisabled: bool, awsIotSqlVersion: string, errorAction: record<dynamoDB: record, dynamoDBv2: record, lambda: record, sns: record, sqs: record, kinesis: record, republish: record, s3: record, firehose: record, cloudwatchMetric: record, cloudwatchAlarm: record, cloudwatchLogs: record, elasticsearch: record, salesforce: record, iotAnalytics: record, iotEvents: record, iotSiteWise: record, stepFunctions: record, timestream: record, http: record, kafka: record, openSearch: record, location: record>>>"
    create-topic-rule-destination: "record<topicRuleDestination: record<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlProperties: record<confirmationUrl: string>, vpcProperties: record<subnetIds: list, securityGroups: list, vpcId: string, roleArn: string>>>"
    list-topic-rule-destinations: "record<destinationSummaries: table<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlSummary: record, vpcDestinationSummary: record>, nextToken: string>"
    update-topic-rule-destination: "record"
    delete-account-audit-configuration: "record"
    describe-account-audit-configuration: "record<roleArn: string, auditNotificationTargetConfigurations: record, auditCheckConfigurations: record>"
    update-account-audit-configuration: "record"
    delete-audit-suppression: "record"
    delete-ca-certificate: "record"
    describe-ca-certificate: "record<certificateDescription: record<certificateArn: string, certificateId: string, status: string, certificatePem: string, ownedBy: string, creationDate: string, autoRegistrationStatus: string, lastModifiedDate: string, customerVersion: int, generationId: string, validity: record<notBefore: string, notAfter: string>, certificateMode: string>, registrationConfig: record<templateBody: string, roleArn: string, templateName: string>>"
    describe-certificate: "record<certificateDescription: record<certificateArn: string, certificateId: string, caCertificateId: string, status: string, certificatePem: string, ownedBy: string, previousOwnedBy: string, creationDate: string, lastModifiedDate: string, customerVersion: int, transferData: record<transferMessage: string, rejectReason: string, transferDate: string, acceptDate: string, rejectDate: string>, generationId: string, validity: record<notBefore: string, notAfter: string>, certificateMode: string>>"
    get-policy-version: "record<policyArn: string, policyName: string, policyDocument: string, policyVersionId: string, isDefaultVersion: bool, creationDate: string, lastModifiedDate: string, generationId: string>"
    delete-provisioning-template: "record"
    describe-provisioning-template: "record<templateArn: string, templateName: string, description: string, creationDate: string, lastModifiedDate: string, defaultVersionId: int, templateBody: string, enabled: bool, provisioningRoleArn: string, preProvisioningHook: record<payloadVersion: string, targetArn: string>, type: string>"
    update-provisioning-template: "record"
    delete-provisioning-template-version: "record"
    describe-provisioning-template-version: "record<versionId: int, creationDate: string, templateBody: string, isDefaultVersion: bool>"
    delete-registration-code: "record"
    get-registration-code: "record<registrationCode: string>"
    delete-topic-rule-destination: "record"
    get-topic-rule-destination: "record<topicRuleDestination: record<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlProperties: record<confirmationUrl: string>, vpcProperties: record<subnetIds: list, securityGroups: list, vpcId: string, roleArn: string>>>"
    deprecate-thing-type: "record"
    describe-audit-finding: "record<finding: record<findingId: string, taskId: string, checkName: string, taskStartTime: string, findingTime: string, severity: string, nonCompliantResource: record<resourceType: string, resourceIdentifier: record, additionalInfo: record>, relatedResources: list<record>, reasonForNonCompliance: string, reasonForNonComplianceCode: string, isSuppressed: bool>>"
    describe-audit-mitigation-actions-task: "record<taskStatus: string, startTime: string, endTime: string, taskStatistics: record, target: record<auditTaskId: string, findingIds: list<string>, auditCheckToReasonCodeFilter: record>, auditCheckToActionsMapping: record, actionsDefinition: table<name: string, id: string, roleArn: string, actionParams: record>>"
    start-audit-mitigation-actions-task: "record<taskId: string>"
    describe-audit-suppression: "record<checkName: string, resourceIdentifier: record<deviceCertificateId: string, caCertificateId: string, cognitoIdentityPoolId: string, clientId: string, policyVersionIdentifier: record<policyName: string, policyVersionId: string>, account: string, iamRoleArn: string, roleAliasArn: string, issuerCertificateIdentifier: record<issuerCertificateSubject: string, issuerId: string, issuerCertificateSerialNumber: string>, deviceCertificateArn: string>, expirationDate: string, suppressIndefinitely: bool, description: string>"
    describe-audit-task: "record<taskStatus: string, taskType: string, taskStartTime: string, taskStatistics: record<totalChecks: int, inProgressChecks: int, waitingForDataCollectionChecks: int, compliantChecks: int, nonCompliantChecks: int, failedChecks: int, canceledChecks: int>, scheduledAuditName: string, auditDetails: record>"
    describe-detect-mitigation-actions-task: "record<taskSummary: record<taskId: string, taskStatus: string, taskStartTime: string, taskEndTime: string, target: record<violationIds: list, securityProfileName: string, behaviorName: string>, violationEventOccurrenceRange: record<startTime: string, endTime: string>, onlyActiveViolationsIncluded: bool, suppressedAlertsIncluded: bool, actionsDefinition: list<record>, taskStatistics: record<actionsExecuted: int, actionsSkipped: int, actionsFailed: int>>>"
    start-detect-mitigation-actions-task: "record<taskId: string>"
    describe-endpoint: "record<endpointAddress: string>"
    describe-event-configurations: "record<eventConfigurations: record, creationDate: string, lastModifiedDate: string>"
    update-event-configurations: "record"
    describe-index: "record<indexName: string, indexStatus: string, schema: string>"
    describe-job-execution: "record<execution: record<jobId: string, status: string, forceCanceled: bool, statusDetails: record<detailsMap: record>, thingArn: string, queuedAt: string, startedAt: string, lastUpdatedAt: string, executionNumber: int, versionNumber: int, approximateSecondsBeforeTimedOut: int>>"
    describe-managed-job-template: "record<templateName: string, templateArn: string, description: string, templateVersion: string, environments: list<string>, documentParameters: table<key: string, description: string, regex: string, example: string, optional: bool>, document: string>"
    describe-thing-registration-task: "record<taskId: string, creationDate: string, lastModifiedDate: string, templateBody: string, inputFileBucket: string, inputFileKey: string, roleArn: string, status: string, message: string, successCount: int, failureCount: int, percentageProgress: int>"
    get-behavior-model-training-summaries: "record<summaries: table<securityProfileName: string, behaviorName: string, trainingDataCollectionStartDate: string, modelStatus: string, datapointsCollectionPercentage: float, lastModelRefreshDate: string>, nextToken: string>"
    get-buckets-aggregation: "record<totalCount: int, buckets: table<keyValue: string, count: int>>"
    get-cardinality: "record<cardinality: int>"
    get-effective-policies: "record<effectivePolicies: table<policyName: string, policyArn: string, policyDocument: string>>"
    get-indexing-configuration: "record<thingIndexingConfiguration: record<thingIndexingMode: string, thingConnectivityIndexingMode: string, deviceDefenderIndexingMode: string, namedShadowIndexingMode: string, managedFields: list<record>, customFields: list<record>, filter: record<namedShadowNames: list>>, thingGroupIndexingConfiguration: record<thingGroupIndexingMode: string, managedFields: list<record>, customFields: list<record>>>"
    update-indexing-configuration: "record"
    get-job-document: "record<document: string>"
    get-logging-options: "record<roleArn: string, logLevel: string>"
    get-percentiles: "record<percentiles: table<percent: float, value: float>>"
    get-statistics: "record<statistics: record<count: int, average: float, sum: float, minimum: float, maximum: float, sumOfSquares: float, variance: float, stdDeviation: float>>"
    get-v2-logging-options: "record<roleArn: string, defaultLogLevel: string, disableAllLogs: bool>"
    list-active-violations: "record<activeViolations: table<violationId: string, thingName: string, securityProfileName: string, behavior: record, lastViolationValue: record, violationEventAdditionalInfo: record, verificationState: string, verificationStateDescription: string, lastViolationTime: string, violationStartTime: string>, nextToken: string>"
    list-attached-policies: "record<policies: table<policyName: string, policyArn: string>, nextMarker: string>"
    list-audit-findings: "record<findings: table<findingId: string, taskId: string, checkName: string, taskStartTime: string, findingTime: string, severity: string, nonCompliantResource: record, relatedResources: list, reasonForNonCompliance: string, reasonForNonComplianceCode: string, isSuppressed: bool>, nextToken: string>"
    list-audit-mitigation-actions-executions: "record<actionsExecutions: table<taskId: string, findingId: string, actionName: string, actionId: string, status: string, startTime: string, endTime: string, errorCode: string, message: string>, nextToken: string>"
    list-audit-mitigation-actions-tasks: "record<tasks: table<taskId: string, startTime: string, taskStatus: string>, nextToken: string>"
    list-audit-suppressions: "record<suppressions: table<checkName: string, resourceIdentifier: record, expirationDate: string, suppressIndefinitely: bool, description: string>, nextToken: string>"
    list-audit-tasks: "record<tasks: table<taskId: string, taskStatus: string, taskType: string>, nextToken: string>"
    list-authorizers: "record<authorizers: table<authorizerName: string, authorizerArn: string>, nextMarker: string>"
    list-billing-groups: "record<billingGroups: table<groupName: string, groupArn: string>, nextToken: string>"
    list-ca-certificates: "record<certificates: table<certificateArn: string, certificateId: string, status: string, creationDate: string>, nextMarker: string>"
    list-certificates-by-ca: "record<certificates: table<certificateArn: string, certificateId: string, status: string, certificateMode: string, creationDate: string>, nextMarker: string>"
    list-custom-metrics: "record<metricNames: list<string>, nextToken: string>"
    list-detect-mitigation-actions-executions: "record<actionsExecutions: table<taskId: string, violationId: string, actionName: string, thingName: string, executionStartDate: string, executionEndDate: string, status: string, errorCode: string, message: string>, nextToken: string>"
    list-detect-mitigation-actions-tasks: "record<tasks: table<taskId: string, taskStatus: string, taskStartTime: string, taskEndTime: string, target: record, violationEventOccurrenceRange: record, onlyActiveViolationsIncluded: bool, suppressedAlertsIncluded: bool, actionsDefinition: list, taskStatistics: record>, nextToken: string>"
    list-dimensions: "record<dimensionNames: list<string>, nextToken: string>"
    list-domain-configurations: "record<domainConfigurations: table<domainConfigurationName: string, domainConfigurationArn: string, serviceType: string>, nextMarker: string>"
    list-fleet-metrics: "record<fleetMetrics: table<metricName: string, metricArn: string>, nextToken: string>"
    list-indices: "record<indexNames: list<string>, nextToken: string>"
    list-job-executions-for-job: "record<executionSummaries: table<thingArn: string, jobExecutionSummary: record>, nextToken: string>"
    list-job-executions-for-thing: "record<executionSummaries: table<jobId: string, jobExecutionSummary: record>, nextToken: string>"
    list-job-templates: "record<jobTemplates: table<jobTemplateArn: string, jobTemplateId: string, description: string, createdAt: string>, nextToken: string>"
    list-jobs: "record<jobs: table<jobArn: string, jobId: string, thingGroupId: string, targetSelection: string, status: string, createdAt: string, lastUpdatedAt: string, completedAt: string, isConcurrent: bool>, nextToken: string>"
    list-managed-job-templates: "record<managedJobTemplates: table<templateArn: string, templateName: string, description: string, environments: list, templateVersion: string>, nextToken: string>"
    list-metric-values: "record<metricDatumList: table<timestamp: string, value: record>, nextToken: string>"
    list-mitigation-actions: "record<actionIdentifiers: table<actionName: string, actionArn: string, creationDate: string>, nextToken: string>"
    list-ota-updates: "record<otaUpdates: table<otaUpdateId: string, otaUpdateArn: string, creationDate: string>, nextToken: string>"
    list-outgoing-certificates: "record<outgoingCertificates: table<certificateArn: string, certificateId: string, transferredTo: string, transferDate: string, transferMessage: string, creationDate: string>, nextMarker: string>"
    list-policies: "record<policies: table<policyName: string, policyArn: string>, nextMarker: string>"
    list-policy-principals: "record<principals: list<string>, nextMarker: string>"
    list-principal-policies: "record<policies: table<policyName: string, policyArn: string>, nextMarker: string>"
    list-principal-things: "record<things: list<string>, nextToken: string>"
    list-related-resources-for-audit-finding: "record<relatedResources: table<resourceType: string, resourceIdentifier: record, additionalInfo: record>, nextToken: string>"
    list-role-aliases: "record<roleAliases: list<string>, nextMarker: string>"
    list-scheduled-audits: "record<scheduledAudits: table<scheduledAuditName: string, scheduledAuditArn: string, frequency: string, dayOfMonth: string, dayOfWeek: string>, nextToken: string>"
    list-security-profiles: "record<securityProfileIdentifiers: table<name: string, arn: string>, nextToken: string>"
    list-security-profiles-for-target: "record<securityProfileTargetMappings: table<securityProfileIdentifier: record, target: record>, nextToken: string>"
    list-streams: "record<streams: table<streamId: string, streamArn: string, streamVersion: int, description: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: table<Key: string, Value: string>, nextToken: string>"
    list-targets-for-policy: "record<targets: list<string>, nextMarker: string>"
    list-targets-for-security-profile: "record<securityProfileTargets: table<arn: string>, nextToken: string>"
    list-thing-groups: "record<thingGroups: table<groupName: string, groupArn: string>, nextToken: string>"
    list-thing-groups-for-thing: "record<thingGroups: table<groupName: string, groupArn: string>, nextToken: string>"
    list-thing-principals: "record<principals: list<string>, nextToken: string>"
    list-thing-registration-task-reports: "record<resourceLinks: list<string>, reportType: string, nextToken: string>"
    list-thing-registration-tasks: "record<taskIds: list<string>, nextToken: string>"
    start-thing-registration-task: "record<taskId: string>"
    list-thing-types: "record<thingTypes: table<thingTypeName: string, thingTypeArn: string, thingTypeProperties: record, thingTypeMetadata: record>, nextToken: string>"
    list-things: "record<things: table<thingName: string, thingTypeName: string, thingArn: string, attributes: record, version: int>, nextToken: string>"
    register-thing: "record<certificatePem: string, resourceArns: record>"
    list-things-in-billing-group: "record<things: list<string>, nextToken: string>"
    list-things-in-thing-group: "record<things: list<string>, nextToken: string>"
    list-topic-rules: "record<rules: table<ruleArn: string, ruleName: string, topicPattern: string, createdAt: string, ruleDisabled: bool>, nextToken: string>"
    list-v2-logging-levels: "record<logTargetConfigurations: table<logTarget: record, logLevel: string>, nextToken: string>"
    list-violation-events: "record<violationEvents: table<violationId: string, thingName: string, securityProfileName: string, behavior: record, metricValue: record, violationEventAdditionalInfo: record, violationEventType: string, verificationState: string, verificationStateDescription: string, violationEventTime: string>, nextToken: string>"
    put-verification-state-on-violation: "record"
    register-ca-certificate: "record<certificateArn: string, certificateId: string>"
    register-certificate: "record<certificateArn: string, certificateId: string>"
    register-certificate-without-ca: "record<certificateArn: string, certificateId: string>"
    remove-thing-from-billing-group: "record"
    remove-thing-from-thing-group: "record"
    search-index: "record<nextToken: string, things: table<thingName: string, thingId: string, thingTypeName: string, thingGroupNames: list, attributes: record, shadow: string, deviceDefender: string, connectivity: record>, thingGroups: table<thingGroupName: string, thingGroupId: string, thingGroupDescription: string, attributes: record, parentGroupNames: list>>"
    start-on-demand-audit-task: "record<taskId: string>"
    stop-thing-registration-task: "record"
    tag-resource: "record"
    test-authorization: "record<authResults: table<authInfo: record, allowed: record, denied: record, authDecision: string, missingContextValues: list>>"
    test-invoke-authorizer: "record<isAuthenticated: bool, principalId: string, policyDocuments: list<string>, refreshAfterInSeconds: int, disconnectAfterInSeconds: int>"
    transfer-certificate: "record<transferredCertificateArn: string>"
    untag-resource: "record"
    update-audit-suppression: "record"
    update-thing-groups-for-thing: "record"
    validate-security-profile-behaviors: "record<valid: bool, validationErrors: table<errorMessage: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-certificate-transfer" "add-thing-to-billing-group" "add-thing-to-thing-group" "associate-targets-with-job" "attach-policy" "detach-policy" "attach-principal-policy" "detach-principal-policy" "attach-security-profile" "detach-security-profile" "attach-thing-principal" "detach-thing-principal" "cancel-audit-mitigation-actions-task" "cancel-audit-task" "cancel-certificate-transfer" "cancel-detect-mitigation-actions-task" "cancel-job" "cancel-job-execution" "clear-default-authorizer" "describe-default-authorizer" "set-default-authorizer" "confirm-topic-rule-destination" "create-audit-suppression" "create-authorizer" "delete-authorizer" "describe-authorizer" "update-authorizer" "create-billing-group" "delete-billing-group" "describe-billing-group" "update-billing-group" "create-certificate-from-csr" "list-certificates" "create-custom-metric" "delete-custom-metric" "describe-custom-metric" "update-custom-metric" "create-dimension" "delete-dimension" "describe-dimension" "update-dimension" "create-domain-configuration" "delete-domain-configuration" "describe-domain-configuration" "update-domain-configuration" "create-dynamic-thing-group" "delete-dynamic-thing-group" "update-dynamic-thing-group" "create-fleet-metric" "delete-fleet-metric" "describe-fleet-metric" "update-fleet-metric" "create-job" "delete-job" "describe-job" "update-job" "create-job-template" "delete-job-template" "describe-job-template" "create-keys-and-certificate" "create-mitigation-action" "delete-mitigation-action" "describe-mitigation-action" "update-mitigation-action" "create-ota-update" "delete-ota-update" "get-ota-update" "create-policy" "delete-policy" "get-policy" "create-policy-version" "list-policy-versions" "create-provisioning-claim" "create-provisioning-template" "list-provisioning-templates" "create-provisioning-template-version" "list-provisioning-template-versions" "create-role-alias" "delete-role-alias" "describe-role-alias" "update-role-alias" "create-scheduled-audit" "delete-scheduled-audit" "describe-scheduled-audit" "update-scheduled-audit" "create-security-profile" "delete-security-profile" "describe-security-profile" "update-security-profile" "create-stream" "delete-stream" "describe-stream" "update-stream" "create-thing" "delete-thing" "describe-thing" "update-thing" "create-thing-group" "delete-thing-group" "describe-thing-group" "update-thing-group" "create-thing-type" "delete-thing-type" "describe-thing-type" "create-topic-rule" "delete-topic-rule" "get-topic-rule" "replace-topic-rule" "create-topic-rule-destination" "list-topic-rule-destinations" "update-topic-rule-destination" "delete-account-audit-configuration" "describe-account-audit-configuration" "update-account-audit-configuration" "delete-audit-suppression" "delete-ca-certificate" "describe-ca-certificate" "update-ca-certificate" "delete-certificate" "describe-certificate" "delete-job-execution" "delete-policy-version" "get-policy-version" "set-default-policy-version" "delete-provisioning-template" "describe-provisioning-template" "update-provisioning-template" "delete-provisioning-template-version" "describe-provisioning-template-version" "delete-registration-code" "get-registration-code" "delete-topic-rule-destination" "get-topic-rule-destination" "delete-v2-logging-level" "deprecate-thing-type" "describe-audit-finding" "describe-audit-mitigation-actions-task" "start-audit-mitigation-actions-task" "describe-audit-suppression" "describe-audit-task" "describe-detect-mitigation-actions-task" "start-detect-mitigation-actions-task" "describe-endpoint" "describe-event-configurations" "update-event-configurations" "describe-index" "describe-job-execution" "describe-managed-job-template" "describe-thing-registration-task" "disable-topic-rule" "enable-topic-rule" "get-behavior-model-training-summaries" "get-buckets-aggregation" "get-cardinality" "get-effective-policies" "get-indexing-configuration" "update-indexing-configuration" "get-job-document" "get-logging-options" "set-logging-options" "get-percentiles" "get-statistics" "get-v2-logging-options" "set-v2-logging-options" "list-active-violations" "list-attached-policies" "list-audit-findings" "list-audit-mitigation-actions-executions" "list-audit-mitigation-actions-tasks" "list-audit-suppressions" "list-audit-tasks" "list-authorizers" "list-billing-groups" "list-ca-certificates" "list-certificates-by-ca" "list-custom-metrics" "list-detect-mitigation-actions-executions" "list-detect-mitigation-actions-tasks" "list-dimensions" "list-domain-configurations" "list-fleet-metrics" "list-indices" "list-job-executions-for-job" "list-job-executions-for-thing" "list-job-templates" "list-jobs" "list-managed-job-templates" "list-metric-values" "list-mitigation-actions" "list-ota-updates" "list-outgoing-certificates" "list-policies" "list-policy-principals" "list-principal-policies" "list-principal-things" "list-related-resources-for-audit-finding" "list-role-aliases" "list-scheduled-audits" "list-security-profiles" "list-security-profiles-for-target" "list-streams" "list-tags-for-resource" "list-targets-for-policy" "list-targets-for-security-profile" "list-thing-groups" "list-thing-groups-for-thing" "list-thing-principals" "list-thing-registration-task-reports" "list-thing-registration-tasks" "start-thing-registration-task" "list-thing-types" "list-things" "register-thing" "list-things-in-billing-group" "list-things-in-thing-group" "list-topic-rules" "list-v2-logging-levels" "set-v2-logging-level" "list-violation-events" "put-verification-state-on-violation" "register-ca-certificate" "register-certificate" "register-certificate-without-ca" "reject-certificate-transfer" "remove-thing-from-billing-group" "remove-thing-from-thing-group" "search-index" "start-on-demand-audit-task" "stop-thing-registration-task" "tag-resource" "test-authorization" "test-invoke-authorizer" "transfer-certificate" "untag-resource" "update-audit-suppression" "update-certificate" "update-thing-groups-for-thing" "validate-security-profile-behaviors" "commands"] | sort) } | get name | first)
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

# Accepts a pending certificate transfer. The default state of the certificate is INACTIVE. To check for pending certificate transfers, call ListCertificates to enumerate your certificates. Requires permission to access the AcceptCertificateTransfer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /accept-certificate-transfer/{certificateId}
# operationId: AcceptCertificateTransfer
export def "accept-certificate-transfer" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-active: oneof<nothing, bool> # Specifies whether the certificate is active.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/accept-certificate-transfer/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    query: [{name: setAsActive, var: set_as_active}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, set_as_active: $set_as_active, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a thing to a billing group. Requires permission to access the AddThingToBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /billing-groups/addThingToBillingGroup
# Returns: record
# operationId: AddThingToBillingGroup
export def "add-thing-to-billing-group" [
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
  --billing-group-name: string # The name of the billing group. This call is asynchronous. It might take several seconds for the detachment to propagate.
  --billing-group-arn: string # The ARN of the billing group.
  --thing-name: string # The name of the thing to be added to the billing group.
  --thing-arn: string # The ARN of the thing to be added to the billing group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/billing-groups/addThingToBillingGroup"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingGroupName, var: billing_group_name}, {name: billingGroupArn, var: billing_group_arn}, {name: thingName, var: thing_name}, {name: thingArn, var: thing_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, billing_group_name: $billing_group_name, billing_group_arn: $billing_group_arn, thing_name: $thing_name, thing_arn: $thing_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a thing to a thing group. Requires permission to access the AddThingToThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /thing-groups/addThingToThingGroup
# Returns: record
# operationId: AddThingToThingGroup
export def "add-thing-to-thing-group" [
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
  --thing-group-name: string # The name of the group to which you are adding a thing.
  --thing-group-arn: string # The ARN of the group to which you are adding a thing.
  --thing-name: string # The name of the thing to add to a group.
  --thing-arn: string # The ARN of the thing to add to a group.
  --override-dynamic-groups: oneof<nothing, bool> # Override dynamic thing groups with static thing groups when 10-group limit is reached. If a thing belongs to 10 thing groups, and one or more of those groups are dynamic thing groups, adding a thing to a static group removes the thing from the last dynamic group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/thing-groups/addThingToThingGroup"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingGroupName, var: thing_group_name}, {name: thingGroupArn, var: thing_group_arn}, {name: thingName, var: thing_name}, {name: thingArn, var: thing_arn}, {name: overrideDynamicGroups, var: override_dynamic_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_group_name: $thing_group_name, thing_group_arn: $thing_group_arn, thing_name: $thing_name, thing_arn: $thing_arn, override_dynamic_groups: $override_dynamic_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a group with a continuous job. The following criteria must be met: The job must have been created with the targetSelection field set to "CONTINUOUS". The job status must currently be "IN_PROGRESS". The total number of targets associated with a job must not exceed 100. Requires permission to access the AssociateTargetsWithJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /jobs/{jobId}/targets
# Returns: record<jobArn: string, jobId: string, description: string>
# operationId: AssociateTargetsWithJob
export def "associate-targets-with-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  targets: list<string> # A list of thing group ARNs that define the targets of the job.
  --comment: string # An optional comment string describing why the job was associated with the targets.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jobs/{jobId}/targets"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: namespaceId, var: namespace_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: targets, var: targets}, {name: comment, var: comment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, namespace_id: $namespace_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, targets: $targets, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches the specified policy to the specified principal (certificate or other credential). Requires permission to access the AttachPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /target-policies/{policyName}
# operationId: AttachPolicy
export def "attach-policy" [
  policy_name: string
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
  target: string # The identity (https://docs.aws.amazon.com/iot/latest/developerguide/security-iam.html) to which the policy is attached. For example, a thing group or a certificate.
]: any -> any {
  $in | http-request {
    method: put
    path: "/target-policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a policy from the specified target. Because of the distributed nature of Amazon Web Services, it can take up to five minutes after a policy is detached before it's ready to be deleted. Requires permission to access the DetachPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /target-policies/{policyName}
# operationId: DetachPolicy
export def "detach-policy" [
  policy_name: string
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
  target: string # The target from which the policy will be detached.
]: any -> any {
  $in | http-request {
    method: post
    path: "/target-policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches the specified policy to the specified principal (certificate or other credential). Note: This action is deprecated and works as expected for backward compatibility, but we won't add enhancements. Use AttachPolicy instead. Requires permission to access the AttachPrincipalPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /principal-policies/{policyName}
# DEPRECATED
# operationId: AttachPrincipalPolicy
@deprecated
export def "attach-principal-policy" [
  policy_name: string
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
  --x-amzn-iot-principal: string # The principal, which can be a certificate ARN (as returned from the CreateCertificate operation) or an Amazon Cognito ID. (required)
]: nothing -> any {
  http-request {
    method: put
    path: "/principal-policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-iot-principal, var: x_amzn_iot_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_iot_principal: $x_amzn_iot_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified policy from the specified certificate. Note: This action is deprecated and works as expected for backward compatibility, but we won't add enhancements. Use DetachPolicy instead. Requires permission to access the DetachPrincipalPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /principal-policies/{policyName}
# DEPRECATED
# operationId: DetachPrincipalPolicy
@deprecated
export def "detach-principal-policy" [
  policy_name: string
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
  --x-amzn-iot-principal: string # The principal. Valid principals are CertificateArn (arn:aws:iot:region:accountId:cert/certificateId), thingGroupArn (arn:aws:iot:region:accountId:thinggroup/groupName) and CognitoId (region:id). (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/principal-policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-iot-principal, var: x_amzn_iot_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_iot_principal: $x_amzn_iot_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a Device Defender security profile with a thing group or this account. Each thing group or account can have up to five security profiles associated with it. Requires permission to access the AttachSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /security-profiles/{securityProfileName}/targets
# Returns: record
# operationId: AttachSecurityProfile
export def "attach-security-profile" [
  security_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-profile-target-arn: string # The ARN of the target (thing group) to which the security profile is attached. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/security-profiles/{securityProfileName}/targets"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    query: [{name: securityProfileTargetArn, var: security_profile_target_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, security_profile_target_arn: $security_profile_target_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a Device Defender security profile from a thing group or from this account. Requires permission to access the DetachSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /security-profiles/{securityProfileName}/targets
# Returns: record
# operationId: DetachSecurityProfile
export def "detach-security-profile" [
  security_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-profile-target-arn: string # The ARN of the thing group from which the security profile is detached. (required)
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
    path: "/security-profiles/{securityProfileName}/targets"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    query: [{name: securityProfileTargetArn, var: security_profile_target_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, security_profile_target_arn: $security_profile_target_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches the specified principal to the specified thing. A principal can be X.509 certificates, Amazon Cognito identities or federated identities. Requires permission to access the AttachThingPrincipal (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /things/{thingName}/principals
# Returns: record
# operationId: AttachThingPrincipal
export def "attach-thing-principal" [
  thing_name: string
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
  --x-amzn-principal: string # The principal, which can be a certificate ARN (as returned from the CreateCertificate operation) or an Amazon Cognito ID. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/things/{thingName}/principals"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-principal, var: x_amzn_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_principal: $x_amzn_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches the specified principal from the specified thing. A principal can be X.509 certificates, IAM users, groups, and roles, Amazon Cognito identities or federated identities. This call is asynchronous. It might take several seconds for the detachment to propagate. Requires permission to access the DetachThingPrincipal (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /things/{thingName}/principals
# Returns: record
# operationId: DetachThingPrincipal
export def "detach-thing-principal" [
  thing_name: string
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
  --x-amzn-principal: string # If the principal is a certificate, this value must be ARN of the certificate. If the principal is an Amazon Cognito identity, this value must be the ID of the Amazon Cognito identity. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/things/{thingName}/principals"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-principal, var: x_amzn_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_principal: $x_amzn_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a mitigation action task that is in progress. If the task is not in progress, an InvalidRequestException occurs. Requires permission to access the CancelAuditMitigationActionsTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /audit/mitigationactions/tasks/{taskId}/cancel
# Returns: record
# operationId: CancelAuditMitigationActionsTask
export def "cancel-audit-mitigation-actions-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/audit/mitigationactions/tasks/{taskId}/cancel"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an audit that is in progress. The audit can be either scheduled or on demand. If the audit isn't in progress, an "InvalidRequestException" occurs. Requires permission to access the CancelAuditTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /audit/tasks/{taskId}/cancel
# Returns: record
# operationId: CancelAuditTask
export def "cancel-audit-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/audit/tasks/{taskId}/cancel"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a pending transfer for the specified certificate. Note Only the transfer source account can use this operation to cancel a transfer. (Transfer destinations can use RejectCertificateTransfer instead.) After transfer, IoT returns the certificate to the source account in the INACTIVE state. After the destination account has accepted the transfer, the transfer cannot be cancelled. After a certificate transfer is cancelled, the status of the certificate changes from PENDING_TRANSFER to INACTIVE. Requires permission to access the CancelCertificateTransfer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /cancel-certificate-transfer/{certificateId}
# operationId: CancelCertificateTransfer
export def "cancel-certificate-transfer" [
  certificate_id: string
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
]: nothing -> any {
  http-request {
    method: patch
    path: "/cancel-certificate-transfer/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a Device Defender ML Detect mitigation action. Requires permission to access the CancelDetectMitigationActionsTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /detect/mitigationactions/tasks/{taskId}/cancel
# Returns: record
# operationId: CancelDetectMitigationActionsTask
export def "cancel-detect-mitigation-actions-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/detect/mitigationactions/tasks/{taskId}/cancel"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a job. Requires permission to access the CancelJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /jobs/{jobId}/cancel
# Returns: record<jobArn: string, jobId: string, description: string>
# operationId: CancelJob
export def "cancel-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # (Optional) If true job executions with status "IN_PROGRESS" and "QUEUED" are canceled, otherwise only job executions with status "QUEUED" are canceled. The default is false. Canceling a job which is "IN_PROGRESS", will cause a device which is executing the job to be unable to update the job execution status. Use caution and ensure that each device executing a job which is canceled is able to recover to a valid state.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --reason-code: string # (Optional)A reason code string that explains why the job was canceled.
  --comment: string # An optional comment string describing why the job was canceled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}/cancel"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: force, var: force}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: reasonCode, var: reason_code}, {name: comment, var: comment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, force: $force, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, reason_code: $reason_code, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the execution of a job for a given thing. Requires permission to access the CancelJobExecution (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /things/{thingName}/jobs/{jobId}/cancel
# operationId: CancelJobExecution
export def "cancel-job-execution" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # (Optional) If true the job execution will be canceled if it has status IN_PROGRESS or QUEUED, otherwise the job execution will be canceled only if it has status QUEUED. If you attempt to cancel a job execution that is IN_PROGRESS, and you do not set force to true, then an InvalidStateTransitionException will be thrown. The default is false. Canceling a job execution which is "IN_PROGRESS", will cause the device to be unable to update the job execution status. Use caution and ensure that the device is able to recover to a valid state.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --expected-version: int # (Optional) The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in Jobs does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned. (This makes it unnecessary to perform a separate DescribeJobExecution request in order to obtain the job execution status data.)
  --status-details: record # A collection of name/value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged. You can specify at most 10 name/value pairs.
]: any -> any {
  $in | http-request {
    method: put
    path: "/things/{thingName}/jobs/{jobId}/cancel"
    path_params: [{name: thingName, var: thing_name}, {name: jobId, var: job_id}]
    query: [{name: force, var: force}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: expectedVersion, var: expected_version}, {name: statusDetails, var: status_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, job_id: $job_id, force: $force, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, expected_version: $expected_version, status_details: $status_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears the default authorizer. Requires permission to access the ClearDefaultAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /default-authorizer
# Returns: record
# operationId: ClearDefaultAuthorizer
export def "clear-default-authorizer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/default-authorizer"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the default authorizer. Requires permission to access the DescribeDefaultAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /default-authorizer
# Returns: record<authorizerDescription: record<authorizerName: string, authorizerArn: string, authorizerFunctionArn: string, tokenKeyName: string, tokenSigningPublicKeys: record, status: string, creationDate: string, lastModifiedDate: string, signingDisabled: bool, enableCachingForHttp: bool>>
# operationId: DescribeDefaultAuthorizer
export def "describe-default-authorizer" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/default-authorizer"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the default authorizer. This will be used if a websocket connection is made without specifying an authorizer. Requires permission to access the SetDefaultAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /default-authorizer
# Returns: record<authorizerName: string, authorizerArn: string>
# operationId: SetDefaultAuthorizer
export def "set-default-authorizer" [
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
  authorizer_name: string # The authorizer name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/default-authorizer"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerName, var: authorizer_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_name: $authorizer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirms a topic rule destination. When you create a rule requiring a destination, IoT sends a confirmation message to the endpoint or base address you specify. The message includes a token which you pass back when calling ConfirmTopicRuleDestination to confirm that you own or have access to the endpoint. Requires permission to access the ConfirmTopicRuleDestination (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /confirmdestination/{confirmationToken}
# Returns: record
# operationId: ConfirmTopicRuleDestination
export def "confirm-topic-rule-destination" [
  confirmation_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/confirmdestination/{confirmationToken}"
    path_params: [{name: confirmationToken, var: confirmation_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    confirmation_token: $confirmation_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Device Defender audit suppression. Requires permission to access the CreateAuditSuppression (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/suppressions/create
# Returns: record
# operationId: CreateAuditSuppression
export def "create-audit-suppression" [
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
  check_name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  resource_identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
  --expiration-date: string # The epoch timestamp in seconds at which this suppression expires. (format: date-time)
  --suppress-indefinitely: oneof<nothing, bool> # Indicates whether a suppression should exist indefinitely or not.
  --description: string # The description of the audit suppression.
  client_request_token: string # Each audit supression must have a unique client request token. If you try to create a new audit suppression with the same token as one that already exists, an exception occurs. If you omit this value, Amazon Web Services SDKs will automatically generate a unique client request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/suppressions/create"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}, {name: expirationDate, var: expiration_date}, {name: suppressIndefinitely, var: suppress_indefinitely}, {name: description, var: description}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, check_name: $check_name, resource_identifier: $resource_identifier, expiration_date: $expiration_date, suppress_indefinitely: $suppress_indefinitely, description: $description, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an authorizer. Requires permission to access the CreateAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /authorizer/{authorizerName}
# Returns: record<authorizerName: string, authorizerArn: string>
# operationId: CreateAuthorizer
export def "create-authorizer" [
  authorizer_name: string
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
  authorizer_function_arn: string # The ARN of the authorizer's Lambda function.
  --token-key-name: string # The name of the token key used to extract the token from the HTTP headers.
  --token-signing-public-keys: record # The public keys used to verify the digital signature returned by your custom authentication service.
  --status: string@status-completer # The status of the create authorizer request.
  --tags: list # Metadata which can be used to manage the custom authorizer. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
  --signing-disabled: oneof<nothing, bool> # Specifies whether IoT validates the token signature in an authorization request.
  --enable-caching-for-http: oneof<nothing, bool> # When true, the result from the authorizer’s Lambda function is cached for clients that use persistent HTTP connections. The results are cached for the time specified by the Lambda function in refreshAfterInSeconds. This value does not affect authorization of clients that use MQTT connections. The default value is false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorizer/{authorizerName}"
    path_params: [{name: authorizerName, var: authorizer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerFunctionArn, var: authorizer_function_arn}, {name: tokenKeyName, var: token_key_name}, {name: tokenSigningPublicKeys, var: token_signing_public_keys}, {name: status, var: status}, {name: tags, var: tags}, {name: signingDisabled, var: signing_disabled}, {name: enableCachingForHttp, var: enable_caching_for_http}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorizer_name: $authorizer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_function_arn: $authorizer_function_arn, token_key_name: $token_key_name, token_signing_public_keys: $token_signing_public_keys, status: $status, tags: $tags, signing_disabled: $signing_disabled, enable_caching_for_http: $enable_caching_for_http
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an authorizer. Requires permission to access the DeleteAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /authorizer/{authorizerName}
# Returns: record
# operationId: DeleteAuthorizer
export def "delete-authorizer" [
  authorizer_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/authorizer/{authorizerName}"
    path_params: [{name: authorizerName, var: authorizer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorizer_name: $authorizer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an authorizer. Requires permission to access the DescribeAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /authorizer/{authorizerName}
# Returns: record<authorizerDescription: record<authorizerName: string, authorizerArn: string, authorizerFunctionArn: string, tokenKeyName: string, tokenSigningPublicKeys: record, status: string, creationDate: string, lastModifiedDate: string, signingDisabled: bool, enableCachingForHttp: bool>>
# operationId: DescribeAuthorizer
export def "describe-authorizer" [
  authorizer_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/authorizer/{authorizerName}"
    path_params: [{name: authorizerName, var: authorizer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorizer_name: $authorizer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an authorizer. Requires permission to access the UpdateAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /authorizer/{authorizerName}
# Returns: record<authorizerName: string, authorizerArn: string>
# operationId: UpdateAuthorizer
export def "update-authorizer" [
  authorizer_name: string
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
  --authorizer-function-arn: string # The ARN of the authorizer's Lambda function.
  --token-key-name: string # The key used to extract the token from the HTTP headers.
  --token-signing-public-keys: record # The public keys used to verify the token signature.
  --status: string@status-completer # The status of the update authorizer request.
  --enable-caching-for-http: oneof<nothing, bool> # When true, the result from the authorizer’s Lambda function is cached for the time specified in refreshAfterInSeconds. The cached result is used while the device reuses the same HTTP connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/authorizer/{authorizerName}"
    path_params: [{name: authorizerName, var: authorizer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerFunctionArn, var: authorizer_function_arn}, {name: tokenKeyName, var: token_key_name}, {name: tokenSigningPublicKeys, var: token_signing_public_keys}, {name: status, var: status}, {name: enableCachingForHttp, var: enable_caching_for_http}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorizer_name: $authorizer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_function_arn: $authorizer_function_arn, token_key_name: $token_key_name, token_signing_public_keys: $token_signing_public_keys, status: $status, enable_caching_for_http: $enable_caching_for_http
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a billing group. Requires permission to access the CreateBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /billing-groups/{billingGroupName}
# Returns: record<billingGroupName: string, billingGroupArn: string, billingGroupId: string>
# operationId: CreateBillingGroup
export def "create-billing-group" [
  billing_group_name: string
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
  --billing-group-properties: record # The properties of a billing group. — shape: {billingGroupDescription?: string}
  --tags: list # Metadata which can be used to manage the billing group. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/billing-groups/{billingGroupName}"
    path_params: [{name: billingGroupName, var: billing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingGroupProperties, var: billing_group_properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_name: $billing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, billing_group_properties: $billing_group_properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the billing group. Requires permission to access the DeleteBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /billing-groups/{billingGroupName}
# Returns: record
# operationId: DeleteBillingGroup
export def "delete-billing-group" [
  billing_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the billing group. If the version of the billing group does not match the expected version specified in the request, the DeleteBillingGroup request is rejected with a VersionConflictException.
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
    path: "/billing-groups/{billingGroupName}"
    path_params: [{name: billingGroupName, var: billing_group_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_name: $billing_group_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a billing group. Requires permission to access the DescribeBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /billing-groups/{billingGroupName}
# Returns: record<billingGroupName: string, billingGroupId: string, billingGroupArn: string, version: int, billingGroupProperties: record<billingGroupDescription: string>, billingGroupMetadata: record<creationDate: string>>
# operationId: DescribeBillingGroup
export def "describe-billing-group" [
  billing_group_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/billing-groups/{billingGroupName}"
    path_params: [{name: billingGroupName, var: billing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_name: $billing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information about the billing group. Requires permission to access the UpdateBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /billing-groups/{billingGroupName}
# Returns: record<version: int>
# operationId: UpdateBillingGroup
export def "update-billing-group" [
  billing_group_name: string
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
  billing_group_properties: record # The properties of a billing group. — shape: {billingGroupDescription?: string}
  --expected-version: int # The expected version of the billing group. If the version of the billing group does not match the expected version specified in the request, the UpdateBillingGroup request is rejected with a VersionConflictException.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/billing-groups/{billingGroupName}"
    path_params: [{name: billingGroupName, var: billing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingGroupProperties, var: billing_group_properties}, {name: expectedVersion, var: expected_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_name: $billing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, billing_group_properties: $billing_group_properties, expected_version: $expected_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an X.509 certificate using the specified certificate signing request. Requires permission to access the CreateCertificateFromCsr (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. The CSR must include a public key that is either an RSA key with a length of at least 2048 bits or an ECC key from NIST P-25 or NIST P-384 curves. For supported certificates, consult Certificate signing algorithms supported by IoT (https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html#x509-cert-algorithms). Reusing the same certificate signing request (CSR) results in a distinct certificate. You can create multiple certificates in a batch by creating a directory, copying multiple .csr files into that directory, and then specifying that directory on the command line. The following commands show how to create a batch of certificates given a batch of CSRs. In the following commands, we assume that a set of CSRs are located inside of the directory my-csr-directory: On Linux and OS X, the command is: $ ls my-csr-directory/ | xargs -I {} aws iot create-certificate-from-csr --certificate-signing-request file://my-csr-directory/{} This command lists all of the CSRs in my-csr-directory and pipes each CSR file name to the aws iot create-certificate-from-csr Amazon Web Services CLI command to create a certificate for the corresponding CSR. You can also run the aws iot create-certificate-from-csr part of the command in parallel to speed up the certificate creation process: $ ls my-csr-directory/ | xargs -P 10 -I {} aws iot create-certificate-from-csr --certificate-signing-request file://my-csr-directory/{} On Windows PowerShell, the command to create certificates for all CSRs in my-csr-directory is: > ls -Name my-csr-directory | %{aws iot create-certificate-from-csr --certificate-signing-request file://my-csr-directory/$_} On a Windows command prompt, the command to create certificates for all CSRs in my-csr-directory is: > forfiles /p my-csr-directory /c "cmd /c aws iot create-certificate-from-csr --certificate-signing-request file://@path"
#
# POST /certificates
# Returns: record<certificateArn: string, certificateId: string, certificatePem: string>
# operationId: CreateCertificateFromCsr
export def "create-certificate-from-csr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-active: oneof<nothing, bool> # Specifies whether the certificate is active.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  certificate_signing_request: string # The certificate signing request (CSR).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates"
    query: [{name: setAsActive, var: set_as_active}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateSigningRequest, var: certificate_signing_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    set_as_active: $set_as_active, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, certificate_signing_request: $certificate_signing_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the certificates registered in your Amazon Web Services account. The results are paginated with a default page size of 25. You can use the returned marker to retrieve additional results. Requires permission to access the ListCertificates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /certificates
# Returns: record<certificates: table<certificateArn: string, certificateId: string, status: string, certificateMode: string, creationDate: string>, nextMarker: string>
# operationId: ListCertificates
export def "list-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The result page size.
  --marker: string # The marker for the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If True, the results are returned in ascending order, based on the creation date.
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
    path: "/certificates"
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this API to define a Custom Metric published by your devices to Device Defender. Requires permission to access the CreateCustomMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /custom-metric/{metricName}
# Returns: record<metricName: string, metricArn: string>
# operationId: CreateCustomMetric
export def "create-custom-metric" [
  metric_name: string
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
  --display-name: string # The friendly name in the console for the custom metric. This name doesn't have to be unique. Don't use this name as the metric identifier in the device metric report. You can update the friendly name after you define it.
  metric_type: string@metric-type-completer # The type of the custom metric. The type number only takes a single metric value as an input, but when you submit the metrics value in the DeviceMetrics report, you must pass it as an array with a single value.
  --tags: list # Metadata that can be used to manage the custom metric. — item shape: {Key: string, Value?: string}
  client_request_token: string # Each custom metric must have a unique client request token. If you try to create a new custom metric that already exists with a different token, an exception occurs. If you omit this value, Amazon Web Services SDKs will automatically generate a unique client request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: metricType, var: metric_type}, {name: tags, var: tags}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, display_name: $display_name, metric_type: $metric_type, tags: $tags, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Device Defender detect custom metric. Requires permission to access the DeleteCustomMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. Before you can delete a custom metric, you must first remove the custom metric from all security profiles it's a part of. The security profile associated with the custom metric can be found using the ListSecurityProfiles (https://docs.aws.amazon.com/iot/latest/apireference/API_ListSecurityProfiles.html) API with metricName set to your custom metric name.
#
# DELETE /custom-metric/{metricName}
# Returns: record
# operationId: DeleteCustomMetric
export def "delete-custom-metric" [
  metric_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/custom-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Device Defender detect custom metric. Requires permission to access the DescribeCustomMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /custom-metric/{metricName}
# Returns: record<metricName: string, metricArn: string, metricType: string, displayName: string, creationDate: string, lastModifiedDate: string>
# operationId: DescribeCustomMetric
export def "describe-custom-metric" [
  metric_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Device Defender detect custom metric. Requires permission to access the UpdateCustomMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /custom-metric/{metricName}
# Returns: record<metricName: string, metricArn: string, metricType: string, displayName: string, creationDate: string, lastModifiedDate: string>
# operationId: UpdateCustomMetric
export def "update-custom-metric" [
  metric_name: string
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
  display_name: string # Field represents a friendly name in the console for the custom metric, it doesn't have to be unique. Don't use this name as the metric identifier in the device metric report. Can be updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/custom-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, display_name: $display_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a dimension that you can use to limit the scope of a metric used in a security profile for IoT Device Defender. For example, using a TOPIC_FILTER dimension, you can narrow down the scope of the metric only to MQTT topics whose name match the pattern specified in the dimension. Requires permission to access the CreateDimension (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /dimensions/{name}
# Returns: record<name: string, arn: string>
# operationId: CreateDimension
export def "create-dimension" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  type: string@type-completer # Specifies the type of dimension. Supported types: TOPIC_FILTER.
  string_values: list<string> # Specifies the value or list of values for the dimension. For TOPIC_FILTER dimensions, this is a pattern used to match the MQTT topic (for example, "admin/#").
  --tags: list # Metadata that can be used to manage the dimension. — item shape: {Key: string, Value?: string}
  client_request_token: string # Each dimension must have a unique client request token. If you try to create a new dimension with the same token as a dimension that already exists, an exception occurs. If you omit this value, Amazon Web Services SDKs will automatically generate a unique client request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dimensions/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: stringValues, var: string_values}, {name: tags, var: tags}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, type: $type, string_values: $string_values, tags: $tags, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified dimension from your Amazon Web Services accounts. Requires permission to access the DeleteDimension (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /dimensions/{name}
# Returns: record
# operationId: DeleteDimension
export def "delete-dimension" [
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
    path: "/dimensions/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about a dimension that is defined in your Amazon Web Services accounts. Requires permission to access the DescribeDimension (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /dimensions/{name}
# Returns: record<name: string, arn: string, type: string, stringValues: list<string>, creationDate: string, lastModifiedDate: string>
# operationId: DescribeDimension
export def "describe-dimension" [
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
    path: "/dimensions/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the definition for a dimension. You cannot change the type of a dimension after it is created (you can delete it and recreate it). Requires permission to access the UpdateDimension (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /dimensions/{name}
# Returns: record<name: string, arn: string, type: string, stringValues: list<string>, creationDate: string, lastModifiedDate: string>
# operationId: UpdateDimension
export def "update-dimension" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  string_values: list<string> # Specifies the value or list of values for the dimension. For TOPIC_FILTER dimensions, this is a pattern used to match the MQTT topic (for example, "admin/#").
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dimensions/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: stringValues, var: string_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, string_values: $string_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a domain configuration. Requires permission to access the CreateDomainConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /domainConfigurations/{domainConfigurationName}
# Returns: record<domainConfigurationName: string, domainConfigurationArn: string>
# operationId: CreateDomainConfiguration
export def "create-domain-configuration" [
  domain_configuration_name: string
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
  --domain-name: string # The name of the domain.
  --server-certificate-arns: list<string> # The ARNs of the certificates that IoT passes to the device during the TLS handshake. Currently you can specify only one certificate ARN. This value is not required for Amazon Web Services-managed domains.
  --validation-certificate-arn: string # The certificate used to validate the server certificate and prove domain name ownership. This certificate must be signed by a public certificate authority. This value is not required for Amazon Web Services-managed domains.
  --authorizer-config: record # An object that specifies the authorization service for a domain. — shape: {defaultAuthorizerName?: string, allowAuthorizerOverride?: bool}
  --service-type: string@service-type-completer # The type of service delivered by the endpoint. Amazon Web Services IoT Core currently supports only the DATA service type.
  --tags: list # Metadata which can be used to manage the domain configuration. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domainConfigurations/{domainConfigurationName}"
    path_params: [{name: domainConfigurationName, var: domain_configuration_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: serverCertificateArns, var: server_certificate_arns}, {name: validationCertificateArn, var: validation_certificate_arn}, {name: authorizerConfig, var: authorizer_config}, {name: serviceType, var: service_type}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_configuration_name: $domain_configuration_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, server_certificate_arns: $server_certificate_arns, validation_certificate_arn: $validation_certificate_arn, authorizer_config: $authorizer_config, service_type: $service_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified domain configuration. Requires permission to access the DeleteDomainConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /domainConfigurations/{domainConfigurationName}
# Returns: record
# operationId: DeleteDomainConfiguration
export def "delete-domain-configuration" [
  domain_configuration_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/domainConfigurations/{domainConfigurationName}"
    path_params: [{name: domainConfigurationName, var: domain_configuration_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_configuration_name: $domain_configuration_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets summary information about a domain configuration. Requires permission to access the DescribeDomainConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /domainConfigurations/{domainConfigurationName}
# Returns: record<domainConfigurationName: string, domainConfigurationArn: string, domainName: string, serverCertificates: table<serverCertificateArn: string, serverCertificateStatus: string, serverCertificateStatusDetail: string>, authorizerConfig: record<defaultAuthorizerName: string, allowAuthorizerOverride: bool>, domainConfigurationStatus: string, serviceType: string, domainType: string, lastStatusChangeDate: string>
# operationId: DescribeDomainConfiguration
export def "describe-domain-configuration" [
  domain_configuration_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domainConfigurations/{domainConfigurationName}"
    path_params: [{name: domainConfigurationName, var: domain_configuration_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_configuration_name: $domain_configuration_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates values stored in the domain configuration. Domain configurations for default endpoints can't be updated. Requires permission to access the UpdateDomainConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /domainConfigurations/{domainConfigurationName}
# Returns: record<domainConfigurationName: string, domainConfigurationArn: string>
# operationId: UpdateDomainConfiguration
export def "update-domain-configuration" [
  domain_configuration_name: string
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
  --authorizer-config: record # An object that specifies the authorization service for a domain. — shape: {defaultAuthorizerName?: string, allowAuthorizerOverride?: bool}
  --domain-configuration-status: string@domain-configuration-status-completer # The status to which the domain configuration should be updated.
  --remove-authorizer-config: oneof<nothing, bool> # Removes the authorization configuration from a domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domainConfigurations/{domainConfigurationName}"
    path_params: [{name: domainConfigurationName, var: domain_configuration_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizerConfig, var: authorizer_config}, {name: domainConfigurationStatus, var: domain_configuration_status}, {name: removeAuthorizerConfig, var: remove_authorizer_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_configuration_name: $domain_configuration_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, authorizer_config: $authorizer_config, domain_configuration_status: $domain_configuration_status, remove_authorizer_config: $remove_authorizer_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dynamic thing group. Requires permission to access the CreateDynamicThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /dynamic-thing-groups/{thingGroupName}
# Returns: record<thingGroupName: string, thingGroupArn: string, thingGroupId: string, indexName: string, queryString: string, queryVersion: string>
# operationId: CreateDynamicThingGroup
export def "create-dynamic-thing-group" [
  thing_group_name: string
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
  --thing-group-properties: record # Thing group properties. — shape: {thingGroupDescription?: string, attributePayload?: record}
  --index-name: string # The dynamic thing group index name. Currently one index is supported: AWS_Things.
  query_string: string # The dynamic thing group search query string. See Query Syntax (https://docs.aws.amazon.com/iot/latest/developerguide/query-syntax.html) for information about query string syntax.
  --query-version: string # The dynamic thing group query version. Currently one query version is supported: "2017-09-30". If not specified, the query version defaults to this value.
  --tags: list # Metadata which can be used to manage the dynamic thing group. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dynamic-thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingGroupProperties, var: thing_group_properties}, {name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: queryVersion, var: query_version}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_group_properties: $thing_group_properties, index_name: $index_name, query_string: $query_string, query_version: $query_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dynamic thing group. Requires permission to access the DeleteDynamicThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /dynamic-thing-groups/{thingGroupName}
# Returns: record
# operationId: DeleteDynamicThingGroup
export def "delete-dynamic-thing-group" [
  thing_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the dynamic thing group to delete.
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
    path: "/dynamic-thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a dynamic thing group. Requires permission to access the UpdateDynamicThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /dynamic-thing-groups/{thingGroupName}
# Returns: record<version: int>
# operationId: UpdateDynamicThingGroup
export def "update-dynamic-thing-group" [
  thing_group_name: string
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
  thing_group_properties: record # Thing group properties. — shape: {thingGroupDescription?: string, attributePayload?: record}
  --expected-version: int # The expected version of the dynamic thing group to update.
  --index-name: string # The dynamic thing group index to update. Currently one index is supported: AWS_Things.
  --query-string: string # The dynamic thing group search query string to update.
  --query-version: string # The dynamic thing group query version to update. Currently one query version is supported: "2017-09-30". If not specified, the query version defaults to this value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dynamic-thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingGroupProperties, var: thing_group_properties}, {name: expectedVersion, var: expected_version}, {name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: queryVersion, var: query_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_group_properties: $thing_group_properties, expected_version: $expected_version, index_name: $index_name, query_string: $query_string, query_version: $query_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a fleet metric. Requires permission to access the CreateFleetMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /fleet-metric/{metricName}
# Returns: record<metricName: string, metricArn: string>
# operationId: CreateFleetMetric
export def "create-fleet-metric" [
  metric_name: string
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
  query_string: string # The search query string.
  aggregation_type: record # The type of aggregation queries. — shape: {name?: "Statistics"|"Percentiles"|"Cardinality", values?: list<string>}
  period: int # The time in seconds between fleet metric emissions. Range [60(1 min), 86400(1 day)] and must be multiple of 60.
  aggregation_field: string # The field to aggregate.
  --description: string # The fleet metric description.
  --query-version: string # The query version.
  --index-name: string # The name of the index to search.
  --unit: string@unit-completer # Used to support unit transformation such as milliseconds to seconds. The unit must be supported by CW metric (https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_MetricDatum.html). Default to null.
  --tags: list # Metadata, which can be used to manage the fleet metric. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/fleet-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: queryString, var: query_string}, {name: aggregationType, var: aggregation_type}, {name: period, var: period}, {name: aggregationField, var: aggregation_field}, {name: description, var: description}, {name: queryVersion, var: query_version}, {name: indexName, var: index_name}, {name: unit, var: unit}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, query_string: $query_string, aggregation_type: $aggregation_type, period: $period, aggregation_field: $aggregation_field, description: $description, query_version: $query_version, index_name: $index_name, unit: $unit, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified fleet metric. Returns successfully with no error if the deletion is successful or you specify a fleet metric that doesn't exist. Requires permission to access the DeleteFleetMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /fleet-metric/{metricName}
# operationId: DeleteFleetMetric
export def "delete-fleet-metric" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the fleet metric to delete.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/fleet-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified fleet metric. Requires permission to access the DescribeFleetMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /fleet-metric/{metricName}
# Returns: record<metricName: string, queryString: string, aggregationType: record<name: string, values: list<string>>, period: int, aggregationField: string, description: string, queryVersion: string, indexName: string, creationDate: string, lastModifiedDate: string, unit: string, version: int, metricArn: string>
# operationId: DescribeFleetMetric
export def "describe-fleet-metric" [
  metric_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fleet-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the data for a fleet metric. Requires permission to access the UpdateFleetMetric (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /fleet-metric/{metricName}
# operationId: UpdateFleetMetric
export def "update-fleet-metric" [
  metric_name: string
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
  --query-string: string # The search query string.
  --aggregation-type: record # The type of aggregation queries. — shape: {name?: "Statistics"|"Percentiles"|"Cardinality", values?: list<string>}
  --period: int # The time in seconds between fleet metric emissions. Range [60(1 min), 86400(1 day)] and must be multiple of 60.
  --aggregation-field: string # The field to aggregate.
  --description: string # The description of the fleet metric.
  --query-version: string # The version of the query.
  index_name: string # The name of the index to search.
  --unit: string@unit-completer # Used to support unit transformation such as milliseconds to seconds. The unit must be supported by CW metric (https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_MetricDatum.html).
  --expected-version: int # The expected version of the fleet metric record in the registry.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/fleet-metric/{metricName}"
    path_params: [{name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: queryString, var: query_string}, {name: aggregationType, var: aggregation_type}, {name: period, var: period}, {name: aggregationField, var: aggregation_field}, {name: description, var: description}, {name: queryVersion, var: query_version}, {name: indexName, var: index_name}, {name: unit, var: unit}, {name: expectedVersion, var: expected_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, query_string: $query_string, aggregation_type: $aggregation_type, period: $period, aggregation_field: $aggregation_field, description: $description, query_version: $query_version, index_name: $index_name, unit: $unit, expected_version: $expected_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job. Requires permission to access the CreateJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /jobs/{jobId}
# Returns: record<jobArn: string, jobId: string, description: string>
# operationId: CreateJob
export def "create-job" [
  job_id: string
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
  targets: list<string> # A list of things and thing groups to which the job should be sent.
  --document-source: string # An S3 link to the job document. Required if you don't specify a value for document. If the job document resides in an S3 bucket, you must use a placeholder link when specifying the document. The placeholder link is of the following form: ${aws:iot:s3-presigned-url:https://s3.amazonaws.com/bucket/key} where bucket is your bucket name and key is the object in the bucket to which you are linking.
  --document: string # The job document. Required if you don't specify a value for documentSource.
  --description: string # A short text description of the job.
  --presigned-url-config: record # Configuration for pre-signed S3 URLs. — shape: {roleArn?: string, expiresInSec?: int}
  --target-selection: string@target-selection-completer # Specifies whether the job will continue to run (CONTINUOUS), or will be complete after all those things specified as targets have completed the job (SNAPSHOT). If continuous, the job may also be run on a thing when a change is detected in a target. For example, a job will run on a thing when the thing is added to a target group, even after the job was completed by all things originally in the group. We recommend that you use continuous jobs instead of snapshot jobs for dynamic thing group targets. By using continuous jobs, devices that join the group receive the job execution even after the job has been created.
  --job-executions-rollout-config: record # Allows you to create a staged rollout of a job. — shape: {maximumPerMinute?: int, exponentialRate?: record}
  --abort-config: record # The criteria that determine when and how a job abort takes place. — shape: {criteriaList?: list}
  --timeout-config: record # Specifies the amount of time each device has to finish its execution of the job. A timer is started when the job execution status is set to IN_PROGRESS. If the job execution status is not set to another terminal state before the timer expires, it will be automatically set to TIMED_OUT. — shape: {inProgressTimeoutInMinutes?: int}
  --tags: list # Metadata which can be used to manage the job. — item shape: {Key: string, Value?: string}
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --job-template-arn: string # The ARN of the job template used to create the job.
  --job-executions-retry-config: record # The configuration that determines how many retries are allowed for each failure type for a job. — shape: {criteriaList?: list}
  --document-parameters: record # Parameters of an Amazon Web Services managed template that you can specify to create the job document. documentParameters can only be used when creating jobs from Amazon Web Services managed templates. This parameter can't be used with custom job templates or to create jobs from them.
  --scheduling-config: record # Specifies the date and time that a job will begin the rollout of the job document to all devices in the target group. Additionally, you can specify the end behavior for each job execution when it reaches the scheduled end time. — shape: {startTime?: string, endTime?: string, endBehavior?: "STOP_ROLLOUT"|"CANCEL"|"FORCE_CANCEL", maintenanceWindows?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: targets, var: targets}, {name: documentSource, var: document_source}, {name: document, var: document}, {name: description, var: description}, {name: presignedUrlConfig, var: presigned_url_config}, {name: targetSelection, var: target_selection}, {name: jobExecutionsRolloutConfig, var: job_executions_rollout_config}, {name: abortConfig, var: abort_config}, {name: timeoutConfig, var: timeout_config}, {name: tags, var: tags}, {name: namespaceId, var: namespace_id}, {name: jobTemplateArn, var: job_template_arn}, {name: jobExecutionsRetryConfig, var: job_executions_retry_config}, {name: documentParameters, var: document_parameters}, {name: schedulingConfig, var: scheduling_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, targets: $targets, document_source: $document_source, document: $document, description: $description, presigned_url_config: $presigned_url_config, target_selection: $target_selection, job_executions_rollout_config: $job_executions_rollout_config, abort_config: $abort_config, timeout_config: $timeout_config, tags: $tags, namespace_id: $namespace_id, job_template_arn: $job_template_arn, job_executions_retry_config: $job_executions_retry_config, document_parameters: $document_parameters, scheduling_config: $scheduling_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a job and its related job executions. Deleting a job may take time, depending on the number of job executions created for the job and various other factors. While the job is being deleted, the status of the job will be shown as "DELETION_IN_PROGRESS". Attempting to delete or cancel a job whose status is already "DELETION_IN_PROGRESS" will result in an error. Only 10 jobs may have status "DELETION_IN_PROGRESS" at the same time, or a LimitExceededException will occur. Requires permission to access the DeleteJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /jobs/{jobId}
# operationId: DeleteJob
export def "delete-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # (Optional) When true, you can delete a job which is "IN_PROGRESS". Otherwise, you can only delete a job which is in a terminal state ("COMPLETED" or "CANCELED") or an exception will occur. The default is false. Deleting a job which is "IN_PROGRESS", will cause a device which is executing the job to be unable to access job information or update the job execution status. Use caution and ensure that each device executing a job which is deleted is able to recover to a valid state.
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: force, var: force}, {name: namespaceId, var: namespace_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, force: $force, namespace_id: $namespace_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a job. Requires permission to access the DescribeJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /jobs/{jobId}
# Returns: record<documentSource: string, job: record<jobArn: string, jobId: string, targetSelection: string, status: string, forceCanceled: bool, reasonCode: string, comment: string, targets: list<string>, description: string, presignedUrlConfig: record<roleArn: string, expiresInSec: int>, jobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record>, abortConfig: record<criteriaList: list>, createdAt: string, lastUpdatedAt: string, completedAt: string, jobProcessDetails: record<processingTargets: list, numberOfCanceledThings: int, numberOfSucceededThings: int, numberOfFailedThings: int, numberOfRejectedThings: int, numberOfQueuedThings: int, numberOfInProgressThings: int, numberOfRemovedThings: int, numberOfTimedOutThings: int>, timeoutConfig: record<inProgressTimeoutInMinutes: int>, namespaceId: string, jobTemplateArn: string, jobExecutionsRetryConfig: record<criteriaList: list>, documentParameters: record, isConcurrent: bool, schedulingConfig: record<startTime: string, endTime: string, endBehavior: string, maintenanceWindows: list>, scheduledJobRollouts: list<record>>>
# operationId: DescribeJob
export def "describe-job" [
  job_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates supported fields of the specified job. Requires permission to access the UpdateJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /jobs/{jobId}
# operationId: UpdateJob
export def "update-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A short text description of the job.
  --presigned-url-config: record # Configuration for pre-signed S3 URLs. — shape: {roleArn?: string, expiresInSec?: int}
  --job-executions-rollout-config: record # Allows you to create a staged rollout of a job. — shape: {maximumPerMinute?: int, exponentialRate?: record}
  --abort-config: record # The criteria that determine when and how a job abort takes place. — shape: {criteriaList?: list}
  --timeout-config: record # Specifies the amount of time each device has to finish its execution of the job. A timer is started when the job execution status is set to IN_PROGRESS. If the job execution status is not set to another terminal state before the timer expires, it will be automatically set to TIMED_OUT. — shape: {inProgressTimeoutInMinutes?: int}
  --job-executions-retry-config: record # The configuration that determines how many retries are allowed for each failure type for a job. — shape: {criteriaList?: list}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/jobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: namespaceId, var: namespace_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: presignedUrlConfig, var: presigned_url_config}, {name: jobExecutionsRolloutConfig, var: job_executions_rollout_config}, {name: abortConfig, var: abort_config}, {name: timeoutConfig, var: timeout_config}, {name: jobExecutionsRetryConfig, var: job_executions_retry_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, namespace_id: $namespace_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, presigned_url_config: $presigned_url_config, job_executions_rollout_config: $job_executions_rollout_config, abort_config: $abort_config, timeout_config: $timeout_config, job_executions_retry_config: $job_executions_retry_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job template. Requires permission to access the CreateJobTemplate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /job-templates/{jobTemplateId}
# Returns: record<jobTemplateArn: string, jobTemplateId: string>
# operationId: CreateJobTemplate
export def "create-job-template" [
  job_template_id: string
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
  --job-arn: string # The ARN of the job to use as the basis for the job template.
  --document-source: string # An S3 link to the job document to use in the template. Required if you don't specify a value for document. If the job document resides in an S3 bucket, you must use a placeholder link when specifying the document. The placeholder link is of the following form: ${aws:iot:s3-presigned-url:https://s3.amazonaws.com/bucket/key} where bucket is your bucket name and key is the object in the bucket to which you are linking.
  --document: string # The job document. Required if you don't specify a value for documentSource.
  description: string # A description of the job document.
  --presigned-url-config: record # Configuration for pre-signed S3 URLs. — shape: {roleArn?: string, expiresInSec?: int}
  --job-executions-rollout-config: record # Allows you to create a staged rollout of a job. — shape: {maximumPerMinute?: int, exponentialRate?: record}
  --abort-config: record # The criteria that determine when and how a job abort takes place. — shape: {criteriaList?: list}
  --timeout-config: record # Specifies the amount of time each device has to finish its execution of the job. A timer is started when the job execution status is set to IN_PROGRESS. If the job execution status is not set to another terminal state before the timer expires, it will be automatically set to TIMED_OUT. — shape: {inProgressTimeoutInMinutes?: int}
  --tags: list # Metadata that can be used to manage the job template. — item shape: {Key: string, Value?: string}
  --job-executions-retry-config: record # The configuration that determines how many retries are allowed for each failure type for a job. — shape: {criteriaList?: list}
  --maintenance-windows: list # Allows you to configure an optional maintenance window for the rollout of a job document to all devices in the target group for a job. — item shape: {startTime: string, durationInMinutes: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/job-templates/{jobTemplateId}"
    path_params: [{name: jobTemplateId, var: job_template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobArn, var: job_arn}, {name: documentSource, var: document_source}, {name: document, var: document}, {name: description, var: description}, {name: presignedUrlConfig, var: presigned_url_config}, {name: jobExecutionsRolloutConfig, var: job_executions_rollout_config}, {name: abortConfig, var: abort_config}, {name: timeoutConfig, var: timeout_config}, {name: tags, var: tags}, {name: jobExecutionsRetryConfig, var: job_executions_retry_config}, {name: maintenanceWindows, var: maintenance_windows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_template_id: $job_template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_arn: $job_arn, document_source: $document_source, document: $document, description: $description, presigned_url_config: $presigned_url_config, job_executions_rollout_config: $job_executions_rollout_config, abort_config: $abort_config, timeout_config: $timeout_config, tags: $tags, job_executions_retry_config: $job_executions_retry_config, maintenance_windows: $maintenance_windows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified job template.
#
# DELETE /job-templates/{jobTemplateId}
# operationId: DeleteJobTemplate
export def "delete-job-template" [
  job_template_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/job-templates/{jobTemplateId}"
    path_params: [{name: jobTemplateId, var: job_template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_template_id: $job_template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a job template.
#
# GET /job-templates/{jobTemplateId}
# Returns: record<jobTemplateArn: string, jobTemplateId: string, description: string, documentSource: string, document: string, createdAt: string, presignedUrlConfig: record<roleArn: string, expiresInSec: int>, jobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record<baseRatePerMinute: int, incrementFactor: float, rateIncreaseCriteria: record>>, abortConfig: record<criteriaList: list<record>>, timeoutConfig: record<inProgressTimeoutInMinutes: int>, jobExecutionsRetryConfig: record<criteriaList: list<record>>, maintenanceWindows: table<startTime: string, durationInMinutes: int>>
# operationId: DescribeJobTemplate
export def "describe-job-template" [
  job_template_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/job-templates/{jobTemplateId}"
    path_params: [{name: jobTemplateId, var: job_template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_template_id: $job_template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a 2048-bit RSA key pair and issues an X.509 certificate using the issued public key. You can also call CreateKeysAndCertificate over MQTT from a device, for more information, see Provisioning MQTT API (https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html#provision-mqtt-api). Note This is the only time IoT issues the private key for this certificate, so it is important to keep it in a secure location. Requires permission to access the CreateKeysAndCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /keys-and-certificate
# Returns: record<certificateArn: string, certificateId: string, certificatePem: string, keyPair: record<PublicKey: string, PrivateKey: string>>
# operationId: CreateKeysAndCertificate
export def "create-keys-and-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-active: oneof<nothing, bool> # Specifies whether the certificate is active.
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
    path: "/keys-and-certificate"
    query: [{name: setAsActive, var: set_as_active}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    set_as_active: $set_as_active, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defines an action that can be applied to audit findings by using StartAuditMitigationActionsTask. Only certain types of mitigation actions can be applied to specific check names. For more information, see Mitigation actions (https://docs.aws.amazon.com/iot/latest/developerguide/device-defender-mitigation-actions.html). Each mitigation action can apply only one type of change. Requires permission to access the CreateMitigationAction (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /mitigationactions/actions/{actionName}
# Returns: record<actionArn: string, actionId: string>
# operationId: CreateMitigationAction
export def "create-mitigation-action" [
  action_name: string
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
  role_arn: string # The ARN of the IAM role that is used to apply the mitigation action.
  action_params: record # The set of parameters for this mitigation action. You can specify only one type of parameter (in other words, you can apply only one action for each defined mitigation action). — shape: {updateDeviceCertificateParams?: record, updateCACertificateParams?: record, addThingsToThingGroupParams?: record, replaceDefaultPolicyVersionParams?: record, enableIoTLoggingParams?: record, publishFindingToSnsParams?: record}
  --tags: list # Metadata that can be used to manage the mitigation action. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mitigationactions/actions/{actionName}"
    path_params: [{name: actionName, var: action_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: actionParams, var: action_params}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_name: $action_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, action_params: $action_params, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a defined mitigation action from your Amazon Web Services accounts. Requires permission to access the DeleteMitigationAction (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /mitigationactions/actions/{actionName}
# Returns: record
# operationId: DeleteMitigationAction
export def "delete-mitigation-action" [
  action_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/mitigationactions/actions/{actionName}"
    path_params: [{name: actionName, var: action_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_name: $action_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a mitigation action. Requires permission to access the DescribeMitigationAction (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /mitigationactions/actions/{actionName}
# Returns: record<actionName: string, actionType: string, actionArn: string, actionId: string, roleArn: string, actionParams: record<updateDeviceCertificateParams: record<action: string>, updateCACertificateParams: record<action: string>, addThingsToThingGroupParams: record<thingGroupNames: list, overrideDynamicGroups: bool>, replaceDefaultPolicyVersionParams: record<templateName: string>, enableIoTLoggingParams: record<roleArnForLogging: string, logLevel: string>, publishFindingToSnsParams: record<topicArn: string>>, creationDate: string, lastModifiedDate: string>
# operationId: DescribeMitigationAction
export def "describe-mitigation-action" [
  action_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mitigationactions/actions/{actionName}"
    path_params: [{name: actionName, var: action_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_name: $action_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the definition for the specified mitigation action. Requires permission to access the UpdateMitigationAction (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /mitigationactions/actions/{actionName}
# Returns: record<actionArn: string, actionId: string>
# operationId: UpdateMitigationAction
export def "update-mitigation-action" [
  action_name: string
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
  --role-arn: string # The ARN of the IAM role that is used to apply the mitigation action.
  --action-params: record # The set of parameters for this mitigation action. You can specify only one type of parameter (in other words, you can apply only one action for each defined mitigation action). — shape: {updateDeviceCertificateParams?: record, updateCACertificateParams?: record, addThingsToThingGroupParams?: record, replaceDefaultPolicyVersionParams?: record, enableIoTLoggingParams?: record, publishFindingToSnsParams?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mitigationactions/actions/{actionName}"
    path_params: [{name: actionName, var: action_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: actionParams, var: action_params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_name: $action_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, action_params: $action_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an IoT OTA update on a target group of things or groups. Requires permission to access the CreateOTAUpdate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /otaUpdates/{otaUpdateId}
# Returns: record<otaUpdateId: string, awsIotJobId: string, otaUpdateArn: string, awsIotJobArn: string, otaUpdateStatus: string>
# operationId: CreateOTAUpdate
export def "create-ota-update" [
  ota_update_id: string
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
  --description: string # The description of the OTA update.
  targets: list<string> # The devices targeted to receive OTA updates.
  --protocols: list<string> # The protocol used to transfer the OTA update image. Valid values are [HTTP], [MQTT], [HTTP, MQTT]. When both HTTP and MQTT are specified, the target device can choose the protocol.
  --target-selection: string@target-selection-completer # Specifies whether the update will continue to run (CONTINUOUS), or will be complete after all the things specified as targets have completed the update (SNAPSHOT). If continuous, the update may also be run on a thing when a change is detected in a target. For example, an update will run on a thing when the thing is added to a target group, even after the update was completed by all things originally in the group. Valid values: CONTINUOUS | SNAPSHOT.
  --aws-job-executions-rollout-config: record # Configuration for the rollout of OTA updates. — shape: {maximumPerMinute?: int, exponentialRate?: record}
  --aws-job-presigned-url-config: record # Configuration information for pre-signed URLs. Valid when protocols contains HTTP. — shape: {expiresInSec?: int}
  --aws-job-abort-config: record # The criteria that determine when and how a job abort takes place. — shape: {abortCriteriaList?: list}
  --aws-job-timeout-config: record # Specifies the amount of time each device has to finish its execution of the job. A timer is started when the job execution status is set to IN_PROGRESS. If the job execution status is not set to another terminal state before the timer expires, it will be automatically set to TIMED_OUT. — shape: {inProgressTimeoutInMinutes?: int}
  files: list # The files to be streamed by the OTA update. — item shape: {fileName?: string, fileType?: int, fileVersion?: string, fileLocation?: record, codeSigning?: record, attributes?: record}
  role_arn: string # The IAM role that grants Amazon Web Services IoT Core access to the Amazon S3, IoT jobs and Amazon Web Services Code Signing resources to create an OTA update job.
  --additional-parameters: record # A list of additional OTA update parameters which are name-value pairs.
  --tags: list # Metadata which can be used to manage updates. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/otaUpdates/{otaUpdateId}"
    path_params: [{name: otaUpdateId, var: ota_update_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: targets, var: targets}, {name: protocols, var: protocols}, {name: targetSelection, var: target_selection}, {name: awsJobExecutionsRolloutConfig, var: aws_job_executions_rollout_config}, {name: awsJobPresignedUrlConfig, var: aws_job_presigned_url_config}, {name: awsJobAbortConfig, var: aws_job_abort_config}, {name: awsJobTimeoutConfig, var: aws_job_timeout_config}, {name: files, var: files}, {name: roleArn, var: role_arn}, {name: additionalParameters, var: additional_parameters}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ota_update_id: $ota_update_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, targets: $targets, protocols: $protocols, target_selection: $target_selection, aws_job_executions_rollout_config: $aws_job_executions_rollout_config, aws_job_presigned_url_config: $aws_job_presigned_url_config, aws_job_abort_config: $aws_job_abort_config, aws_job_timeout_config: $aws_job_timeout_config, files: $files, role_arn: $role_arn, additional_parameters: $additional_parameters, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an OTA update. Requires permission to access the DeleteOTAUpdate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /otaUpdates/{otaUpdateId}
# Returns: record
# operationId: DeleteOTAUpdate
export def "delete-ota-update" [
  ota_update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-stream: oneof<nothing, bool> # When true, the stream created by the OTAUpdate process is deleted when the OTA update is deleted. Ignored if the stream specified in the OTAUpdate is supplied by the user.
  --force-delete-aws-job: oneof<nothing, bool> # When true, deletes the IoT job created by the OTAUpdate process even if it is "IN_PROGRESS". Otherwise, if the job is not in a terminal state ("COMPLETED" or "CANCELED") an exception will occur. The default is false.
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
    path: "/otaUpdates/{otaUpdateId}"
    path_params: [{name: otaUpdateId, var: ota_update_id}]
    query: [{name: deleteStream, var: delete_stream}, {name: forceDeleteAWSJob, var: force_delete_aws_job}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ota_update_id: $ota_update_id, delete_stream: $delete_stream, force_delete_aws_job: $force_delete_aws_job, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an OTA update. Requires permission to access the GetOTAUpdate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /otaUpdates/{otaUpdateId}
# Returns: record<otaUpdateInfo: record<otaUpdateId: string, otaUpdateArn: string, creationDate: string, lastModifiedDate: string, description: string, targets: list<string>, protocols: list<string>, awsJobExecutionsRolloutConfig: record<maximumPerMinute: int, exponentialRate: record>, awsJobPresignedUrlConfig: record<expiresInSec: int>, targetSelection: string, otaUpdateFiles: list<record>, otaUpdateStatus: string, awsIotJobId: string, awsIotJobArn: string, errorInfo: record<code: string, message: string>, additionalParameters: record>>
# operationId: GetOTAUpdate
export def "get-ota-update" [
  ota_update_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/otaUpdates/{otaUpdateId}"
    path_params: [{name: otaUpdateId, var: ota_update_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ota_update_id: $ota_update_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an IoT policy. The created policy is the default version for the policy. This operation creates a policy version with a version identifier of 1 and sets 1 as the policy's default version. Requires permission to access the CreatePolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /policies/{policyName}
# Returns: record<policyName: string, policyArn: string, policyDocument: string, policyVersionId: string>
# operationId: CreatePolicy
export def "create-policy" [
  policy_name: string
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
  policy_document: string # The JSON document that describes the policy. policyDocument must have a minimum length of 1, with a maximum length of 2048, excluding whitespace.
  --tags: list # Metadata which can be used to manage the policy. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: policyDocument, var: policy_document}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy_document: $policy_document, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified policy. A policy cannot be deleted if it has non-default versions or it is attached to any certificate. To delete a policy, use the DeletePolicyVersion action to delete all non-default versions of the policy; use the DetachPolicy action to detach the policy from any certificate; and then use the DeletePolicy action to delete the policy. When a policy is deleted using DeletePolicy, its default version is deleted with it. Because of the distributed nature of Amazon Web Services, it can take up to five minutes after a policy is detached before it's ready to be deleted. Requires permission to access the DeletePolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /policies/{policyName}
# operationId: DeletePolicy
export def "delete-policy" [
  policy_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified policy with the policy document of the default version. Requires permission to access the GetPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /policies/{policyName}
# Returns: record<policyName: string, policyArn: string, policyDocument: string, defaultVersionId: string, creationDate: string, lastModifiedDate: string, generationId: string>
# operationId: GetPolicy
export def "get-policy" [
  policy_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/policies/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of the specified IoT policy. To update a policy, create a new policy version. A managed policy can have up to five versions. If the policy has five versions, you must use DeletePolicyVersion to delete an existing version before you create a new one. Optionally, you can set the new version as the policy's default version. The default version is the operative version (that is, the version that is in effect for the certificates to which the policy is attached). Requires permission to access the CreatePolicyVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /policies/{policyName}/version
# Returns: record<policyArn: string, policyDocument: string, policyVersionId: string, isDefaultVersion: bool>
# operationId: CreatePolicyVersion
export def "create-policy-version" [
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-default: oneof<nothing, bool> # Specifies whether the policy version is set as the default. When this parameter is true, the new policy version becomes the operative version (that is, the version that is in effect for the certificates to which the policy is attached).
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  policy_document: string # The JSON document that describes the policy. Minimum length of 1. Maximum length of 2048, excluding whitespace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policies/{policyName}/version"
    path_params: [{name: policyName, var: policy_name}]
    query: [{name: setAsDefault, var: set_as_default}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: policyDocument, var: policy_document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, set_as_default: $set_as_default, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy_document: $policy_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the versions of the specified policy and identifies the default version. Requires permission to access the ListPolicyVersions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /policies/{policyName}/version
# Returns: record<policyVersions: table<versionId: string, isDefaultVersion: bool, createDate: string>>
# operationId: ListPolicyVersions
export def "list-policy-versions" [
  policy_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/policies/{policyName}/version"
    path_params: [{name: policyName, var: policy_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a provisioning claim. Requires permission to access the CreateProvisioningClaim (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /provisioning-templates/{templateName}/provisioning-claim
# Returns: record<certificateId: string, certificatePem: string, keyPair: record<PublicKey: string, PrivateKey: string>, expiration: string>
# operationId: CreateProvisioningClaim
export def "create-provisioning-claim" [
  template_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/provisioning-templates/{templateName}/provisioning-claim"
    path_params: [{name: templateName, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a provisioning template. Requires permission to access the CreateProvisioningTemplate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /provisioning-templates
# Returns: record<templateArn: string, templateName: string, defaultVersionId: int>
# operationId: CreateProvisioningTemplate
export def "create-provisioning-template" [
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
  template_name: string # The name of the provisioning template.
  --description: string # The description of the provisioning template.
  template_body: string # The JSON formatted contents of the provisioning template.
  --enabled: oneof<nothing, bool> # True to enable the provisioning template, otherwise false.
  provisioning_role_arn: string # The role ARN for the role associated with the provisioning template. This IoT role grants permission to provision a device.
  --pre-provisioning-hook: record # Structure that contains payloadVersion and targetArn. — shape: {payloadVersion?: string, targetArn?: string}
  --tags: list # Metadata which can be used to manage the provisioning template. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
  --type: string@type-completer-1 # The type you define in a provisioning template. You can create a template with only one type. You can't change the template type after its creation. The default value is FLEET_PROVISIONING. For more information about provisioning template, see: Provisioning template (https://docs.aws.amazon.com/iot/latest/developerguide/provision-template.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/provisioning-templates"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateName, var: template_name}, {name: description, var: description}, {name: templateBody, var: template_body}, {name: enabled, var: enabled}, {name: provisioningRoleArn, var: provisioning_role_arn}, {name: preProvisioningHook, var: pre_provisioning_hook}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_name: $template_name, description: $description, template_body: $template_body, enabled: $enabled, provisioning_role_arn: $provisioning_role_arn, pre_provisioning_hook: $pre_provisioning_hook, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the provisioning templates in your Amazon Web Services account. Requires permission to access the ListProvisioningTemplates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /provisioning-templates
# Returns: record<templates: table<templateArn: string, templateName: string, description: string, creationDate: string, lastModifiedDate: string, enabled: bool, type: string>, nextToken: string>
# operationId: ListProvisioningTemplates
export def "list-provisioning-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at one time.
  --next-token: string # A token to retrieve the next set of results.
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
    path: "/provisioning-templates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new version of a provisioning template. Requires permission to access the CreateProvisioningTemplateVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /provisioning-templates/{templateName}/versions
# Returns: record<templateArn: string, templateName: string, versionId: int, isDefaultVersion: bool>
# operationId: CreateProvisioningTemplateVersion
export def "create-provisioning-template-version" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-default: oneof<nothing, bool> # Sets a fleet provision template version as the default version.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template_body: string # The JSON formatted contents of the provisioning template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/provisioning-templates/{templateName}/versions"
    path_params: [{name: templateName, var: template_name}]
    query: [{name: setAsDefault, var: set_as_default}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateBody, var: template_body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, set_as_default: $set_as_default, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_body: $template_body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of provisioning template versions. Requires permission to access the ListProvisioningTemplateVersions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /provisioning-templates/{templateName}/versions
# Returns: record<versions: table<versionId: int, creationDate: string, isDefaultVersion: bool>, nextToken: string>
# operationId: ListProvisioningTemplateVersions
export def "list-provisioning-template-versions" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at one time.
  --next-token: string # A token to retrieve the next set of results.
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
    path: "/provisioning-templates/{templateName}/versions"
    path_params: [{name: templateName, var: template_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a role alias. Requires permission to access the CreateRoleAlias (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /role-aliases/{roleAlias}
# Returns: record<roleAlias: string, roleAliasArn: string>
# operationId: CreateRoleAlias
export def "create-role-alias" [
  role_alias: string
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
  role_arn: string # The role ARN.
  --credential-duration-seconds: int # How long (in seconds) the credentials will be valid. The default value is 3,600 seconds. This value must be less than or equal to the maximum session duration of the IAM role that the role alias references.
  --tags: list # Metadata which can be used to manage the role alias. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/role-aliases/{roleAlias}"
    path_params: [{name: roleAlias, var: role_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: credentialDurationSeconds, var: credential_duration_seconds}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_alias: $role_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, credential_duration_seconds: $credential_duration_seconds, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a role alias Requires permission to access the DeleteRoleAlias (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /role-aliases/{roleAlias}
# Returns: record
# operationId: DeleteRoleAlias
export def "delete-role-alias" [
  role_alias: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/role-aliases/{roleAlias}"
    path_params: [{name: roleAlias, var: role_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_alias: $role_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a role alias. Requires permission to access the DescribeRoleAlias (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /role-aliases/{roleAlias}
# Returns: record<roleAliasDescription: record<roleAlias: string, roleAliasArn: string, roleArn: string, owner: string, credentialDurationSeconds: int, creationDate: string, lastModifiedDate: string>>
# operationId: DescribeRoleAlias
export def "describe-role-alias" [
  role_alias: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/role-aliases/{roleAlias}"
    path_params: [{name: roleAlias, var: role_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_alias: $role_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a role alias. Requires permission to access the UpdateRoleAlias (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /role-aliases/{roleAlias}
# Returns: record<roleAlias: string, roleAliasArn: string>
# operationId: UpdateRoleAlias
export def "update-role-alias" [
  role_alias: string
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
  --role-arn: string # The role ARN.
  --credential-duration-seconds: int # The number of seconds the credential will be valid. This value must be less than or equal to the maximum session duration of the IAM role that the role alias references.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/role-aliases/{roleAlias}"
    path_params: [{name: roleAlias, var: role_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: credentialDurationSeconds, var: credential_duration_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_alias: $role_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, credential_duration_seconds: $credential_duration_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a scheduled audit that is run at a specified time interval. Requires permission to access the CreateScheduledAudit (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/scheduledaudits/{scheduledAuditName}
# Returns: record<scheduledAuditArn: string>
# operationId: CreateScheduledAudit
export def "create-scheduled-audit" [
  scheduled_audit_name: string
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
  frequency: string@frequency-completer # How often the scheduled audit takes place, either DAILY, WEEKLY, BIWEEKLY or MONTHLY. The start time of each audit is determined by the system.
  --day-of-month: string # The day of the month on which the scheduled audit takes place. This can be "1" through "31" or "LAST". This field is required if the "frequency" parameter is set to MONTHLY. If days 29 to 31 are specified, and the month doesn't have that many days, the audit takes place on the LAST day of the month.
  --day-of-week: string@day-of-week-completer # The day of the week on which the scheduled audit takes place, either SUN, MON, TUE, WED, THU, FRI, or SAT. This field is required if the frequency parameter is set to WEEKLY or BIWEEKLY.
  target_check_names: list<string> # Which checks are performed during the scheduled audit. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  --tags: list # Metadata that can be used to manage the scheduled audit. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/scheduledaudits/{scheduledAuditName}"
    path_params: [{name: scheduledAuditName, var: scheduled_audit_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: frequency, var: frequency}, {name: dayOfMonth, var: day_of_month}, {name: dayOfWeek, var: day_of_week}, {name: targetCheckNames, var: target_check_names}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheduled_audit_name: $scheduled_audit_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, frequency: $frequency, day_of_month: $day_of_month, day_of_week: $day_of_week, target_check_names: $target_check_names, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a scheduled audit. Requires permission to access the DeleteScheduledAudit (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /audit/scheduledaudits/{scheduledAuditName}
# Returns: record
# operationId: DeleteScheduledAudit
export def "delete-scheduled-audit" [
  scheduled_audit_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/audit/scheduledaudits/{scheduledAuditName}"
    path_params: [{name: scheduledAuditName, var: scheduled_audit_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheduled_audit_name: $scheduled_audit_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a scheduled audit. Requires permission to access the DescribeScheduledAudit (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/scheduledaudits/{scheduledAuditName}
# Returns: record<frequency: string, dayOfMonth: string, dayOfWeek: string, targetCheckNames: list<string>, scheduledAuditName: string, scheduledAuditArn: string>
# operationId: DescribeScheduledAudit
export def "describe-scheduled-audit" [
  scheduled_audit_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audit/scheduledaudits/{scheduledAuditName}"
    path_params: [{name: scheduledAuditName, var: scheduled_audit_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheduled_audit_name: $scheduled_audit_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a scheduled audit, including which checks are performed and how often the audit takes place. Requires permission to access the UpdateScheduledAudit (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /audit/scheduledaudits/{scheduledAuditName}
# Returns: record<scheduledAuditArn: string>
# operationId: UpdateScheduledAudit
export def "update-scheduled-audit" [
  scheduled_audit_name: string
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
  --frequency: string@frequency-completer # How often the scheduled audit takes place, either DAILY, WEEKLY, BIWEEKLY, or MONTHLY. The start time of each audit is determined by the system.
  --day-of-month: string # The day of the month on which the scheduled audit takes place. This can be 1 through 31 or LAST. This field is required if the frequency parameter is set to MONTHLY. If days 29-31 are specified, and the month does not have that many days, the audit takes place on the "LAST" day of the month.
  --day-of-week: string@day-of-week-completer # The day of the week on which the scheduled audit takes place. This can be one of SUN, MON, TUE, WED, THU, FRI, or SAT. This field is required if the "frequency" parameter is set to WEEKLY or BIWEEKLY.
  --target-check-names: list<string> # Which checks are performed during the scheduled audit. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/audit/scheduledaudits/{scheduledAuditName}"
    path_params: [{name: scheduledAuditName, var: scheduled_audit_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: frequency, var: frequency}, {name: dayOfMonth, var: day_of_month}, {name: dayOfWeek, var: day_of_week}, {name: targetCheckNames, var: target_check_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scheduled_audit_name: $scheduled_audit_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, frequency: $frequency, day_of_month: $day_of_month, day_of_week: $day_of_week, target_check_names: $target_check_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Device Defender security profile. Requires permission to access the CreateSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /security-profiles/{securityProfileName}
# Returns: record<securityProfileName: string, securityProfileArn: string>
# operationId: CreateSecurityProfile
export def "create-security-profile" [
  security_profile_name: string
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
  --security-profile-description: string # A description of the security profile.
  --behaviors: list # Specifies the behaviors that, when violated by a device (thing), cause an alert. — item shape: {name: string, metric?: string, metricDimension?: record, criteria?: record, suppressAlerts?: bool}
  --alert-targets: record # Specifies the destinations to which alerts are sent. (Alerts are always sent to the console.) Alerts are generated when a device (thing) violates a behavior.
  --additional-metrics-to-retain: list<string> # Please use CreateSecurityProfileRequest$additionalMetricsToRetainV2 instead. A list of metrics whose data is retained (stored). By default, data is retained for any metric used in the profile's behaviors, but it is also retained for any metric specified here. Can be used with custom metrics; cannot be used with dimensions.
  --additional-metrics-to-retain-v2: list # A list of metrics whose data is retained (stored). By default, data is retained for any metric used in the profile's behaviors, but it is also retained for any metric specified here. Can be used with custom metrics; cannot be used with dimensions. — item shape: {metric: string, metricDimension?: record}
  --tags: list # Metadata that can be used to manage the security profile. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/security-profiles/{securityProfileName}"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: securityProfileDescription, var: security_profile_description}, {name: behaviors, var: behaviors}, {name: alertTargets, var: alert_targets}, {name: additionalMetricsToRetain, var: additional_metrics_to_retain}, {name: additionalMetricsToRetainV2, var: additional_metrics_to_retain_v2}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, security_profile_description: $security_profile_description, behaviors: $behaviors, alert_targets: $alert_targets, additional_metrics_to_retain: $additional_metrics_to_retain, additional_metrics_to_retain_v2: $additional_metrics_to_retain_v2, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Device Defender security profile. Requires permission to access the DeleteSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /security-profiles/{securityProfileName}
# Returns: record
# operationId: DeleteSecurityProfile
export def "delete-security-profile" [
  security_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the security profile. A new version is generated whenever the security profile is updated. If you specify a value that is different from the actual version, a VersionConflictException is thrown.
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
    path: "/security-profiles/{securityProfileName}"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Device Defender security profile. Requires permission to access the DescribeSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /security-profiles/{securityProfileName}
# Returns: record<securityProfileName: string, securityProfileArn: string, securityProfileDescription: string, behaviors: table<name: string, metric: string, metricDimension: record, criteria: record, suppressAlerts: bool>, alertTargets: record, additionalMetricsToRetain: list<string>, additionalMetricsToRetainV2: table<metric: string, metricDimension: record>, version: int, creationDate: string, lastModifiedDate: string>
# operationId: DescribeSecurityProfile
export def "describe-security-profile" [
  security_profile_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/security-profiles/{securityProfileName}"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Device Defender security profile. Requires permission to access the UpdateSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /security-profiles/{securityProfileName}
# Returns: record<securityProfileName: string, securityProfileArn: string, securityProfileDescription: string, behaviors: table<name: string, metric: string, metricDimension: record, criteria: record, suppressAlerts: bool>, alertTargets: record, additionalMetricsToRetain: list<string>, additionalMetricsToRetainV2: table<metric: string, metricDimension: record>, version: int, creationDate: string, lastModifiedDate: string>
# operationId: UpdateSecurityProfile
export def "update-security-profile" [
  security_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the security profile. A new version is generated whenever the security profile is updated. If you specify a value that is different from the actual version, a VersionConflictException is thrown.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --security-profile-description: string # A description of the security profile.
  --behaviors: list # Specifies the behaviors that, when violated by a device (thing), cause an alert. — item shape: {name: string, metric?: string, metricDimension?: record, criteria?: record, suppressAlerts?: bool}
  --alert-targets: record # Where the alerts are sent. (Alerts are always sent to the console.)
  --additional-metrics-to-retain: list<string> # Please use UpdateSecurityProfileRequest$additionalMetricsToRetainV2 instead. A list of metrics whose data is retained (stored). By default, data is retained for any metric used in the profile's behaviors, but it is also retained for any metric specified here. Can be used with custom metrics; cannot be used with dimensions.
  --additional-metrics-to-retain-v2: list # A list of metrics whose data is retained (stored). By default, data is retained for any metric used in the profile's behaviors, but it is also retained for any metric specified here. Can be used with custom metrics; cannot be used with dimensions. — item shape: {metric: string, metricDimension?: record}
  --delete-behaviors: oneof<nothing, bool> # If true, delete all behaviors defined for this security profile. If any behaviors are defined in the current invocation, an exception occurs.
  --delete-alert-targets: oneof<nothing, bool> # If true, delete all alertTargets defined for this security profile. If any alertTargets are defined in the current invocation, an exception occurs.
  --delete-additional-metrics-to-retain: oneof<nothing, bool> # If true, delete all additionalMetricsToRetain defined for this security profile. If any additionalMetricsToRetain are defined in the current invocation, an exception occurs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/security-profiles/{securityProfileName}"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: securityProfileDescription, var: security_profile_description}, {name: behaviors, var: behaviors}, {name: alertTargets, var: alert_targets}, {name: additionalMetricsToRetain, var: additional_metrics_to_retain}, {name: additionalMetricsToRetainV2, var: additional_metrics_to_retain_v2}, {name: deleteBehaviors, var: delete_behaviors}, {name: deleteAlertTargets, var: delete_alert_targets}, {name: deleteAdditionalMetricsToRetain, var: delete_additional_metrics_to_retain}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, security_profile_description: $security_profile_description, behaviors: $behaviors, alert_targets: $alert_targets, additional_metrics_to_retain: $additional_metrics_to_retain, additional_metrics_to_retain_v2: $additional_metrics_to_retain_v2, delete_behaviors: $delete_behaviors, delete_alert_targets: $delete_alert_targets, delete_additional_metrics_to_retain: $delete_additional_metrics_to_retain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a stream for delivering one or more large files in chunks over MQTT. A stream transports data bytes in chunks or blocks packaged as MQTT messages from a source like S3. You can have one or more files associated with a stream. Requires permission to access the CreateStream (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /streams/{streamId}
# Returns: record<streamId: string, streamArn: string, description: string, streamVersion: int>
# operationId: CreateStream
export def "create-stream" [
  stream_id: string
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
  --description: string # A description of the stream.
  files: list # The files to stream. — item shape: {fileId?: int, s3Location?: record}
  role_arn: string # An IAM role that allows the IoT service principal to access your S3 files.
  --tags: list # Metadata which can be used to manage streams. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/streams/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: files, var: files}, {name: roleArn, var: role_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_id: $stream_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, files: $files, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a stream. Requires permission to access the DeleteStream (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /streams/{streamId}
# Returns: record
# operationId: DeleteStream
export def "delete-stream" [
  stream_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/streams/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_id: $stream_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a stream. Requires permission to access the DescribeStream (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /streams/{streamId}
# Returns: record<streamInfo: record<streamId: string, streamArn: string, streamVersion: int, description: string, files: list<record>, createdAt: string, lastUpdatedAt: string, roleArn: string>>
# operationId: DescribeStream
export def "describe-stream" [
  stream_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/streams/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_id: $stream_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing stream. The stream version will be incremented by one. Requires permission to access the UpdateStream (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /streams/{streamId}
# Returns: record<streamId: string, streamArn: string, description: string, streamVersion: int>
# operationId: UpdateStream
export def "update-stream" [
  stream_id: string
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
  --description: string # The description of the stream.
  --files: list # The files associated with the stream. — item shape: {fileId?: int, s3Location?: record}
  --role-arn: string # An IAM role that allows the IoT service principal assumes to access your S3 files.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/streams/{streamId}"
    path_params: [{name: streamId, var: stream_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: files, var: files}, {name: roleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_id: $stream_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, files: $files, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a thing record in the registry. If this call is made multiple times using the same thing name and configuration, the call will succeed. If this call is made with the same thing name but different configuration a ResourceAlreadyExistsException is thrown. This is a control plane operation. See Authorization (https://docs.aws.amazon.com/iot/latest/developerguide/iot-authorization.html) for information about authorizing control plane actions. Requires permission to access the CreateThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /things/{thingName}
# Returns: record<thingName: string, thingArn: string, thingId: string>
# operationId: CreateThing
export def "create-thing" [
  thing_name: string
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
  --thing-type-name: string # The name of the thing type associated with the new thing.
  --attribute-payload: record # The attribute payload. — shape: {attributes?: record, merge?: bool}
  --billing-group-name: string # The name of the billing group the thing will be added to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/things/{thingName}"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingTypeName, var: thing_type_name}, {name: attributePayload, var: attribute_payload}, {name: billingGroupName, var: billing_group_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_type_name: $thing_type_name, attribute_payload: $attribute_payload, billing_group_name: $billing_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified thing. Returns successfully with no error if the deletion is successful or you specify a thing that doesn't exist. Requires permission to access the DeleteThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /things/{thingName}
# Returns: record
# operationId: DeleteThing
export def "delete-thing" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the thing record in the registry. If the version of the record in the registry does not match the expected version specified in the request, the DeleteThing request is rejected with a VersionConflictException.
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
    path: "/things/{thingName}"
    path_params: [{name: thingName, var: thing_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified thing. Requires permission to access the DescribeThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /things/{thingName}
# Returns: record<defaultClientId: string, thingName: string, thingId: string, thingArn: string, thingTypeName: string, attributes: record, version: int, billingGroupName: string>
# operationId: DescribeThing
export def "describe-thing" [
  thing_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/things/{thingName}"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the data for a thing. Requires permission to access the UpdateThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /things/{thingName}
# Returns: record
# operationId: UpdateThing
export def "update-thing" [
  thing_name: string
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
  --thing-type-name: string # The name of the thing type.
  --attribute-payload: record # The attribute payload. — shape: {attributes?: record, merge?: bool}
  --expected-version: int # The expected version of the thing record in the registry. If the version of the record in the registry does not match the expected version specified in the request, the UpdateThing request is rejected with a VersionConflictException.
  --remove-thing-type: oneof<nothing, bool> # Remove a thing type association. If true, the association is removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/things/{thingName}"
    path_params: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingTypeName, var: thing_type_name}, {name: attributePayload, var: attribute_payload}, {name: expectedVersion, var: expected_version}, {name: removeThingType, var: remove_thing_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_type_name: $thing_type_name, attribute_payload: $attribute_payload, expected_version: $expected_version, remove_thing_type: $remove_thing_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a thing group. This is a control plane operation. See Authorization (https://docs.aws.amazon.com/iot/latest/developerguide/iot-authorization.html) for information about authorizing control plane actions. Requires permission to access the CreateThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /thing-groups/{thingGroupName}
# Returns: record<thingGroupName: string, thingGroupArn: string, thingGroupId: string>
# operationId: CreateThingGroup
export def "create-thing-group" [
  thing_group_name: string
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
  --parent-group-name: string # The name of the parent thing group.
  --thing-group-properties: record # Thing group properties. — shape: {thingGroupDescription?: string, attributePayload?: record}
  --tags: list # Metadata which can be used to manage the thing group. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: parentGroupName, var: parent_group_name}, {name: thingGroupProperties, var: thing_group_properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, parent_group_name: $parent_group_name, thing_group_properties: $thing_group_properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a thing group. Requires permission to access the DeleteThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /thing-groups/{thingGroupName}
# Returns: record
# operationId: DeleteThingGroup
export def "delete-thing-group" [
  thing_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-version: int # The expected version of the thing group to delete.
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
    path: "/thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    query: [{name: expectedVersion, var: expected_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, expected_version: $expected_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe a thing group. Requires permission to access the DescribeThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-groups/{thingGroupName}
# Returns: record<thingGroupName: string, thingGroupId: string, thingGroupArn: string, version: int, thingGroupProperties: record<thingGroupDescription: string, attributePayload: record<attributes: record, merge: bool>>, thingGroupMetadata: record<parentGroupName: string, rootToParentThingGroups: list<record>, creationDate: string>, indexName: string, queryString: string, queryVersion: string, status: string>
# operationId: DescribeThingGroup
export def "describe-thing-group" [
  thing_group_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a thing group. Requires permission to access the UpdateThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /thing-groups/{thingGroupName}
# Returns: record<version: int>
# operationId: UpdateThingGroup
export def "update-thing-group" [
  thing_group_name: string
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
  thing_group_properties: record # Thing group properties. — shape: {thingGroupDescription?: string, attributePayload?: record}
  --expected-version: int # The expected version of the thing group. If this does not match the version of the thing group being updated, the update will fail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/thing-groups/{thingGroupName}"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingGroupProperties, var: thing_group_properties}, {name: expectedVersion, var: expected_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_group_properties: $thing_group_properties, expected_version: $expected_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new thing type. Requires permission to access the CreateThingType (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /thing-types/{thingTypeName}
# Returns: record<thingTypeName: string, thingTypeArn: string, thingTypeId: string>
# operationId: CreateThingType
export def "create-thing-type" [
  thing_type_name: string
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
  --thing-type-properties: record # The ThingTypeProperties contains information about the thing type including: a thing type description, and a list of searchable thing attribute names. — shape: {thingTypeDescription?: string, searchableAttributes?: list<string>}
  --tags: list # Metadata which can be used to manage the thing type. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/thing-types/{thingTypeName}"
    path_params: [{name: thingTypeName, var: thing_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingTypeProperties, var: thing_type_properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_type_name: $thing_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_type_properties: $thing_type_properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified thing type. You cannot delete a thing type if it has things associated with it. To delete a thing type, first mark it as deprecated by calling DeprecateThingType, then remove any associated things by calling UpdateThing to change the thing type on any associated thing, and finally use DeleteThingType to delete the thing type. Requires permission to access the DeleteThingType (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /thing-types/{thingTypeName}
# Returns: record
# operationId: DeleteThingType
export def "delete-thing-type" [
  thing_type_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/thing-types/{thingTypeName}"
    path_params: [{name: thingTypeName, var: thing_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_type_name: $thing_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified thing type. Requires permission to access the DescribeThingType (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-types/{thingTypeName}
# Returns: record<thingTypeName: string, thingTypeId: string, thingTypeArn: string, thingTypeProperties: record<thingTypeDescription: string, searchableAttributes: list<string>>, thingTypeMetadata: record<deprecated: bool, deprecationDate: string, creationDate: string>>
# operationId: DescribeThingType
export def "describe-thing-type" [
  thing_type_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/thing-types/{thingTypeName}"
    path_params: [{name: thingTypeName, var: thing_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_type_name: $thing_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a rule. Creating rules is an administrator-level action. Any user who has permission to create rules will be able to access data processed by the rule. Requires permission to access the CreateTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /rules/{ruleName}
# operationId: CreateTopicRule
export def "create-topic-rule" [
  rule_name: string
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
  --x-amz-tagging: string # Metadata which can be used to manage the topic rule. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: --tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..."
  topic_rule_payload: record # Describes a rule. — shape: {sql?: string, description?: string, actions?: list, ruleDisabled?: bool, awsIotSqlVersion?: string, errorAction?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/rules/{ruleName}"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amz-tagging, var: x_amz_tagging}]
    body: {content_type: "application/json", kind: json, fields: [{name: topicRulePayload, var: topic_rule_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_tagging: $x_amz_tagging, topic_rule_payload: $topic_rule_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the rule. Requires permission to access the DeleteTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /rules/{ruleName}
# operationId: DeleteTopicRule
export def "delete-topic-rule" [
  rule_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/rules/{ruleName}"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the rule. Requires permission to access the GetTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /rules/{ruleName}
# Returns: record<ruleArn: string, rule: record<ruleName: string, sql: string, description: string, createdAt: string, actions: list<record>, ruleDisabled: bool, awsIotSqlVersion: string, errorAction: record<dynamoDB: record, dynamoDBv2: record, lambda: record, sns: record, sqs: record, kinesis: record, republish: record, s3: record, firehose: record, cloudwatchMetric: record, cloudwatchAlarm: record, cloudwatchLogs: record, elasticsearch: record, salesforce: record, iotAnalytics: record, iotEvents: record, iotSiteWise: record, stepFunctions: record, timestream: record, http: record, kafka: record, openSearch: record, location: record>>>
# operationId: GetTopicRule
export def "get-topic-rule" [
  rule_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rules/{ruleName}"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replaces the rule. You must specify all parameters for the new rule. Creating rules is an administrator-level action. Any user who has permission to create rules will be able to access data processed by the rule. Requires permission to access the ReplaceTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /rules/{ruleName}
# operationId: ReplaceTopicRule
export def "replace-topic-rule" [
  rule_name: string
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
  topic_rule_payload: record # Describes a rule. — shape: {sql?: string, description?: string, actions?: list, ruleDisabled?: bool, awsIotSqlVersion?: string, errorAction?: record}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rules/{ruleName}"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: topicRulePayload, var: topic_rule_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, topic_rule_payload: $topic_rule_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a topic rule destination. The destination must be confirmed prior to use. Requires permission to access the CreateTopicRuleDestination (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /destinations
# Returns: record<topicRuleDestination: record<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlProperties: record<confirmationUrl: string>, vpcProperties: record<subnetIds: list, securityGroups: list, vpcId: string, roleArn: string>>>
# operationId: CreateTopicRuleDestination
export def "create-topic-rule-destination" [
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
  destination_configuration: record # Configuration of the topic rule destination. — shape: {httpUrlConfiguration?: record, vpcConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/destinations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationConfiguration, var: destination_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, destination_configuration: $destination_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the topic rule destinations in your Amazon Web Services account. Requires permission to access the ListTopicRuleDestinations (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /destinations
# Returns: record<destinationSummaries: table<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlSummary: record, vpcDestinationSummary: record>, nextToken: string>
# operationId: ListTopicRuleDestinations
export def "list-topic-rule-destinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at one time.
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
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
    path: "/destinations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a topic rule destination. You use this to change the status, endpoint URL, or confirmation URL of the destination. Requires permission to access the UpdateTopicRuleDestination (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /destinations
# Returns: record
# operationId: UpdateTopicRuleDestination
export def "update-topic-rule-destination" [
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
  arn: string # The ARN of the topic rule destination.
  status: string@status-completer-1 # The status of the topic rule destination. Valid values are: IN_PROGRESS A topic rule destination was created but has not been confirmed. You can set status to IN_PROGRESS by calling UpdateTopicRuleDestination. Calling UpdateTopicRuleDestination causes a new confirmation challenge to be sent to your confirmation endpoint. ENABLED Confirmation was completed, and traffic to this destination is allowed. You can set status to DISABLED by calling UpdateTopicRuleDestination. DISABLED Confirmation was completed, and traffic to this destination is not allowed. You can set status to ENABLED by calling UpdateTopicRuleDestination. ERROR Confirmation could not be completed, for example if the confirmation timed out. You can call GetTopicRuleDestination for details about the error. You can set status to IN_PROGRESS by calling UpdateTopicRuleDestination. Calling UpdateTopicRuleDestination causes a new confirmation challenge to be sent to your confirmation endpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/destinations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, arn: $arn, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores the default settings for Device Defender audits for this account. Any configuration data you entered is deleted and all audit checks are reset to disabled. Requires permission to access the DeleteAccountAuditConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /audit/configuration
# Returns: record
# operationId: DeleteAccountAuditConfiguration
export def "delete-account-audit-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-scheduled-audits: oneof<nothing, bool> # If true, all scheduled audits are deleted.
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
    path: "/audit/configuration"
    query: [{name: deleteScheduledAudits, var: delete_scheduled_audits}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delete_scheduled_audits: $delete_scheduled_audits, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Device Defender audit settings for this account. Settings include how audit notifications are sent and which audit checks are enabled or disabled. Requires permission to access the DescribeAccountAuditConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/configuration
# Returns: record<roleArn: string, auditNotificationTargetConfigurations: record, auditCheckConfigurations: record>
# operationId: DescribeAccountAuditConfiguration
export def "describe-account-audit-configuration" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audit/configuration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures or reconfigures the Device Defender audit settings for this account. Settings include how audit notifications are sent and which audit checks are enabled or disabled. Requires permission to access the UpdateAccountAuditConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /audit/configuration
# Returns: record
# operationId: UpdateAccountAuditConfiguration
export def "update-account-audit-configuration" [
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
  --role-arn: string # The Amazon Resource Name (ARN) of the role that grants permission to IoT to access information about your devices, policies, certificates, and other items as required when performing an audit.
  --audit-notification-target-configurations: record # Information about the targets to which audit notifications are sent.
  --audit-check-configurations: record # Specifies which audit checks are enabled and disabled for this account. Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are currently enabled. Some data collection might start immediately when certain checks are enabled. When a check is disabled, any data collected so far in relation to the check is deleted. You cannot disable a check if it's used by any scheduled audit. You must first delete the check from the scheduled audit or delete the scheduled audit itself. On the first call to UpdateAccountAuditConfiguration, this parameter is required and must specify at least one enabled check.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/audit/configuration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: auditNotificationTargetConfigurations, var: audit_notification_target_configurations}, {name: auditCheckConfigurations, var: audit_check_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, audit_notification_target_configurations: $audit_notification_target_configurations, audit_check_configurations: $audit_check_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Device Defender audit suppression. Requires permission to access the DeleteAuditSuppression (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/suppressions/delete
# Returns: record
# operationId: DeleteAuditSuppression
export def "delete-audit-suppression" [
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
  check_name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  resource_identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/suppressions/delete"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, check_name: $check_name, resource_identifier: $resource_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a registered CA certificate. Requires permission to access the DeleteCACertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /cacertificate/{caCertificateId}
# Returns: record
# operationId: DeleteCACertificate
export def "delete-ca-certificate" [
  ca_certificate_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/cacertificate/{caCertificateId}"
    path_params: [{name: caCertificateId, var: ca_certificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ca_certificate_id: $ca_certificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a registered CA certificate. Requires permission to access the DescribeCACertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /cacertificate/{caCertificateId}
# Returns: record<certificateDescription: record<certificateArn: string, certificateId: string, status: string, certificatePem: string, ownedBy: string, creationDate: string, autoRegistrationStatus: string, lastModifiedDate: string, customerVersion: int, generationId: string, validity: record<notBefore: string, notAfter: string>, certificateMode: string>, registrationConfig: record<templateBody: string, roleArn: string, templateName: string>>
# operationId: DescribeCACertificate
export def "describe-ca-certificate" [
  ca_certificate_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cacertificate/{caCertificateId}"
    path_params: [{name: caCertificateId, var: ca_certificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ca_certificate_id: $ca_certificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a registered CA certificate. Requires permission to access the UpdateCACertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /cacertificate/{caCertificateId}
# operationId: UpdateCACertificate
export def "update-ca-certificate" [
  ca_certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-status: string@new-status-completer # The updated status of the CA certificate. Note: The status value REGISTER_INACTIVE is deprecated and should not be used.
  --new-auto-registration-status: string@new-auto-registration-status-completer # The new value for the auto registration status. Valid values are: "ENABLE" or "DISABLE".
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --registration-config: record # The registration configuration. — shape: {templateBody?: string, roleArn?: string, templateName?: string}
  --remove-auto-registration: oneof<nothing, bool> # If true, removes auto registration.
]: any -> any {
  $in | http-request {
    method: put
    path: "/cacertificate/{caCertificateId}"
    path_params: [{name: caCertificateId, var: ca_certificate_id}]
    query: [{name: newStatus, var: new_status}, {name: newAutoRegistrationStatus, var: new_auto_registration_status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: registrationConfig, var: registration_config}, {name: removeAutoRegistration, var: remove_auto_registration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ca_certificate_id: $ca_certificate_id, new_status: $new_status, new_auto_registration_status: $new_auto_registration_status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, registration_config: $registration_config, remove_auto_registration: $remove_auto_registration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified certificate. A certificate cannot be deleted if it has a policy or IoT thing attached to it or if its status is set to ACTIVE. To delete a certificate, first use the DetachPolicy action to detach all policies. Next, use the UpdateCertificate action to set the certificate to the INACTIVE status. Requires permission to access the DeleteCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /certificates/{certificateId}
# operationId: DeleteCertificate
export def "delete-certificate" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-delete: oneof<nothing, bool> # Forces the deletion of a certificate if it is inactive and is not attached to an IoT thing.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/certificates/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    query: [{name: forceDelete, var: force_delete}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, force_delete: $force_delete, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified certificate. Requires permission to access the DescribeCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /certificates/{certificateId}
# Returns: record<certificateDescription: record<certificateArn: string, certificateId: string, caCertificateId: string, status: string, certificatePem: string, ownedBy: string, previousOwnedBy: string, creationDate: string, lastModifiedDate: string, customerVersion: int, transferData: record<transferMessage: string, rejectReason: string, transferDate: string, acceptDate: string, rejectDate: string>, generationId: string, validity: record<notBefore: string, notAfter: string>, certificateMode: string>>
# operationId: DescribeCertificate
export def "describe-certificate" [
  certificate_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a job execution. Requires permission to access the DeleteJobExecution (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /things/{thingName}/jobs/{jobId}/executionNumber/{executionNumber}
# operationId: DeleteJobExecution
export def "delete-job-execution" [
  thing_name: string
  job_id: string
  execution_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # (Optional) When true, you can delete a job execution which is "IN_PROGRESS". Otherwise, you can only delete a job execution which is in a terminal state ("SUCCEEDED", "FAILED", "REJECTED", "REMOVED" or "CANCELED") or an exception will occur. The default is false. Deleting a job execution which is "IN_PROGRESS", will cause the device to be unable to access job information or update the job execution status. Use caution and ensure that the device is able to recover to a valid state.
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/things/{thingName}/jobs/{jobId}/executionNumber/{executionNumber}"
    path_params: [{name: thingName, var: thing_name}, {name: jobId, var: job_id}, {name: executionNumber, var: execution_number}]
    query: [{name: force, var: force}, {name: namespaceId, var: namespace_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, job_id: $job_id, execution_number: $execution_number, force: $force, namespace_id: $namespace_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified version of the specified policy. You cannot delete the default version of a policy using this action. To delete the default version of a policy, use DeletePolicy. To find out which version of a policy is marked as the default version, use ListPolicyVersions. Requires permission to access the DeletePolicyVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /policies/{policyName}/version/{policyVersionId}
# operationId: DeletePolicyVersion
export def "delete-policy-version" [
  policy_name: string
  policy_version_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/policies/{policyName}/version/{policyVersionId}"
    path_params: [{name: policyName, var: policy_name}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified policy version. Requires permission to access the GetPolicyVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /policies/{policyName}/version/{policyVersionId}
# Returns: record<policyArn: string, policyName: string, policyDocument: string, policyVersionId: string, isDefaultVersion: bool, creationDate: string, lastModifiedDate: string, generationId: string>
# operationId: GetPolicyVersion
export def "get-policy-version" [
  policy_name: string
  policy_version_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/policies/{policyName}/version/{policyVersionId}"
    path_params: [{name: policyName, var: policy_name}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the specified version of the specified policy as the policy's default (operative) version. This action affects all certificates to which the policy is attached. To list the principals the policy is attached to, use the ListPrincipalPolicies action. Requires permission to access the SetDefaultPolicyVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /policies/{policyName}/version/{policyVersionId}
# operationId: SetDefaultPolicyVersion
export def "set-default-policy-version" [
  policy_name: string
  policy_version_id: string
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
]: nothing -> any {
  http-request {
    method: patch
    path: "/policies/{policyName}/version/{policyVersionId}"
    path_params: [{name: policyName, var: policy_name}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a provisioning template. Requires permission to access the DeleteProvisioningTemplate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /provisioning-templates/{templateName}
# Returns: record
# operationId: DeleteProvisioningTemplate
export def "delete-provisioning-template" [
  template_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/provisioning-templates/{templateName}"
    path_params: [{name: templateName, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a provisioning template. Requires permission to access the DescribeProvisioningTemplate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /provisioning-templates/{templateName}
# Returns: record<templateArn: string, templateName: string, description: string, creationDate: string, lastModifiedDate: string, defaultVersionId: int, templateBody: string, enabled: bool, provisioningRoleArn: string, preProvisioningHook: record<payloadVersion: string, targetArn: string>, type: string>
# operationId: DescribeProvisioningTemplate
export def "describe-provisioning-template" [
  template_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/provisioning-templates/{templateName}"
    path_params: [{name: templateName, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a provisioning template. Requires permission to access the UpdateProvisioningTemplate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /provisioning-templates/{templateName}
# Returns: record
# operationId: UpdateProvisioningTemplate
export def "update-provisioning-template" [
  template_name: string
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
  --description: string # The description of the provisioning template.
  --enabled: oneof<nothing, bool> # True to enable the provisioning template, otherwise false.
  --default-version-id: int # The ID of the default provisioning template version.
  --provisioning-role-arn: string # The ARN of the role associated with the provisioning template. This IoT role grants permission to provision a device.
  --pre-provisioning-hook: record # Structure that contains payloadVersion and targetArn. — shape: {payloadVersion?: string, targetArn?: string}
  --remove-pre-provisioning-hook: oneof<nothing, bool> # Removes pre-provisioning hook template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/provisioning-templates/{templateName}"
    path_params: [{name: templateName, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: enabled, var: enabled}, {name: defaultVersionId, var: default_version_id}, {name: provisioningRoleArn, var: provisioning_role_arn}, {name: preProvisioningHook, var: pre_provisioning_hook}, {name: removePreProvisioningHook, var: remove_pre_provisioning_hook}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, enabled: $enabled, default_version_id: $default_version_id, provisioning_role_arn: $provisioning_role_arn, pre_provisioning_hook: $pre_provisioning_hook, remove_pre_provisioning_hook: $remove_pre_provisioning_hook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a provisioning template version. Requires permission to access the DeleteProvisioningTemplateVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /provisioning-templates/{templateName}/versions/{versionId}
# Returns: record
# operationId: DeleteProvisioningTemplateVersion
export def "delete-provisioning-template-version" [
  template_name: string
  version_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/provisioning-templates/{templateName}/versions/{versionId}"
    path_params: [{name: templateName, var: template_name}, {name: versionId, var: version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version_id: $version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a provisioning template version. Requires permission to access the DescribeProvisioningTemplateVersion (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /provisioning-templates/{templateName}/versions/{versionId}
# Returns: record<versionId: int, creationDate: string, templateBody: string, isDefaultVersion: bool>
# operationId: DescribeProvisioningTemplateVersion
export def "describe-provisioning-template-version" [
  template_name: string
  version_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/provisioning-templates/{templateName}/versions/{versionId}"
    path_params: [{name: templateName, var: template_name}, {name: versionId, var: version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, version_id: $version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a CA certificate registration code. Requires permission to access the DeleteRegistrationCode (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /registrationcode
# Returns: record
# operationId: DeleteRegistrationCode
export def "delete-registration-code" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/registrationcode"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a registration code used to register a CA certificate with IoT. Requires permission to access the GetRegistrationCode (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /registrationcode
# Returns: record<registrationCode: string>
# operationId: GetRegistrationCode
export def "get-registration-code" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registrationcode"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a topic rule destination. Requires permission to access the DeleteTopicRuleDestination (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /destinations/{arn}
# Returns: record
# operationId: DeleteTopicRuleDestination
export def "delete-topic-rule-destination" [
  arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/destinations/{arn}"
    path_params: [{name: arn, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a topic rule destination. Requires permission to access the GetTopicRuleDestination (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /destinations/{arn}
# Returns: record<topicRuleDestination: record<arn: string, status: string, createdAt: string, lastUpdatedAt: string, statusReason: string, httpUrlProperties: record<confirmationUrl: string>, vpcProperties: record<subnetIds: list, securityGroups: list, vpcId: string, roleArn: string>>>
# operationId: GetTopicRuleDestination
export def "get-topic-rule-destination" [
  arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/destinations/{arn}"
    path_params: [{name: arn, var: arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    arn: $arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a logging level. Requires permission to access the DeleteV2LoggingLevel (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# DELETE /v2LoggingLevel
# operationId: DeleteV2LoggingLevel
export def "delete-v2-logging-level" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-type: string@target-type-completer # The type of resource for which you are configuring logging. Must be THING_Group. (required)
  --target-name: string # The name of the resource for which you are configuring logging. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2LoggingLevel"
    query: [{name: targetType, var: target_type, required: true}, {name: targetName, var: target_name, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_type: $target_type, target_name: $target_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecates a thing type. You can not associate new things with deprecated thing type. Requires permission to access the DeprecateThingType (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /thing-types/{thingTypeName}/deprecate
# Returns: record
# operationId: DeprecateThingType
export def "deprecate-thing-type" [
  thing_type_name: string
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
  --undo-deprecate: oneof<nothing, bool> # Whether to undeprecate a deprecated thing type. If true, the thing type will not be deprecated anymore and you can associate it with things.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/thing-types/{thingTypeName}/deprecate"
    path_params: [{name: thingTypeName, var: thing_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: undoDeprecate, var: undo_deprecate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_type_name: $thing_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, undo_deprecate: $undo_deprecate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a single audit finding. Properties include the reason for noncompliance, the severity of the issue, and the start time when the audit that returned the finding. Requires permission to access the DescribeAuditFinding (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/findings/{findingId}
# Returns: record<finding: record<findingId: string, taskId: string, checkName: string, taskStartTime: string, findingTime: string, severity: string, nonCompliantResource: record<resourceType: string, resourceIdentifier: record, additionalInfo: record>, relatedResources: list<record>, reasonForNonCompliance: string, reasonForNonComplianceCode: string, isSuppressed: bool>>
# operationId: DescribeAuditFinding
export def "describe-audit-finding" [
  finding_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audit/findings/{findingId}"
    path_params: [{name: findingId, var: finding_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    finding_id: $finding_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an audit mitigation task that is used to apply mitigation actions to a set of audit findings. Properties include the actions being applied, the audit checks to which they're being applied, the task status, and aggregated task statistics.
#
# GET /audit/mitigationactions/tasks/{taskId}
# Returns: record<taskStatus: string, startTime: string, endTime: string, taskStatistics: record, target: record<auditTaskId: string, findingIds: list<string>, auditCheckToReasonCodeFilter: record>, auditCheckToActionsMapping: record, actionsDefinition: table<name: string, id: string, roleArn: string, actionParams: record>>
# operationId: DescribeAuditMitigationActionsTask
export def "describe-audit-mitigation-actions-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audit/mitigationactions/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a task that applies a set of mitigation actions to the specified target. Requires permission to access the StartAuditMitigationActionsTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/mitigationactions/tasks/{taskId}
# Returns: record<taskId: string>
# operationId: StartAuditMitigationActionsTask
export def "start-audit-mitigation-actions-task" [
  task_id: string
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
  target: record # Used in MitigationActionParams, this information identifies the target findings to which the mitigation actions are applied. Only one entry appears. — shape: {auditTaskId?: string, findingIds?: list<string>, auditCheckToReasonCodeFilter?: record}
  audit_check_to_actions_mapping: record # For an audit check, specifies which mitigation actions to apply. Those actions must be defined in your Amazon Web Services accounts.
  client_request_token: string # Each audit mitigation task must have a unique client request token. If you try to start a new task with the same token as a task that already exists, an exception occurs. If you omit this value, a unique client request token is generated automatically.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/mitigationactions/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: target, var: target}, {name: auditCheckToActionsMapping, var: audit_check_to_actions_mapping}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target: $target, audit_check_to_actions_mapping: $audit_check_to_actions_mapping, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Device Defender audit suppression.
#
# POST /audit/suppressions/describe
# Returns: record<checkName: string, resourceIdentifier: record<deviceCertificateId: string, caCertificateId: string, cognitoIdentityPoolId: string, clientId: string, policyVersionIdentifier: record<policyName: string, policyVersionId: string>, account: string, iamRoleArn: string, roleAliasArn: string, issuerCertificateIdentifier: record<issuerCertificateSubject: string, issuerId: string, issuerCertificateSerialNumber: string>, deviceCertificateArn: string>, expirationDate: string, suppressIndefinitely: bool, description: string>
# operationId: DescribeAuditSuppression
export def "describe-audit-suppression" [
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
  check_name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  resource_identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/suppressions/describe"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, check_name: $check_name, resource_identifier: $resource_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Device Defender audit. Requires permission to access the DescribeAuditTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/tasks/{taskId}
# Returns: record<taskStatus: string, taskType: string, taskStartTime: string, taskStatistics: record<totalChecks: int, inProgressChecks: int, waitingForDataCollectionChecks: int, compliantChecks: int, nonCompliantChecks: int, failedChecks: int, canceledChecks: int>, scheduledAuditName: string, auditDetails: record>
# operationId: DescribeAuditTask
export def "describe-audit-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audit/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a Device Defender ML Detect mitigation action. Requires permission to access the DescribeDetectMitigationActionsTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /detect/mitigationactions/tasks/{taskId}
# Returns: record<taskSummary: record<taskId: string, taskStatus: string, taskStartTime: string, taskEndTime: string, target: record<violationIds: list, securityProfileName: string, behaviorName: string>, violationEventOccurrenceRange: record<startTime: string, endTime: string>, onlyActiveViolationsIncluded: bool, suppressedAlertsIncluded: bool, actionsDefinition: list<record>, taskStatistics: record<actionsExecuted: int, actionsSkipped: int, actionsFailed: int>>>
# operationId: DescribeDetectMitigationActionsTask
export def "describe-detect-mitigation-actions-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/detect/mitigationactions/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a Device Defender ML Detect mitigation actions task. Requires permission to access the StartDetectMitigationActionsTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /detect/mitigationactions/tasks/{taskId}
# Returns: record<taskId: string>
# operationId: StartDetectMitigationActionsTask
export def "start-detect-mitigation-actions-task" [
  task_id: string
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
  target: record # The target of a mitigation action task. — shape: {violationIds?: list<string>, securityProfileName?: string, behaviorName?: string}
  actions: list<string> # The actions to be performed when a device has unexpected behavior.
  --violation-event-occurrence-range: record # Specifies the time period of which violation events occurred between. — shape: {startTime?: string, endTime?: string}
  --include-only-active-violations: oneof<nothing, bool> # Specifies to list only active violations.
  --include-suppressed-alerts: oneof<nothing, bool> # Specifies to include suppressed alerts.
  client_request_token: string # Each mitigation action task must have a unique client request token. If you try to create a new task with the same token as a task that already exists, an exception occurs. If you omit this value, Amazon Web Services SDKs will automatically generate a unique client request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/detect/mitigationactions/tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: target, var: target}, {name: actions, var: actions}, {name: violationEventOccurrenceRange, var: violation_event_occurrence_range}, {name: includeOnlyActiveViolations, var: include_only_active_violations}, {name: includeSuppressedAlerts, var: include_suppressed_alerts}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target: $target, actions: $actions, violation_event_occurrence_range: $violation_event_occurrence_range, include_only_active_violations: $include_only_active_violations, include_suppressed_alerts: $include_suppressed_alerts, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a unique endpoint specific to the Amazon Web Services account making the call. Requires permission to access the DescribeEndpoint (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /endpoint
# Returns: record<endpointAddress: string>
# operationId: DescribeEndpoint
export def "describe-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-type: string # The endpoint type. Valid endpoint types include: iot:Data - Returns a VeriSign signed data endpoint. iot:Data-ATS - Returns an ATS signed data endpoint. iot:CredentialProvider - Returns an IoT credentials provider API endpoint. iot:Jobs - Returns an IoT device management Jobs API endpoint. We strongly recommend that customers use the newer iot:Data-ATS endpoint type to avoid issues related to the widespread distrust of Symantec certificate authorities.
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
    path: "/endpoint"
    query: [{name: endpointType, var: endpoint_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    endpoint_type: $endpoint_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes event configurations. Requires permission to access the DescribeEventConfigurations (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /event-configurations
# Returns: record<eventConfigurations: record, creationDate: string, lastModifiedDate: string>
# operationId: DescribeEventConfigurations
export def "describe-event-configurations" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event-configurations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the event configurations. Requires permission to access the UpdateEventConfigurations (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /event-configurations
# Returns: record
# operationId: UpdateEventConfigurations
export def "update-event-configurations" [
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
  --event-configurations: record # The new event configuration values.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/event-configurations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventConfigurations, var: event_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, event_configurations: $event_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a search index. Requires permission to access the DescribeIndex (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /indices/{indexName}
# Returns: record<indexName: string, indexStatus: string, schema: string>
# operationId: DescribeIndex
export def "describe-index" [
  index_name: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indices/{indexName}"
    path_params: [{name: indexName, var: index_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    index_name: $index_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a job execution. Requires permission to access the DescribeJobExecution (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /things/{thingName}/jobs/{jobId}
# Returns: record<execution: record<jobId: string, status: string, forceCanceled: bool, statusDetails: record<detailsMap: record>, thingArn: string, queuedAt: string, startedAt: string, lastUpdatedAt: string, executionNumber: int, versionNumber: int, approximateSecondsBeforeTimedOut: int>>
# operationId: DescribeJobExecution
export def "describe-job-execution" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-number: int # A string (consisting of the digits "0" through "9" which is used to specify a particular job execution on a particular device.
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
    path: "/things/{thingName}/jobs/{jobId}"
    path_params: [{name: thingName, var: thing_name}, {name: jobId, var: job_id}]
    query: [{name: executionNumber, var: execution_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, job_id: $job_id, execution_number: $execution_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View details of a managed job template.
#
# GET /managed-job-templates/{templateName}
# Returns: record<templateName: string, templateArn: string, description: string, templateVersion: string, environments: list<string>, documentParameters: table<key: string, description: string, regex: string, example: string, optional: bool>, document: string>
# operationId: DescribeManagedJobTemplate
export def "describe-managed-job-template" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-version: string # An optional parameter to specify version of a managed template. If not specified, the pre-defined default version is returned.
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
    path: "/managed-job-templates/{templateName}"
    path_params: [{name: templateName, var: template_name}]
    query: [{name: templateVersion, var: template_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, template_version: $template_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a bulk thing provisioning task. Requires permission to access the DescribeThingRegistrationTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-registration-tasks/{taskId}
# Returns: record<taskId: string, creationDate: string, lastModifiedDate: string, templateBody: string, inputFileBucket: string, inputFileKey: string, roleArn: string, status: string, message: string, successCount: int, failureCount: int, percentageProgress: int>
# operationId: DescribeThingRegistrationTask
export def "describe-thing-registration-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/thing-registration-tasks/{taskId}"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the rule. Requires permission to access the DisableTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /rules/{ruleName}/disable
# operationId: DisableTopicRule
export def "disable-topic-rule" [
  rule_name: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/rules/{ruleName}/disable"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the rule. Requires permission to access the EnableTopicRule (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /rules/{ruleName}/enable
# operationId: EnableTopicRule
export def "enable-topic-rule" [
  rule_name: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/rules/{ruleName}/enable"
    path_params: [{name: ruleName, var: rule_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_name: $rule_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Device Defender's ML Detect Security Profile training model's status. Requires permission to access the GetBehaviorModelTrainingSummaries (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /behavior-model-training/summaries
# Returns: record<summaries: table<securityProfileName: string, behaviorName: string, trainingDataCollectionStartDate: string, modelStatus: string, datapointsCollectionPercentage: float, lastModelRefreshDate: string>, nextToken: string>
# operationId: GetBehaviorModelTrainingSummaries
export def "get-behavior-model-training-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-profile-name: string # The name of the security profile.
  --max-results: int # The maximum number of results to return at one time. The default is 10.
  --next-token: string # The token for the next set of results.
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
    path: "/behavior-model-training/summaries"
    query: [{name: securityProfileName, var: security_profile_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregates on indexed data with search queries pertaining to particular fields. Requires permission to access the GetBucketsAggregation (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indices/buckets
# Returns: record<totalCount: int, buckets: table<keyValue: string, count: int>>
# operationId: GetBucketsAggregation
export def "get-buckets-aggregation" [
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
  --index-name: string # The name of the index to search.
  query_string: string # The search query string.
  aggregation_field: string # The aggregation field.
  --query-version: string # The version of the query.
  buckets_aggregation_type: record # The type of bucketed aggregation performed. — shape: {termsAggregation?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indices/buckets"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: aggregationField, var: aggregation_field}, {name: queryVersion, var: query_version}, {name: bucketsAggregationType, var: buckets_aggregation_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, index_name: $index_name, query_string: $query_string, aggregation_field: $aggregation_field, query_version: $query_version, buckets_aggregation_type: $buckets_aggregation_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the approximate count of unique values that match the query. Requires permission to access the GetCardinality (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indices/cardinality
# Returns: record<cardinality: int>
# operationId: GetCardinality
export def "get-cardinality" [
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
  --index-name: string # The name of the index to search.
  query_string: string # The search query string.
  --aggregation-field: string # The field to aggregate.
  --query-version: string # The query version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indices/cardinality"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: aggregationField, var: aggregation_field}, {name: queryVersion, var: query_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, index_name: $index_name, query_string: $query_string, aggregation_field: $aggregation_field, query_version: $query_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the policies that have an effect on the authorization behavior of the specified device when it connects to the IoT device gateway. Requires permission to access the GetEffectivePolicies (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /effective-policies
# Returns: record<effectivePolicies: table<policyName: string, policyArn: string, policyDocument: string>>
# operationId: GetEffectivePolicies
export def "get-effective-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thing-name: string # The thing name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --principal: string # The principal. Valid principals are CertificateArn (arn:aws:iot:region:accountId:cert/certificateId), thingGroupArn (arn:aws:iot:region:accountId:thinggroup/groupName) and CognitoId (region:id).
  --cognito-identity-pool-id: string # The Cognito identity pool ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/effective-policies"
    query: [{name: thingName, var: thing_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: principal, var: principal}, {name: cognitoIdentityPoolId, var: cognito_identity_pool_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, principal: $principal, cognito_identity_pool_id: $cognito_identity_pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the indexing configuration. Requires permission to access the GetIndexingConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /indexing/config
# Returns: record<thingIndexingConfiguration: record<thingIndexingMode: string, thingConnectivityIndexingMode: string, deviceDefenderIndexingMode: string, namedShadowIndexingMode: string, managedFields: list<record>, customFields: list<record>, filter: record<namedShadowNames: list>>, thingGroupIndexingConfiguration: record<thingGroupIndexingMode: string, managedFields: list<record>, customFields: list<record>>>
# operationId: GetIndexingConfiguration
export def "get-indexing-configuration" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/indexing/config"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the search configuration. Requires permission to access the UpdateIndexingConfiguration (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indexing/config
# Returns: record
# operationId: UpdateIndexingConfiguration
export def "update-indexing-configuration" [
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
  --thing-indexing-configuration: record # The thing indexing configuration. For more information, see Managing Thing Indexing (https://docs.aws.amazon.com/iot/latest/developerguide/managing-index.html). — shape: {thingIndexingMode?: "OFF"|"REGISTRY"|"REGISTRY_AND_SHADOW", thingConnectivityIndexingMode?: "OFF"|"STATUS", deviceDefenderIndexingMode?: "OFF"|"VIOLATIONS", namedShadowIndexingMode?: "OFF"|"ON", managedFields?: list, customFields?: list, filter?: record}
  --thing-group-indexing-configuration: record # Thing group indexing configuration. — shape: {thingGroupIndexingMode?: "OFF"|"ON", managedFields?: list, customFields?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indexing/config"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingIndexingConfiguration, var: thing_indexing_configuration}, {name: thingGroupIndexingConfiguration, var: thing_group_indexing_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_indexing_configuration: $thing_indexing_configuration, thing_group_indexing_configuration: $thing_group_indexing_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a job document. Requires permission to access the GetJobDocument (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /jobs/{jobId}/job-document
# Returns: record<document: string>
# operationId: GetJobDocument
export def "get-job-document" [
  job_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{jobId}/job-document"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the logging options. NOTE: use of this command is not recommended. Use GetV2LoggingOptions instead. Requires permission to access the GetLoggingOptions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /loggingOptions
# Returns: record<roleArn: string, logLevel: string>
# operationId: GetLoggingOptions
export def "get-logging-options" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/loggingOptions"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the logging options. NOTE: use of this command is not recommended. Use SetV2LoggingOptions instead. Requires permission to access the SetLoggingOptions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /loggingOptions
# operationId: SetLoggingOptions
export def "set-logging-options" [
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
  logging_options_payload: record # Describes the logging options payload. — shape: {roleArn?: string, logLevel?: "DEBUG"|"INFO"|"ERROR"|"WARN"|"DISABLED"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/loggingOptions"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: loggingOptionsPayload, var: logging_options_payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, logging_options_payload: $logging_options_payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Groups the aggregated values that match the query into percentile groupings. The default percentile groupings are: 1,5,25,50,75,95,99, although you can specify your own when you call GetPercentiles. This function returns a value for each percentile group specified (or the default percentile groupings). The percentile group "1" contains the aggregated field value that occurs in approximately one percent of the values that match the query. The percentile group "5" contains the aggregated field value that occurs in approximately five percent of the values that match the query, and so on. The result is an approximation, the more values that match the query, the more accurate the percentile values. Requires permission to access the GetPercentiles (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indices/percentiles
# Returns: record<percentiles: table<percent: float, value: float>>
# operationId: GetPercentiles
export def "get-percentiles" [
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
  --index-name: string # The name of the index to search.
  query_string: string # The search query string.
  --aggregation-field: string # The field to aggregate.
  --query-version: string # The query version.
  --percents: list<float> # The percentile groups returned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indices/percentiles"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: aggregationField, var: aggregation_field}, {name: queryVersion, var: query_version}, {name: percents, var: percents}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, index_name: $index_name, query_string: $query_string, aggregation_field: $aggregation_field, query_version: $query_version, percents: $percents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the count, average, sum, minimum, maximum, sum of squares, variance, and standard deviation for the specified aggregated field. If the aggregation field is of type String, only the count statistic is returned. Requires permission to access the GetStatistics (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indices/statistics
# Returns: record<statistics: record<count: int, average: float, sum: float, minimum: float, maximum: float, sumOfSquares: float, variance: float, stdDeviation: float>>
# operationId: GetStatistics
export def "get-statistics" [
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
  --index-name: string # The name of the index to search. The default value is AWS_Things.
  query_string: string # The query used to search. You can specify "*" for the query string to get the count of all indexed things in your Amazon Web Services account.
  --aggregation-field: string # The aggregation field name.
  --query-version: string # The version of the query used to search.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indices/statistics"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: aggregationField, var: aggregation_field}, {name: queryVersion, var: query_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, index_name: $index_name, query_string: $query_string, aggregation_field: $aggregation_field, query_version: $query_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the fine grained logging options. Requires permission to access the GetV2LoggingOptions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /v2LoggingOptions
# Returns: record<roleArn: string, defaultLogLevel: string, disableAllLogs: bool>
# operationId: GetV2LoggingOptions
export def "get-v2-logging-options" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2LoggingOptions"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the logging options for the V2 logging service. Requires permission to access the SetV2LoggingOptions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /v2LoggingOptions
# operationId: SetV2LoggingOptions
export def "set-v2-logging-options" [
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
  --role-arn: string # The ARN of the role that allows IoT to write to Cloudwatch logs.
  --default-log-level: string@default-log-level-completer # The default logging level.
  --disable-all-logs: oneof<nothing, bool> # If true all logs are disabled. The default is false.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2LoggingOptions"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleArn, var: role_arn}, {name: defaultLogLevel, var: default_log_level}, {name: disableAllLogs, var: disable_all_logs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, role_arn: $role_arn, default_log_level: $default_log_level, disable_all_logs: $disable_all_logs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the active violations for a given Device Defender security profile. Requires permission to access the ListActiveViolations (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /active-violations
# Returns: record<activeViolations: table<violationId: string, thingName: string, securityProfileName: string, behavior: record, lastViolationValue: record, violationEventAdditionalInfo: record, verificationState: string, verificationStateDescription: string, lastViolationTime: string, violationStartTime: string>, nextToken: string>
# operationId: ListActiveViolations
export def "list-active-violations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thing-name: string # The name of the thing whose active violations are listed.
  --security-profile-name: string # The name of the Device Defender security profile for which violations are listed.
  --behavior-criteria-type: string@behavior-criteria-type-completer # The criteria for a behavior.
  --list-suppressed-alerts: oneof<nothing, bool> # A list of all suppressed alerts.
  --verification-state: string@verification-state-completer # The verification state of the violation (detect alarm).
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/active-violations"
    query: [{name: thingName, var: thing_name}, {name: securityProfileName, var: security_profile_name}, {name: behaviorCriteriaType, var: behavior_criteria_type}, {name: listSuppressedAlerts, var: list_suppressed_alerts}, {name: verificationState, var: verification_state}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, security_profile_name: $security_profile_name, behavior_criteria_type: $behavior_criteria_type, list_suppressed_alerts: $list_suppressed_alerts, verification_state: $verification_state, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the policies attached to the specified thing group. Requires permission to access the ListAttachedPolicies (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /attached-policies/{target}
# Returns: record<policies: table<policyName: string, policyArn: string>, nextMarker: string>
# operationId: ListAttachedPolicies
export def "list-attached-policies" [
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # When true, recursively list attached policies.
  --marker: string # The token to retrieve the next set of results.
  --page-size: int # The maximum number of results to be returned per request.
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
    path: "/attached-policies/{target}"
    path_params: [{name: target, var: target}]
    query: [{name: recursive, var: recursive}, {name: marker, var: marker}, {name: pageSize, var: page_size}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target: $target, recursive: $recursive, marker: $marker, page_size: $page_size, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the findings (results) of a Device Defender audit or of the audits performed during a specified time period. (Findings are retained for 90 days.) Requires permission to access the ListAuditFindings (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/findings
# Returns: record<findings: table<findingId: string, taskId: string, checkName: string, taskStartTime: string, findingTime: string, severity: string, nonCompliantResource: record, relatedResources: list, reasonForNonCompliance: string, reasonForNonComplianceCode: string, isSuppressed: bool>, nextToken: string>
# operationId: ListAuditFindings
export def "list-audit-findings" [
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
  --task-id: string # A filter to limit results to the audit with the specified ID. You must specify either the taskId or the startTime and endTime, but not both.
  --check-name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  --resource-identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
  --body-max-results: int # The maximum number of results to return at one time. The default is 25. (spec name: maxResults)
  --body-next-token: string # The token for the next set of results. (spec name: nextToken)
  --start-time: string # A filter to limit results to those found after the specified time. You must specify either the startTime and endTime or the taskId, but not both. (format: date-time)
  --end-time: string # A filter to limit results to those found before the specified time. You must specify either the startTime and endTime or the taskId, but not both. (format: date-time)
  --list-suppressed-findings: oneof<nothing, bool> # Boolean flag indicating whether only the suppressed findings or the unsuppressed findings should be listed. If this parameter isn't provided, the response will list both suppressed and unsuppressed findings.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/findings"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: taskId, var: task_id}, {name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: listSuppressedFindings, var: list_suppressed_findings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, task_id: $task_id, check_name: $check_name, resource_identifier: $resource_identifier, body_max_results: $body_max_results, body_next_token: $body_next_token, start_time: $start_time, end_time: $end_time, list_suppressed_findings: $list_suppressed_findings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of audit mitigation action tasks that were executed. Requires permission to access the ListAuditMitigationActionsExecutions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/mitigationactions/executions
# Returns: record<actionsExecutions: table<taskId: string, findingId: string, actionName: string, actionId: string, status: string, startTime: string, endTime: string, errorCode: string, message: string>, nextToken: string>
# operationId: ListAuditMitigationActionsExecutions
export def "list-audit-mitigation-actions-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-id: string # Specify this filter to limit results to actions for a specific audit mitigation actions task. (required)
  --action-status: string@action-status-completer # Specify this filter to limit results to those with a specific status.
  --finding-id: string # Specify this filter to limit results to those that were applied to a specific audit finding. (required)
  --max-results: int # The maximum number of results to return at one time. The default is 25.
  --next-token: string # The token for the next set of results.
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
    path: "/audit/mitigationactions/executions"
    query: [{name: taskId, var: task_id, required: true}, {name: actionStatus, var: action_status}, {name: findingId, var: finding_id, required: true}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, action_status: $action_status, finding_id: $finding_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of audit mitigation action tasks that match the specified filters. Requires permission to access the ListAuditMitigationActionsTasks (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/mitigationactions/tasks
# Returns: record<tasks: table<taskId: string, startTime: string, taskStatus: string>, nextToken: string>
# operationId: ListAuditMitigationActionsTasks
export def "list-audit-mitigation-actions-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audit-task-id: string # Specify this filter to limit results to tasks that were applied to results for a specific audit.
  --finding-id: string # Specify this filter to limit results to tasks that were applied to a specific audit finding.
  --task-status: string@task-status-completer # Specify this filter to limit results to tasks that are in a specific state.
  --max-results: int # The maximum number of results to return at one time. The default is 25.
  --next-token: string # The token for the next set of results.
  --start-time: string # Specify this filter to limit results to tasks that began on or after a specific date and time. (required, format: date-time)
  --end-time: string # Specify this filter to limit results to tasks that were completed or canceled on or before a specific date and time. (required, format: date-time)
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
    path: "/audit/mitigationactions/tasks"
    query: [{name: auditTaskId, var: audit_task_id}, {name: findingId, var: finding_id}, {name: taskStatus, var: task_status}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: startTime, var: start_time, required: true}, {name: endTime, var: end_time, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    audit_task_id: $audit_task_id, finding_id: $finding_id, task_status: $task_status, max_results: $max_results, next_token: $next_token, start_time: $start_time, end_time: $end_time, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your Device Defender audit listings. Requires permission to access the ListAuditSuppressions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/suppressions/list
# Returns: record<suppressions: table<checkName: string, resourceIdentifier: record, expirationDate: string, suppressIndefinitely: bool, description: string>, nextToken: string>
# operationId: ListAuditSuppressions
export def "list-audit-suppressions" [
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
  --check-name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  --resource-identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
  --ascending-order: oneof<nothing, bool> # Determines whether suppressions are listed in ascending order by expiration date or not. If parameter isn't provided, ascendingOrder=true.
  --body-next-token: string # The token for the next set of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return at one time. The default is 25. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/suppressions/list"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}, {name: ascendingOrder, var: ascending_order}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, check_name: $check_name, resource_identifier: $resource_identifier, ascending_order: $ascending_order, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Device Defender audits that have been performed during a given time period. Requires permission to access the ListAuditTasks (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/tasks
# Returns: record<tasks: table<taskId: string, taskStatus: string, taskType: string>, nextToken: string>
# operationId: ListAuditTasks
export def "list-audit-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # The beginning of the time period. Audit information is retained for a limited time (90 days). Requesting a start time prior to what is retained results in an "InvalidRequestException". (required, format: date-time)
  --end-time: string # The end of the time period. (required, format: date-time)
  --task-type: string@task-type-completer # A filter to limit the output to the specified type of audit: can be one of "ON_DEMAND_AUDIT_TASK" or "SCHEDULED__AUDIT_TASK".
  --task-status: string@task-status-completer # A filter to limit the output to audits with the specified completion status: can be one of "IN_PROGRESS", "COMPLETED", "FAILED", or "CANCELED".
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time. The default is 25.
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
    path: "/audit/tasks"
    query: [{name: startTime, var: start_time, required: true}, {name: endTime, var: end_time, required: true}, {name: taskType, var: task_type}, {name: taskStatus, var: task_status}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, task_type: $task_type, task_status: $task_status, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the authorizers registered in your account. Requires permission to access the ListAuthorizers (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /authorizers/
# Returns: record<authorizers: table<authorizerName: string, authorizerArn: string>, nextMarker: string>
# operationId: ListAuthorizers
export def "list-authorizers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of results to return at one time.
  --marker: string # A marker used to get the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Return the list of authorizers in ascending alphabetical order.
  --status: string@status-completer # The status of the list authorizers request.
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
    path: "/authorizers/"
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}, {name: status, var: status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, status: $status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the billing groups you have created. Requires permission to access the ListBillingGroups (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /billing-groups
# Returns: record<billingGroups: table<groupName: string, groupArn: string>, nextToken: string>
# operationId: ListBillingGroups
export def "list-billing-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return per request.
  --name-prefix-filter: string # Limit the results to billing groups whose names have the given prefix.
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
    path: "/billing-groups"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: namePrefixFilter, var: name_prefix_filter}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, name_prefix_filter: $name_prefix_filter, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the CA certificates registered for your Amazon Web Services account. The results are paginated with a default page size of 25. You can use the returned marker to retrieve additional results. Requires permission to access the ListCACertificates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /cacertificates
# Returns: record<certificates: table<certificateArn: string, certificateId: string, status: string, creationDate: string>, nextMarker: string>
# operationId: ListCACertificates
export def "list-ca-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The result page size.
  --marker: string # The marker for the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Determines the order of the results.
  --template-name: string # The name of the provisioning template.
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
    path: "/cacertificates"
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}, {name: templateName, var: template_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, template_name: $template_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the device certificates signed by the specified CA certificate. Requires permission to access the ListCertificatesByCA (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /certificates-by-ca/{caCertificateId}
# Returns: record<certificates: table<certificateArn: string, certificateId: string, status: string, certificateMode: string, creationDate: string>, nextMarker: string>
# operationId: ListCertificatesByCA
export def "list-certificates-by-ca" [
  ca_certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The result page size.
  --marker: string # The marker for the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If True, the results are returned in ascending order, based on the creation date.
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
    path: "/certificates-by-ca/{caCertificateId}"
    path_params: [{name: caCertificateId, var: ca_certificate_id}]
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ca_certificate_id: $ca_certificate_id, page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your Device Defender detect custom metrics. Requires permission to access the ListCustomMetrics (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /custom-metrics
# Returns: record<metricNames: list<string>, nextToken: string>
# operationId: ListCustomMetrics
export def "list-custom-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time. The default is 25.
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
    path: "/custom-metrics"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists mitigation actions executions for a Device Defender ML Detect Security Profile. Requires permission to access the ListDetectMitigationActionsExecutions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /detect/mitigationactions/executions
# Returns: record<actionsExecutions: table<taskId: string, violationId: string, actionName: string, thingName: string, executionStartDate: string, executionEndDate: string, status: string, errorCode: string, message: string>, nextToken: string>
# operationId: ListDetectMitigationActionsExecutions
export def "list-detect-mitigation-actions-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-id: string # The unique identifier of the task.
  --violation-id: string # The unique identifier of the violation.
  --thing-name: string # The name of the thing whose mitigation actions are listed.
  --start-time: string # A filter to limit results to those found after the specified time. You must specify either the startTime and endTime or the taskId, but not both. (format: date-time)
  --end-time: string # The end of the time period for which ML Detect mitigation actions executions are returned. (format: date-time)
  --max-results: int # The maximum number of results to return at one time. The default is 25.
  --next-token: string # The token for the next set of results.
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
    path: "/detect/mitigationactions/executions"
    query: [{name: taskId, var: task_id}, {name: violationId, var: violation_id}, {name: thingName, var: thing_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, violation_id: $violation_id, thing_name: $thing_name, start_time: $start_time, end_time: $end_time, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Device Defender ML Detect mitigation actions tasks. Requires permission to access the ListDetectMitigationActionsTasks (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /detect/mitigationactions/tasks
# Returns: record<tasks: table<taskId: string, taskStatus: string, taskStartTime: string, taskEndTime: string, target: record, violationEventOccurrenceRange: record, onlyActiveViolationsIncluded: bool, suppressedAlertsIncluded: bool, actionsDefinition: list, taskStatistics: record>, nextToken: string>
# operationId: ListDetectMitigationActionsTasks
export def "list-detect-mitigation-actions-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at one time. The default is 25.
  --next-token: string # The token for the next set of results.
  --start-time: string # A filter to limit results to those found after the specified time. You must specify either the startTime and endTime or the taskId, but not both. (required, format: date-time)
  --end-time: string # The end of the time period for which ML Detect mitigation actions tasks are returned. (required, format: date-time)
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
    path: "/detect/mitigationactions/tasks"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: startTime, var: start_time, required: true}, {name: endTime, var: end_time, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, start_time: $start_time, end_time: $end_time, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the set of dimensions that are defined for your Amazon Web Services accounts. Requires permission to access the ListDimensions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /dimensions
# Returns: record<dimensionNames: list<string>, nextToken: string>
# operationId: ListDimensions
export def "list-dimensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to retrieve at one time.
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
    path: "/dimensions"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of domain configurations for the user. This list is sorted alphabetically by domain configuration name. Requires permission to access the ListDomainConfigurations (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /domainConfigurations
# Returns: record<domainConfigurations: table<domainConfigurationName: string, domainConfigurationArn: string, serviceType: string>, nextMarker: string>
# operationId: ListDomainConfigurations
export def "list-domain-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results.
  --page-size: int # The result page size.
  --service-type: string@service-type-completer # The type of service delivered by the endpoint.
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
    path: "/domainConfigurations"
    query: [{name: marker, var: marker}, {name: pageSize, var: page_size}, {name: serviceType, var: service_type}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, page_size: $page_size, service_type: $service_type, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all your fleet metrics. Requires permission to access the ListFleetMetrics (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /fleet-metrics
# Returns: record<fleetMetrics: table<metricName: string, metricArn: string>, nextToken: string>
# operationId: ListFleetMetrics
export def "list-fleet-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return in this operation.
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
    path: "/fleet-metrics"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the search indices. Requires permission to access the ListIndices (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /indices
# Returns: record<indexNames: list<string>, nextToken: string>
# operationId: ListIndices
export def "list-indices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token used to get the next set of results, or null if there are no additional results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/indices"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the job executions for a job. Requires permission to access the ListJobExecutionsForJob (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /jobs/{jobId}/things
# Returns: record<executionSummaries: table<thingArn: string, jobExecutionSummary: record>, nextToken: string>
# operationId: ListJobExecutionsForJob
export def "list-job-executions-for-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # The status of the job.
  --max-results: int # The maximum number of results to be returned per request.
  --next-token: string # The token to retrieve the next set of results.
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
    path: "/jobs/{jobId}/things"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: status, var: status}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, status: $status, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the job executions for the specified thing. Requires permission to access the ListJobExecutionsForThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /things/{thingName}/jobs
# Returns: record<executionSummaries: table<jobId: string, jobExecutionSummary: record>, nextToken: string>
# operationId: ListJobExecutionsForThing
export def "list-job-executions-for-thing" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # An optional filter that lets you search for jobs that have the specified status.
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
  --max-results: int # The maximum number of results to be returned per request.
  --next-token: string # The token to retrieve the next set of results.
  --job-id: string # The unique identifier you assigned to this job when it was created.
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
    path: "/things/{thingName}/jobs"
    path_params: [{name: thingName, var: thing_name}]
    query: [{name: status, var: status}, {name: namespaceId, var: namespace_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, status: $status, namespace_id: $namespace_id, max_results: $max_results, next_token: $next_token, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of job templates. Requires permission to access the ListJobTemplates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /job-templates
# Returns: record<jobTemplates: table<jobTemplateArn: string, jobTemplateId: string, description: string, createdAt: string>, nextToken: string>
# operationId: ListJobTemplates
export def "list-job-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return in the list.
  --next-token: string # The token to use to return the next set of results in the list.
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
    path: "/job-templates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists jobs. Requires permission to access the ListJobs (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /jobs
# Returns: record<jobs: table<jobArn: string, jobId: string, thingGroupId: string, targetSelection: string, status: string, createdAt: string, lastUpdatedAt: string, completedAt: string, isConcurrent: bool>, nextToken: string>
# operationId: ListJobs
export def "list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # An optional filter that lets you search for jobs that have the specified status.
  --target-selection: string@target-selection-completer # Specifies whether the job will continue to run (CONTINUOUS), or will be complete after all those things specified as targets have completed the job (SNAPSHOT). If continuous, the job may also be run on a thing when a change is detected in a target. For example, a job will run on a thing when the thing is added to a target group, even after the job was completed by all things originally in the group. We recommend that you use continuous jobs instead of snapshot jobs for dynamic thing group targets. By using continuous jobs, devices that join the group receive the job execution even after the job has been created.
  --max-results: int # The maximum number of results to return per request.
  --next-token: string # The token to retrieve the next set of results.
  --thing-group-name: string # A filter that limits the returned jobs to those for the specified group.
  --thing-group-id: string # A filter that limits the returned jobs to those for the specified group.
  --namespace-id: string # The namespace used to indicate that a job is a customer-managed job. When you specify a value for this parameter, Amazon Web Services IoT Core sends jobs notifications to MQTT topics that contain the value in the following format. $aws/things/THING_NAME/jobs/JOB_ID/notify-namespace-NAMESPACE_ID/ The namespaceId feature is in public preview.
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
    path: "/jobs"
    query: [{name: status, var: status}, {name: targetSelection, var: target_selection}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: thingGroupName, var: thing_group_name}, {name: thingGroupId, var: thing_group_id}, {name: namespaceId, var: namespace_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, target_selection: $target_selection, max_results: $max_results, next_token: $next_token, thing_group_name: $thing_group_name, thing_group_id: $thing_group_id, namespace_id: $namespace_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of managed job templates.
#
# GET /managed-job-templates
# Returns: record<managedJobTemplates: table<templateArn: string, templateName: string, description: string, environments: list, templateVersion: string>, nextToken: string>
# operationId: ListManagedJobTemplates
export def "list-managed-job-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-name: string # An optional parameter for template name. If specified, only the versions of the managed job templates that have the specified template name will be returned.
  --max-results: int # Maximum number of entries that can be returned.
  --next-token: string # The token to retrieve the next set of results.
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
    path: "/managed-job-templates"
    query: [{name: templateName, var: template_name}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_name: $template_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the values reported for an IoT Device Defender metric (device-side metric, cloud-side metric, or custom metric) by the given thing during the specified time period.
#
# GET /metric-values
# Returns: record<metricDatumList: table<timestamp: string, value: record>, nextToken: string>
# operationId: ListMetricValues
export def "list-metric-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --thing-name: string # The name of the thing for which security profile metric values are returned. (required)
  --metric-name: string # The name of the security profile metric for which values are returned. (required)
  --dimension-name: string # The dimension name.
  --dimension-value-operator: string@dimension-value-operator-completer # The dimension value operator.
  --start-time: string # The start of the time period for which metric values are returned. (required, format: date-time)
  --end-time: string # The end of the time period for which metric values are returned. (required, format: date-time)
  --max-results: int # The maximum number of results to return at one time.
  --next-token: string # The token for the next set of results.
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
    path: "/metric-values"
    query: [{name: thingName, var: thing_name, required: true}, {name: metricName, var: metric_name, required: true}, {name: dimensionName, var: dimension_name}, {name: dimensionValueOperator, var: dimension_value_operator}, {name: startTime, var: start_time, required: true}, {name: endTime, var: end_time, required: true}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, metric_name: $metric_name, dimension_name: $dimension_name, dimension_value_operator: $dimension_value_operator, start_time: $start_time, end_time: $end_time, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all mitigation actions that match the specified filter criteria. Requires permission to access the ListMitigationActions (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /mitigationactions/actions
# Returns: record<actionIdentifiers: table<actionName: string, actionArn: string, creationDate: string>, nextToken: string>
# operationId: ListMitigationActions
export def "list-mitigation-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-type: string@action-type-completer # Specify a value to limit the result to mitigation actions with a specific action type.
  --max-results: int # The maximum number of results to return at one time. The default is 25.
  --next-token: string # The token for the next set of results.
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
    path: "/mitigationactions/actions"
    query: [{name: actionType, var: action_type}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_type: $action_type, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists OTA updates. Requires permission to access the ListOTAUpdates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /otaUpdates
# Returns: record<otaUpdates: table<otaUpdateId: string, otaUpdateArn: string, creationDate: string>, nextToken: string>
# operationId: ListOTAUpdates
export def "list-ota-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at one time.
  --next-token: string # A token used to retrieve the next set of results.
  --ota-update-status: string@ota-update-status-completer # The OTA update job status.
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
    path: "/otaUpdates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: otaUpdateStatus, var: ota_update_status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, ota_update_status: $ota_update_status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists certificates that are being transferred but not yet accepted. Requires permission to access the ListOutgoingCertificates (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /certificates-out-going
# Returns: record<outgoingCertificates: table<certificateArn: string, certificateId: string, transferredTo: string, transferDate: string, transferMessage: string, creationDate: string>, nextMarker: string>
# operationId: ListOutgoingCertificates
export def "list-outgoing-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The result page size.
  --marker: string # The marker for the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If True, the results are returned in ascending order, based on the creation date.
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
    path: "/certificates-out-going"
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your policies. Requires permission to access the ListPolicies (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /policies
# Returns: record<policies: table<policyName: string, policyArn: string>, nextMarker: string>
# operationId: ListPolicies
export def "list-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results.
  --page-size: int # The result page size.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If true, the results are returned in ascending creation order.
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
    path: "/policies"
    query: [{name: marker, var: marker}, {name: pageSize, var: page_size}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, page_size: $page_size, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the principals associated with the specified policy. Note: This action is deprecated and works as expected for backward compatibility, but we won't add enhancements. Use ListTargetsForPolicy instead. Requires permission to access the ListPolicyPrincipals (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /policy-principals
# DEPRECATED
# Returns: record<principals: list<string>, nextMarker: string>
# operationId: ListPolicyPrincipals
@deprecated
export def "list-policy-principals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results.
  --page-size: int # The result page size.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If true, the results are returned in ascending creation order.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-iot-policy: string # The policy name. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/policy-principals"
    query: [{name: marker, var: marker}, {name: pageSize, var: page_size}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-iot-policy, var: x_amzn_iot_policy, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, page_size: $page_size, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_iot_policy: $x_amzn_iot_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the policies attached to the specified principal. If you use an Cognito identity, the ID must be in AmazonCognito Identity format (https://docs.aws.amazon.com/cognitoidentity/latest/APIReference/API_GetCredentialsForIdentity.html#API_GetCredentialsForIdentity_RequestSyntax). Note: This action is deprecated and works as expected for backward compatibility, but we won't add enhancements. Use ListAttachedPolicies instead. Requires permission to access the ListPrincipalPolicies (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /principal-policies
# DEPRECATED
# Returns: record<policies: table<policyName: string, policyArn: string>, nextMarker: string>
# operationId: ListPrincipalPolicies
@deprecated
export def "list-principal-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The marker for the next set of results.
  --page-size: int # The result page size.
  --is-ascending-order: oneof<nothing, bool> # Specifies the order for results. If true, results are returned in ascending creation order.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-iot-principal: string # The principal. Valid principals are CertificateArn (arn:aws:iot:region:accountId:cert/certificateId), thingGroupArn (arn:aws:iot:region:accountId:thinggroup/groupName) and CognitoId (region:id). (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/principal-policies"
    query: [{name: marker, var: marker}, {name: pageSize, var: page_size}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-iot-principal, var: x_amzn_iot_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marker: $marker, page_size: $page_size, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_iot_principal: $x_amzn_iot_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the things associated with the specified principal. A principal can be X.509 certificates, IAM users, groups, and roles, Amazon Cognito identities or federated identities. Requires permission to access the ListPrincipalThings (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /principals/things
# Returns: record<things: list<string>, nextToken: string>
# operationId: ListPrincipalThings
export def "list-principal-things" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return in this operation.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amzn-principal: string # The principal. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/principals/things"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: x-amzn-principal, var: x_amzn_principal, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amzn_principal: $x_amzn_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The related resources of an Audit finding. The following resources can be returned from calling this API: DEVICE_CERTIFICATE CA_CERTIFICATE IOT_POLICY COGNITO_IDENTITY_POOL CLIENT_ID ACCOUNT_SETTINGS ROLE_ALIAS IAM_ROLE ISSUER_CERTIFICATE This API is similar to DescribeAuditFinding's RelatedResources (https://docs.aws.amazon.com/iot/latest/apireference/API_DescribeAuditFinding.html) but provides pagination and is not limited to 10 resources. When calling DescribeAuditFinding (https://docs.aws.amazon.com/iot/latest/apireference/API_DescribeAuditFinding.html) for the intermediate CA revoked for active device certificates check, RelatedResources will not be populated. You must use this API, ListRelatedResourcesForAuditFinding, to list the certificates.
#
# GET /audit/relatedResources
# Returns: record<relatedResources: table<resourceType: string, resourceIdentifier: record, additionalInfo: record>, nextToken: string>
# operationId: ListRelatedResourcesForAuditFinding
export def "list-related-resources-for-audit-finding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --finding-id: string # The finding Id. (required)
  --next-token: string # A token that can be used to retrieve the next set of results, or null if there are no additional results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/audit/relatedResources"
    query: [{name: findingId, var: finding_id, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    finding_id: $finding_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the role aliases registered in your account. Requires permission to access the ListRoleAliases (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /role-aliases
# Returns: record<roleAliases: list<string>, nextMarker: string>
# operationId: ListRoleAliases
export def "list-role-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of results to return at one time.
  --marker: string # A marker used to get the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Return the list of role aliases in ascending alphabetical order.
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
    path: "/role-aliases"
    query: [{name: pageSize, var: page_size}, {name: marker, var: marker}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, marker: $marker, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of your scheduled audits. Requires permission to access the ListScheduledAudits (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /audit/scheduledaudits
# Returns: record<scheduledAudits: table<scheduledAuditName: string, scheduledAuditArn: string, frequency: string, dayOfMonth: string, dayOfWeek: string>, nextToken: string>
# operationId: ListScheduledAudits
export def "list-scheduled-audits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time. The default is 25.
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
    path: "/audit/scheduledaudits"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Device Defender security profiles you've created. You can filter security profiles by dimension or custom metric. Requires permission to access the ListSecurityProfiles (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. dimensionName and metricName cannot be used in the same request.
#
# GET /security-profiles
# Returns: record<securityProfileIdentifiers: table<name: string, arn: string>, nextToken: string>
# operationId: ListSecurityProfiles
export def "list-security-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time.
  --dimension-name: string # A filter to limit results to the security profiles that use the defined dimension. Cannot be used with metricName
  --metric-name: string # The name of the custom metric. Cannot be used with dimensionName.
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
    path: "/security-profiles"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: dimensionName, var: dimension_name}, {name: metricName, var: metric_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, dimension_name: $dimension_name, metric_name: $metric_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Device Defender security profiles attached to a target (thing group). Requires permission to access the ListSecurityProfilesForTarget (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /security-profiles-for-target
# Returns: record<securityProfileTargetMappings: table<securityProfileIdentifier: record, target: record>, nextToken: string>
# operationId: ListSecurityProfilesForTarget
export def "list-security-profiles-for-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time.
  --recursive: oneof<nothing, bool> # If true, return child groups too.
  --security-profile-target-arn: string # The ARN of the target (thing group) whose attached security profiles you want to get. (required)
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
    path: "/security-profiles-for-target"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: recursive, var: recursive}, {name: securityProfileTargetArn, var: security_profile_target_arn, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, recursive: $recursive, security_profile_target_arn: $security_profile_target_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the streams in your Amazon Web Services account. Requires permission to access the ListStreams (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /streams
# Returns: record<streams: table<streamId: string, streamArn: string, streamVersion: int, description: string>, nextToken: string>
# operationId: ListStreams
export def "list-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return at a time.
  --next-token: string # A token used to get the next set of results.
  --is-ascending-order: oneof<nothing, bool> # Set to true to return the list of streams in ascending order.
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
    path: "/streams"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: isAscendingOrder, var: is_ascending_order}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, is_ascending_order: $is_ascending_order, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags (metadata) you have assigned to the resource. Requires permission to access the ListTagsForResource (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /tags
# Returns: record<tags: table<Key: string, Value: string>, nextToken: string>
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
  --resource-arn: string # The ARN of the resource. (required)
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
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
    path: "/tags"
    query: [{name: resourceArn, var: resource_arn, required: true}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List targets for the specified policy. Requires permission to access the ListTargetsForPolicy (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /policy-targets/{policyName}
# Returns: record<targets: list<string>, nextMarker: string>
# operationId: ListTargetsForPolicy
export def "list-targets-for-policy" [
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # A marker used to get the next set of results.
  --page-size: int # The maximum number of results to return at one time.
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
    path: "/policy-targets/{policyName}"
    path_params: [{name: policyName, var: policy_name}]
    query: [{name: marker, var: marker}, {name: pageSize, var: page_size}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_name: $policy_name, marker: $marker, page_size: $page_size, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the targets (thing groups) associated with a given Device Defender security profile. Requires permission to access the ListTargetsForSecurityProfile (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /security-profiles/{securityProfileName}/targets
# Returns: record<securityProfileTargets: table<arn: string>, nextToken: string>
# operationId: ListTargetsForSecurityProfile
export def "list-targets-for-security-profile" [
  security_profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/security-profiles/{securityProfileName}/targets"
    path_params: [{name: securityProfileName, var: security_profile_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    security_profile_name: $security_profile_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the thing groups in your account. Requires permission to access the ListThingGroups (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-groups
# Returns: record<thingGroups: table<groupName: string, groupArn: string>, nextToken: string>
# operationId: ListThingGroups
export def "list-thing-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
  --parent-group: string # A filter that limits the results to those with the specified parent group.
  --name-prefix-filter: string # A filter that limits the results to those with the specified name prefix.
  --recursive: oneof<nothing, bool> # If true, return child groups as well.
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
    path: "/thing-groups"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: parentGroup, var: parent_group}, {name: namePrefixFilter, var: name_prefix_filter}, {name: recursive, var: recursive}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, parent_group: $parent_group, name_prefix_filter: $name_prefix_filter, recursive: $recursive, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the thing groups to which the specified thing belongs. Requires permission to access the ListThingGroupsForThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /things/{thingName}/thing-groups
# Returns: record<thingGroups: table<groupName: string, groupArn: string>, nextToken: string>
# operationId: ListThingGroupsForThing
export def "list-thing-groups-for-thing" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/things/{thingName}/thing-groups"
    path_params: [{name: thingName, var: thing_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the principals associated with the specified thing. A principal can be X.509 certificates, IAM users, groups, and roles, Amazon Cognito identities or federated identities. Requires permission to access the ListThingPrincipals (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /things/{thingName}/principals
# Returns: record<principals: list<string>, nextToken: string>
# operationId: ListThingPrincipals
export def "list-thing-principals" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return in this operation.
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
    path: "/things/{thingName}/principals"
    path_params: [{name: thingName, var: thing_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_name: $thing_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about the thing registration tasks.
#
# GET /thing-registration-tasks/{taskId}/reports
# Returns: record<resourceLinks: list<string>, reportType: string, nextToken: string>
# operationId: ListThingRegistrationTaskReports
export def "list-thing-registration-task-reports" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of task report. (required)
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return per request.
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
    path: "/thing-registration-tasks/{taskId}/reports"
    path_params: [{name: taskId, var: task_id}]
    query: [{name: reportType, var: report_type, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, report_type: $report_type, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List bulk thing provisioning tasks. Requires permission to access the ListThingRegistrationTasks (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-registration-tasks
# Returns: record<taskIds: list<string>, nextToken: string>
# operationId: ListThingRegistrationTasks
export def "list-thing-registration-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
  --status: string@status-completer-4 # The status of the bulk thing provisioning task.
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
    path: "/thing-registration-tasks"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: status, var: status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, status: $status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a bulk thing provisioning task. Requires permission to access the StartThingRegistrationTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /thing-registration-tasks
# Returns: record<taskId: string>
# operationId: StartThingRegistrationTask
export def "start-thing-registration-task" [
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
  template_body: string # The provisioning template.
  input_file_bucket: string # The S3 bucket that contains the input file.
  input_file_key: string # The name of input file within the S3 bucket. This file contains a newline delimited JSON file. Each line contains the parameter values to provision one device (thing).
  role_arn: string # The IAM role ARN that grants permission the input file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/thing-registration-tasks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateBody, var: template_body}, {name: inputFileBucket, var: input_file_bucket}, {name: inputFileKey, var: input_file_key}, {name: roleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_body: $template_body, input_file_bucket: $input_file_bucket, input_file_key: $input_file_key, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the existing thing types. Requires permission to access the ListThingTypes (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-types
# Returns: record<thingTypes: table<thingTypeName: string, thingTypeArn: string, thingTypeProperties: record, thingTypeMetadata: record>, nextToken: string>
# operationId: ListThingTypes
export def "list-thing-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return in this operation.
  --thing-type-name: string # The name of the thing type.
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
    path: "/thing-types"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: thingTypeName, var: thing_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, thing_type_name: $thing_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your things. Use the attributeName and attributeValue parameters to filter your things. For example, calling ListThings with attributeName=Color and attributeValue=Red retrieves all things in the registry that contain an attribute Color with the value Red. For more information, see List Things (https://docs.aws.amazon.com/iot/latest/developerguide/thing-registry.html#list-things) from the Amazon Web Services IoT Core Developer Guide. Requires permission to access the ListThings (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. You will not be charged for calling this API if an Access denied error is returned. You will also not be charged if no attributes or pagination token was provided in request and no pagination token and no results were returned.
#
# GET /things
# Returns: record<things: table<thingName: string, thingTypeName: string, thingArn: string, attributes: record, version: int>, nextToken: string>
# operationId: ListThings
export def "list-things" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return in this operation.
  --attribute-name: string # The attribute name used to search for things.
  --attribute-value: string # The attribute value used to search for things.
  --thing-type-name: string # The name of the thing type used to search for things.
  --use-prefix-attribute-value: oneof<nothing, bool> # When true, the action returns the thing resources with attribute values that start with the attributeValue provided. When false, or not present, the action returns only the thing resources with attribute values that match the entire attributeValue provided.
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
    path: "/things"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: attributeName, var: attribute_name}, {name: attributeValue, var: attribute_value}, {name: thingTypeName, var: thing_type_name}, {name: usePrefixAttributeValue, var: use_prefix_attribute_value}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, attribute_name: $attribute_name, attribute_value: $attribute_value, thing_type_name: $thing_type_name, use_prefix_attribute_value: $use_prefix_attribute_value, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a thing in the device registry. RegisterThing calls other IoT control plane APIs. These calls might exceed your account level IoT Throttling Limits (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_iot) and cause throttle errors. Please contact Amazon Web Services Customer Support (https://console.aws.amazon.com/support/home) to raise your throttling limits if necessary. Requires permission to access the RegisterThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /things
# Returns: record<certificatePem: string, resourceArns: record>
# operationId: RegisterThing
export def "register-thing" [
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
  template_body: string # The provisioning template. See Provisioning Devices That Have Device Certificates (https://docs.aws.amazon.com/iot/latest/developerguide/provision-w-cert.html) for more information.
  --parameters: record # The parameters for provisioning a thing. See Provisioning Templates (https://docs.aws.amazon.com/iot/latest/developerguide/provision-template.html) for more information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/things"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateBody, var: template_body}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_body: $template_body, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the things you have added to the given billing group. Requires permission to access the ListThingsInBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /billing-groups/{billingGroupName}/things
# Returns: record<things: list<string>, nextToken: string>
# operationId: ListThingsInBillingGroup
export def "list-things-in-billing-group" [
  billing_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return per request.
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
    path: "/billing-groups/{billingGroupName}/things"
    path_params: [{name: billingGroupName, var: billing_group_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_group_name: $billing_group_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the things in the specified group. Requires permission to access the ListThingsInThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /thing-groups/{thingGroupName}/things
# Returns: record<things: list<string>, nextToken: string>
# operationId: ListThingsInThingGroup
export def "list-things-in-thing-group" [
  thing_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # When true, list things in this thing group and in all child groups as well.
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/thing-groups/{thingGroupName}/things"
    path_params: [{name: thingGroupName, var: thing_group_name}]
    query: [{name: recursive, var: recursive}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    thing_group_name: $thing_group_name, recursive: $recursive, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the rules for the specific topic. Requires permission to access the ListTopicRules (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /rules
# Returns: record<rules: table<ruleArn: string, ruleName: string, topicPattern: string, createdAt: string, ruleDisabled: bool>, nextToken: string>
# operationId: ListTopicRules
export def "list-topic-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # The topic.
  --max-results: int # The maximum number of results to return.
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --rule-disabled: oneof<nothing, bool> # Specifies whether the rule is disabled.
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
    path: "/rules"
    query: [{name: topic, var: topic}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: ruleDisabled, var: rule_disabled}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    topic: $topic, max_results: $max_results, next_token: $next_token, rule_disabled: $rule_disabled, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists logging levels. Requires permission to access the ListV2LoggingLevels (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /v2LoggingLevel
# Returns: record<logTargetConfigurations: table<logTarget: record, logLevel: string>, nextToken: string>
# operationId: ListV2LoggingLevels
export def "list-v2-logging-levels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-type: string@target-type-completer # The type of resource for which you are configuring logging. Must be THING_Group.
  --next-token: string # To retrieve the next set of results, the nextToken value from a previous response; otherwise null to receive the first set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/v2LoggingLevel"
    query: [{name: targetType, var: target_type}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    target_type: $target_type, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the logging level. Requires permission to access the SetV2LoggingLevel (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /v2LoggingLevel
# operationId: SetV2LoggingLevel
export def "set-v2-logging-level" [
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
  log_target: record # A log target. — shape: {targetType?: "DEFAULT"|"THING_GROUP"|"CLIENT_ID"|"SOURCE_IP"|"PRINCIPAL_ID", targetName?: string}
  log_level: string@log-level-completer # The log level.
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2LoggingLevel"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: logTarget, var: log_target}, {name: logLevel, var: log_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, log_target: $log_target, log_level: $log_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Device Defender security profile violations discovered during the given time period. You can use filters to limit the results to those alerts issued for a particular security profile, behavior, or thing (device). Requires permission to access the ListViolationEvents (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# GET /violation-events
# Returns: record<violationEvents: table<violationId: string, thingName: string, securityProfileName: string, behavior: record, metricValue: record, violationEventAdditionalInfo: record, violationEventType: string, verificationState: string, verificationStateDescription: string, violationEventTime: string>, nextToken: string>
# operationId: ListViolationEvents
export def "list-violation-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # The start time for the alerts to be listed. (required, format: date-time)
  --end-time: string # The end time for the alerts to be listed. (required, format: date-time)
  --thing-name: string # A filter to limit results to those alerts caused by the specified thing.
  --security-profile-name: string # A filter to limit results to those alerts generated by the specified security profile.
  --behavior-criteria-type: string@behavior-criteria-type-completer # The criteria for a behavior.
  --list-suppressed-alerts: oneof<nothing, bool> # A list of all suppressed alerts.
  --verification-state: string@verification-state-completer # The verification state of the violation (detect alarm).
  --next-token: string # The token for the next set of results.
  --max-results: int # The maximum number of results to return at one time.
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
    path: "/violation-events"
    query: [{name: startTime, var: start_time, required: true}, {name: endTime, var: end_time, required: true}, {name: thingName, var: thing_name}, {name: securityProfileName, var: security_profile_name}, {name: behaviorCriteriaType, var: behavior_criteria_type}, {name: listSuppressedAlerts, var: list_suppressed_alerts}, {name: verificationState, var: verification_state}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, thing_name: $thing_name, security_profile_name: $security_profile_name, behavior_criteria_type: $behavior_criteria_type, list_suppressed_alerts: $list_suppressed_alerts, verification_state: $verification_state, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a verification state and provide a description of that verification state on a violation (detect alarm).
#
# POST /violations/verification-state/{violationId}
# Returns: record
# operationId: PutVerificationStateOnViolation
export def "put-verification-state-on-violation" [
  violation_id: string
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
  verification_state: string@verification-state-completer # The verification state of the violation.
  --verification-state-description: string # The description of the verification state of the violation (detect alarm).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/violations/verification-state/{violationId}"
    path_params: [{name: violationId, var: violation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: verificationState, var: verification_state}, {name: verificationStateDescription, var: verification_state_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    violation_id: $violation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, verification_state: $verification_state, verification_state_description: $verification_state_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a CA certificate with Amazon Web Services IoT Core. There is no limit to the number of CA certificates you can register in your Amazon Web Services account. You can register up to 10 CA certificates with the same CA subject field per Amazon Web Services account. Requires permission to access the RegisterCACertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /cacertificate
# Returns: record<certificateArn: string, certificateId: string>
# operationId: RegisterCACertificate
export def "register-ca-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-active: oneof<nothing, bool> # A boolean value that specifies if the CA certificate is set to active. Valid values: ACTIVE | INACTIVE
  --allow-auto-registration: oneof<nothing, bool> # Allows this CA certificate to be used for auto registration of device certificates.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  ca_certificate: string # The PEM of a certificate.
  --verification-certificate: string # The PEM of a certificate.
  --registration-config: record # The registration configuration. — shape: {templateBody?: string, roleArn?: string, templateName?: string}
  --tags: list # Metadata which can be used to manage the CA certificate. For URI Request parameters use format: ...key1=value1&key2=value2... For the CLI command-line parameter use format: &&tags "key1=value1&key2=value2..." For the cli-input-json file use format: "tags": "key1=value1&key2=value2..." — item shape: {Key: string, Value?: string}
  --certificate-mode: string@certificate-mode-completer # Describes the certificate mode in which the Certificate Authority (CA) will be registered. If the verificationCertificate field is not provided, set certificateMode to be SNI_ONLY. If the verificationCertificate field is provided, set certificateMode to be DEFAULT. When certificateMode is not provided, it defaults to DEFAULT. All the device certificates that are registered using this CA will be registered in the same certificate mode as the CA. For more information about certificate mode for device certificates, see certificate mode (https://docs.aws.amazon.com/iot/latest/apireference/API_CertificateDescription.html#iot-Type-CertificateDescription-certificateMode).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cacertificate"
    query: [{name: setAsActive, var: set_as_active}, {name: allowAutoRegistration, var: allow_auto_registration}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: caCertificate, var: ca_certificate}, {name: verificationCertificate, var: verification_certificate}, {name: registrationConfig, var: registration_config}, {name: tags, var: tags}, {name: certificateMode, var: certificate_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    set_as_active: $set_as_active, allow_auto_registration: $allow_auto_registration, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ca_certificate: $ca_certificate, verification_certificate: $verification_certificate, registration_config: $registration_config, tags: $tags, certificate_mode: $certificate_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a device certificate with IoT in the same certificate mode (https://docs.aws.amazon.com/iot/latest/apireference/API_CertificateDescription.html#iot-Type-CertificateDescription-certificateMode) as the signing CA. If you have more than one CA certificate that has the same subject field, you must specify the CA certificate that was used to sign the device certificate being registered. Requires permission to access the RegisterCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /certificate/register
# Returns: record<certificateArn: string, certificateId: string>
# operationId: RegisterCertificate
export def "register-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set-as-active: oneof<nothing, bool> # A boolean value that specifies if the certificate is set to active. Valid values: ACTIVE | INACTIVE
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  certificate_pem: string # The PEM of a certificate.
  --ca-certificate-pem: string # The PEM of a certificate.
  --status: string@status-completer-5 # The status of the register certificate request. Valid values that you can use include ACTIVE, INACTIVE, and REVOKED.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificate/register"
    query: [{name: setAsActive, var: set_as_active}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificatePem, var: certificate_pem}, {name: caCertificatePem, var: ca_certificate_pem}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    set_as_active: $set_as_active, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, certificate_pem: $certificate_pem, ca_certificate_pem: $ca_certificate_pem, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a certificate that does not have a certificate authority (CA). For supported certificates, consult Certificate signing algorithms supported by IoT (https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html#x509-cert-algorithms).
#
# POST /certificate/register-no-ca
# Returns: record<certificateArn: string, certificateId: string>
# operationId: RegisterCertificateWithoutCA
export def "register-certificate-without-ca" [
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
  certificate_pem: string # The PEM of a certificate.
  --status: string@status-completer-5 # The status of the register certificate request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificate/register-no-ca"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificatePem, var: certificate_pem}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, certificate_pem: $certificate_pem, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects a pending certificate transfer. After IoT rejects a certificate transfer, the certificate status changes from PENDING_TRANSFER to INACTIVE. To check for pending certificate transfers, call ListCertificates to enumerate your certificates. This operation can only be called by the transfer destination. After it is called, the certificate will be returned to the source's account in the INACTIVE state. Requires permission to access the RejectCertificateTransfer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PATCH /reject-certificate-transfer/{certificateId}
# operationId: RejectCertificateTransfer
export def "reject-certificate-transfer" [
  certificate_id: string
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
  --reject-reason: string # The reason the certificate transfer was rejected.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/reject-certificate-transfer/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: rejectReason, var: reject_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, reject_reason: $reject_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the given thing from the billing group. Requires permission to access the RemoveThingFromBillingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. This call is asynchronous. It might take several seconds for the detachment to propagate.
#
# PUT /billing-groups/removeThingFromBillingGroup
# Returns: record
# operationId: RemoveThingFromBillingGroup
export def "remove-thing-from-billing-group" [
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
  --billing-group-name: string # The name of the billing group.
  --billing-group-arn: string # The ARN of the billing group.
  --thing-name: string # The name of the thing to be removed from the billing group.
  --thing-arn: string # The ARN of the thing to be removed from the billing group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/billing-groups/removeThingFromBillingGroup"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: billingGroupName, var: billing_group_name}, {name: billingGroupArn, var: billing_group_arn}, {name: thingName, var: thing_name}, {name: thingArn, var: thing_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, billing_group_name: $billing_group_name, billing_group_arn: $billing_group_arn, thing_name: $thing_name, thing_arn: $thing_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the specified thing from the specified group. You must specify either a thingGroupArn or a thingGroupName to identify the thing group and either a thingArn or a thingName to identify the thing to remove from the thing group. Requires permission to access the RemoveThingFromThingGroup (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /thing-groups/removeThingFromThingGroup
# Returns: record
# operationId: RemoveThingFromThingGroup
export def "remove-thing-from-thing-group" [
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
  --thing-group-name: string # The group name.
  --thing-group-arn: string # The group ARN.
  --thing-name: string # The name of the thing to remove from the group.
  --thing-arn: string # The ARN of the thing to remove from the group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/thing-groups/removeThingFromThingGroup"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingGroupName, var: thing_group_name}, {name: thingGroupArn, var: thing_group_arn}, {name: thingName, var: thing_name}, {name: thingArn, var: thing_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_group_name: $thing_group_name, thing_group_arn: $thing_group_arn, thing_name: $thing_name, thing_arn: $thing_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The query search index. Requires permission to access the SearchIndex (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /indices/search
# Returns: record<nextToken: string, things: table<thingName: string, thingId: string, thingTypeName: string, thingGroupNames: list, attributes: record, shadow: string, deviceDefender: string, connectivity: record>, thingGroups: table<thingGroupName: string, thingGroupId: string, thingGroupDescription: string, attributes: record, parentGroupNames: list>>
# operationId: SearchIndex
export def "search-index" [
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
  --index-name: string # The search index name.
  query_string: string # The search query string. For more information about the search query syntax, see Query syntax (https://docs.aws.amazon.com/iot/latest/developerguide/query-syntax.html).
  --next-token: string # The token used to get the next set of results, or null if there are no additional results.
  --max-results: int # The maximum number of results to return at one time.
  --query-version: string # The query version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/indices/search"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: indexName, var: index_name}, {name: queryString, var: query_string}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: queryVersion, var: query_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, index_name: $index_name, query_string: $query_string, next_token: $next_token, max_results: $max_results, query_version: $query_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an on-demand Device Defender audit. Requires permission to access the StartOnDemandAuditTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /audit/tasks
# Returns: record<taskId: string>
# operationId: StartOnDemandAuditTask
export def "start-on-demand-audit-task" [
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
  target_check_names: list<string> # Which checks are performed during the audit. The checks you specify must be enabled for your account or an exception occurs. Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or UpdateAccountAuditConfiguration to select which checks are enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/audit/tasks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetCheckNames, var: target_check_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, target_check_names: $target_check_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a bulk thing provisioning task. Requires permission to access the StopThingRegistrationTask (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /thing-registration-tasks/{taskId}/cancel
# Returns: record
# operationId: StopThingRegistrationTask
export def "stop-thing-registration-task" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/thing-registration-tasks/{taskId}/cancel"
    path_params: [{name: taskId, var: task_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds to or modifies the tags of the given resource. Tags are metadata which can be used to manage a resource. Requires permission to access the TagResource (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /tags
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
  resource_arn: string # The ARN of the resource.
  tags: list # The new or modified tags for the resource. — item shape: {Key: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests if a specified principal is authorized to perform an IoT action on a specified resource. Use this to test and debug the authorization behavior of devices that connect to the IoT device gateway. Requires permission to access the TestAuthorization (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /test-authorization
# Returns: record<authResults: table<authInfo: record, allowed: record, denied: record, authDecision: string, missingContextValues: list>>
# operationId: TestAuthorization
export def "test-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The MQTT client ID.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --principal: string # The principal. Valid principals are CertificateArn (arn:aws:iot:region:accountId:cert/certificateId), thingGroupArn (arn:aws:iot:region:accountId:thinggroup/groupName) and CognitoId (region:id).
  --cognito-identity-pool-id: string # The Cognito identity pool ID.
  auth_infos: list # A list of authorization info objects. Simulating authorization will create a response for each authInfo object in the list. — item shape: {actionType?: "PUBLISH"|"SUBSCRIBE"|"RECEIVE"|"CONNECT", resources: list<string>}
  --policy-names-to-add: list<string> # When testing custom authorization, the policies specified here are treated as if they are attached to the principal being authorized.
  --policy-names-to-skip: list<string> # When testing custom authorization, the policies specified here are treated as if they are not attached to the principal being authorized.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/test-authorization"
    query: [{name: clientId, var: client_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: principal, var: principal}, {name: cognitoIdentityPoolId, var: cognito_identity_pool_id}, {name: authInfos, var: auth_infos}, {name: policyNamesToAdd, var: policy_names_to_add}, {name: policyNamesToSkip, var: policy_names_to_skip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, principal: $principal, cognito_identity_pool_id: $cognito_identity_pool_id, auth_infos: $auth_infos, policy_names_to_add: $policy_names_to_add, policy_names_to_skip: $policy_names_to_skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests a custom authorization behavior by invoking a specified custom authorizer. Use this to test and debug the custom authorization behavior of devices that connect to the IoT device gateway. Requires permission to access the TestInvokeAuthorizer (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /authorizer/{authorizerName}/test
# Returns: record<isAuthenticated: bool, principalId: string, policyDocuments: list<string>, refreshAfterInSeconds: int, disconnectAfterInSeconds: int>
# operationId: TestInvokeAuthorizer
export def "test-invoke-authorizer" [
  authorizer_name: string
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
  --body-token: string # The token returned by your custom authentication service. (spec name: token)
  --token-signature: string # The signature made with the token and your custom authentication service's private key. This value must be Base-64-encoded.
  --http-context: record # Specifies the HTTP context to use for the test authorizer request. — shape: {headers?: record, queryString?: string}
  --mqtt-context: record # Specifies the MQTT context to use for the test authorizer request — shape: {username?: string, password?: string, clientId?: string}
  --tls-context: record # Specifies the TLS context to use for the test authorizer request. — shape: {serverName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authorizer/{authorizerName}/test"
    path_params: [{name: authorizerName, var: authorizer_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: token, var: body_token}, {name: tokenSignature, var: token_signature}, {name: httpContext, var: http_context}, {name: mqttContext, var: mqtt_context}, {name: tlsContext, var: tls_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorizer_name: $authorizer_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_token: $body_token, token_signature: $token_signature, http_context: $http_context, mqtt_context: $mqtt_context, tls_context: $tls_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers the specified certificate to the specified Amazon Web Services account. Requires permission to access the TransferCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. You can cancel the transfer until it is acknowledged by the recipient. No notification is sent to the transfer destination's account. It is up to the caller to notify the transfer target. The certificate being transferred must not be in the ACTIVE state. You can use the UpdateCertificate action to deactivate it. The certificate must not have any policies attached to it. You can use the DetachPolicy action to detach them.
#
# PATCH /transfer-certificate/{certificateId}
# Returns: record<transferredCertificateArn: string>
# operationId: TransferCertificate
export def "transfer-certificate" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-aws-account: string # The Amazon Web Services account. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --transfer-message: string # The transfer message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transfer-certificate/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    query: [{name: targetAwsAccount, var: target_aws_account, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: transferMessage, var: transfer_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, target_aws_account: $target_aws_account, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, transfer_message: $transfer_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the given tags (metadata) from the resource. Requires permission to access the UntagResource (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /untag
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
  resource_arn: string # The ARN of the resource.
  tag_keys: list<string> # A list of the keys of the tags to be removed from the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/untag"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Device Defender audit suppression.
#
# PATCH /audit/suppressions/update
# Returns: record
# operationId: UpdateAuditSuppression
export def "update-audit-suppression" [
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
  check_name: string # An audit check name. Checks must be enabled for your account. (Use DescribeAccountAuditConfiguration to see the list of all checks, including those that are enabled or use UpdateAccountAuditConfiguration to select which checks are enabled.)
  resource_identifier: record # Information that identifies the noncompliant resource. — shape: {deviceCertificateId?: string, caCertificateId?: string, cognitoIdentityPoolId?: string, clientId?: string, policyVersionIdentifier?: record, account?: string, iamRoleArn?: string, roleAliasArn?: string, issuerCertificateIdentifier?: record, deviceCertificateArn?: string}
  --expiration-date: string # The expiration date (epoch timestamp in seconds) that you want the suppression to adhere to. (format: date-time)
  --suppress-indefinitely: oneof<nothing, bool> # Indicates whether a suppression should exist indefinitely or not.
  --description: string # The description of the audit suppression.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/audit/suppressions/update"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkName, var: check_name}, {name: resourceIdentifier, var: resource_identifier}, {name: expirationDate, var: expiration_date}, {name: suppressIndefinitely, var: suppress_indefinitely}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, check_name: $check_name, resource_identifier: $resource_identifier, expiration_date: $expiration_date, suppress_indefinitely: $suppress_indefinitely, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of the specified certificate. This operation is idempotent. Requires permission to access the UpdateCertificate (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action. Certificates must be in the ACTIVE state to authenticate devices that use a certificate to connect to IoT. Within a few minutes of updating a certificate from the ACTIVE state to any other state, IoT disconnects all devices that used that certificate to connect. Devices cannot use a certificate that is not in the ACTIVE state to reconnect.
#
# PUT /certificates/{certificateId}
# operationId: UpdateCertificate
export def "update-certificate" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-status: string@new-status-completer-1 # The new status. Note: Setting the status to PENDING_TRANSFER or PENDING_ACTIVATION will result in an exception being thrown. PENDING_TRANSFER and PENDING_ACTIVATION are statuses used internally by IoT. They are not intended for developer use. Note: The status value REGISTER_INACTIVE is deprecated and should not be used. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: put
    path: "/certificates/{certificateId}"
    path_params: [{name: certificateId, var: certificate_id}]
    query: [{name: newStatus, var: new_status, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_id: $certificate_id, new_status: $new_status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the groups to which the thing belongs. Requires permission to access the UpdateThingGroupsForThing (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# PUT /thing-groups/updateThingGroupsForThing
# Returns: record
# operationId: UpdateThingGroupsForThing
export def "update-thing-groups-for-thing" [
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
  --thing-name: string # The thing whose group memberships will be updated.
  --thing-groups-to-add: list<string> # The groups to which the thing will be added.
  --thing-groups-to-remove: list<string> # The groups from which the thing will be removed.
  --override-dynamic-groups: oneof<nothing, bool> # Override dynamic thing groups with static thing groups when 10-group limit is reached. If a thing belongs to 10 thing groups, and one or more of those groups are dynamic thing groups, adding a thing to a static group removes the thing from the last dynamic group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/thing-groups/updateThingGroupsForThing"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: thingName, var: thing_name}, {name: thingGroupsToAdd, var: thing_groups_to_add}, {name: thingGroupsToRemove, var: thing_groups_to_remove}, {name: overrideDynamicGroups, var: override_dynamic_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, thing_name: $thing_name, thing_groups_to_add: $thing_groups_to_add, thing_groups_to_remove: $thing_groups_to_remove, override_dynamic_groups: $override_dynamic_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates a Device Defender security profile behaviors specification. Requires permission to access the ValidateSecurityProfileBehaviors (https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsiot.html#awsiot-actions-as-permissions) action.
#
# POST /security-profile-behaviors/validate
# Returns: record<valid: bool, validationErrors: table<errorMessage: string>>
# operationId: ValidateSecurityProfileBehaviors
export def "validate-security-profile-behaviors" [
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
  behaviors: list # Specifies the behaviors that, when violated by a device (thing), cause an alert. — item shape: {name: string, metric?: string, metricDimension?: record, criteria?: record, suppressAlerts?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/security-profile-behaviors/validate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: behaviors, var: behaviors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, behaviors: $behaviors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
