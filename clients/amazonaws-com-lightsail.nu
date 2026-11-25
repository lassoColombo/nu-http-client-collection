# Auto-generated client for Amazon Lightsail v2016-11-28
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lightsail/2016-11-28/openapi.json
# Auth: --token flag or $env.AMAZON_LIGHTSAIL_TOKEN

const CLIENT = {
  base_url: "http://lightsail.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_LIGHTSAIL_TOKEN"
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

def base-url-completer [] { ["http://lightsail.us-east-1.amazonaws.com" "http://lightsail.us-east-2.amazonaws.com" "http://lightsail.us-west-1.amazonaws.com" "http://lightsail.us-west-2.amazonaws.com" "http://lightsail.us-gov-west-1.amazonaws.com" "http://lightsail.us-gov-east-1.amazonaws.com" "http://lightsail.ca-central-1.amazonaws.com" "http://lightsail.eu-north-1.amazonaws.com" "http://lightsail.eu-west-1.amazonaws.com" "http://lightsail.eu-west-2.amazonaws.com" "http://lightsail.eu-west-3.amazonaws.com" "http://lightsail.eu-central-1.amazonaws.com" "http://lightsail.eu-south-1.amazonaws.com" "http://lightsail.af-south-1.amazonaws.com" "http://lightsail.ap-northeast-1.amazonaws.com" "http://lightsail.ap-northeast-2.amazonaws.com" "http://lightsail.ap-northeast-3.amazonaws.com" "http://lightsail.ap-southeast-1.amazonaws.com" "http://lightsail.ap-southeast-2.amazonaws.com" "http://lightsail.ap-east-1.amazonaws.com" "http://lightsail.ap-south-1.amazonaws.com" "http://lightsail.sa-east-1.amazonaws.com" "http://lightsail.me-south-1.amazonaws.com" "https://lightsail.us-east-1.amazonaws.com" "https://lightsail.us-east-2.amazonaws.com" "https://lightsail.us-west-1.amazonaws.com" "https://lightsail.us-west-2.amazonaws.com" "https://lightsail.us-gov-west-1.amazonaws.com" "https://lightsail.us-gov-east-1.amazonaws.com" "https://lightsail.ca-central-1.amazonaws.com" "https://lightsail.eu-north-1.amazonaws.com" "https://lightsail.eu-west-1.amazonaws.com" "https://lightsail.eu-west-2.amazonaws.com" "https://lightsail.eu-west-3.amazonaws.com" "https://lightsail.eu-central-1.amazonaws.com" "https://lightsail.eu-south-1.amazonaws.com" "https://lightsail.af-south-1.amazonaws.com" "https://lightsail.ap-northeast-1.amazonaws.com" "https://lightsail.ap-northeast-2.amazonaws.com" "https://lightsail.ap-northeast-3.amazonaws.com" "https://lightsail.ap-southeast-1.amazonaws.com" "https://lightsail.ap-southeast-2.amazonaws.com" "https://lightsail.ap-east-1.amazonaws.com" "https://lightsail.ap-south-1.amazonaws.com" "https://lightsail.sa-east-1.amazonaws.com" "https://lightsail.me-south-1.amazonaws.com" "http://lightsail.cn-north-1.amazonaws.com.cn" "http://lightsail.cn-northwest-1.amazonaws.com.cn" "https://lightsail.cn-north-1.amazonaws.com.cn" "https://lightsail.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Lightsail_20161128.AllocateStaticIp"] }
def x-amz-target-completer-1 [] { ["Lightsail_20161128.AttachCertificateToDistribution"] }
def x-amz-target-completer-2 [] { ["Lightsail_20161128.AttachDisk"] }
def x-amz-target-completer-3 [] { ["Lightsail_20161128.AttachInstancesToLoadBalancer"] }
def x-amz-target-completer-4 [] { ["Lightsail_20161128.AttachLoadBalancerTlsCertificate"] }
def x-amz-target-completer-5 [] { ["Lightsail_20161128.AttachStaticIp"] }
def x-amz-target-completer-6 [] { ["Lightsail_20161128.CloseInstancePublicPorts"] }
def source-region-completer [] { ["ap-northeast-1" "ap-northeast-2" "ap-south-1" "ap-southeast-1" "ap-southeast-2" "ca-central-1" "eu-central-1" "eu-north-1" "eu-west-1" "eu-west-2" "eu-west-3" "us-east-1" "us-east-2" "us-west-1" "us-west-2"] }
def x-amz-target-completer-7 [] { ["Lightsail_20161128.CopySnapshot"] }
def x-amz-target-completer-8 [] { ["Lightsail_20161128.CreateBucket"] }
def x-amz-target-completer-9 [] { ["Lightsail_20161128.CreateBucketAccessKey"] }
def x-amz-target-completer-10 [] { ["Lightsail_20161128.CreateCertificate"] }
def x-amz-target-completer-11 [] { ["Lightsail_20161128.CreateCloudFormationStack"] }
def protocol-completer [] { ["Email" "SMS"] }
def x-amz-target-completer-12 [] { ["Lightsail_20161128.CreateContactMethod"] }
def power-completer [] { ["large" "medium" "micro" "nano" "small" "xlarge"] }
def x-amz-target-completer-13 [] { ["Lightsail_20161128.CreateContainerService"] }
def x-amz-target-completer-14 [] { ["Lightsail_20161128.CreateContainerServiceDeployment"] }
def x-amz-target-completer-15 [] { ["Lightsail_20161128.CreateContainerServiceRegistryLogin"] }
def x-amz-target-completer-16 [] { ["Lightsail_20161128.CreateDisk"] }
def x-amz-target-completer-17 [] { ["Lightsail_20161128.CreateDiskFromSnapshot"] }
def x-amz-target-completer-18 [] { ["Lightsail_20161128.CreateDiskSnapshot"] }
def ip-address-type-completer [] { ["dualstack" "ipv4"] }
def x-amz-target-completer-19 [] { ["Lightsail_20161128.CreateDistribution"] }
def x-amz-target-completer-20 [] { ["Lightsail_20161128.CreateDomain"] }
def x-amz-target-completer-21 [] { ["Lightsail_20161128.CreateDomainEntry"] }
def x-amz-target-completer-22 [] { ["Lightsail_20161128.CreateGUISessionAccessDetails"] }
def x-amz-target-completer-23 [] { ["Lightsail_20161128.CreateInstanceSnapshot"] }
def x-amz-target-completer-24 [] { ["Lightsail_20161128.CreateInstances"] }
def x-amz-target-completer-25 [] { ["Lightsail_20161128.CreateInstancesFromSnapshot"] }
def x-amz-target-completer-26 [] { ["Lightsail_20161128.CreateKeyPair"] }
def x-amz-target-completer-27 [] { ["Lightsail_20161128.CreateLoadBalancer"] }
def x-amz-target-completer-28 [] { ["Lightsail_20161128.CreateLoadBalancerTlsCertificate"] }
def x-amz-target-completer-29 [] { ["Lightsail_20161128.CreateRelationalDatabase"] }
def x-amz-target-completer-30 [] { ["Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"] }
def x-amz-target-completer-31 [] { ["Lightsail_20161128.CreateRelationalDatabaseSnapshot"] }
def x-amz-target-completer-32 [] { ["Lightsail_20161128.DeleteAlarm"] }
def x-amz-target-completer-33 [] { ["Lightsail_20161128.DeleteAutoSnapshot"] }
def x-amz-target-completer-34 [] { ["Lightsail_20161128.DeleteBucket"] }
def x-amz-target-completer-35 [] { ["Lightsail_20161128.DeleteBucketAccessKey"] }
def x-amz-target-completer-36 [] { ["Lightsail_20161128.DeleteCertificate"] }
def x-amz-target-completer-37 [] { ["Lightsail_20161128.DeleteContactMethod"] }
def x-amz-target-completer-38 [] { ["Lightsail_20161128.DeleteContainerImage"] }
def x-amz-target-completer-39 [] { ["Lightsail_20161128.DeleteContainerService"] }
def x-amz-target-completer-40 [] { ["Lightsail_20161128.DeleteDisk"] }
def x-amz-target-completer-41 [] { ["Lightsail_20161128.DeleteDiskSnapshot"] }
def x-amz-target-completer-42 [] { ["Lightsail_20161128.DeleteDistribution"] }
def x-amz-target-completer-43 [] { ["Lightsail_20161128.DeleteDomain"] }
def x-amz-target-completer-44 [] { ["Lightsail_20161128.DeleteDomainEntry"] }
def x-amz-target-completer-45 [] { ["Lightsail_20161128.DeleteInstance"] }
def x-amz-target-completer-46 [] { ["Lightsail_20161128.DeleteInstanceSnapshot"] }
def x-amz-target-completer-47 [] { ["Lightsail_20161128.DeleteKeyPair"] }
def x-amz-target-completer-48 [] { ["Lightsail_20161128.DeleteKnownHostKeys"] }
def x-amz-target-completer-49 [] { ["Lightsail_20161128.DeleteLoadBalancer"] }
def x-amz-target-completer-50 [] { ["Lightsail_20161128.DeleteLoadBalancerTlsCertificate"] }
def x-amz-target-completer-51 [] { ["Lightsail_20161128.DeleteRelationalDatabase"] }
def x-amz-target-completer-52 [] { ["Lightsail_20161128.DeleteRelationalDatabaseSnapshot"] }
def x-amz-target-completer-53 [] { ["Lightsail_20161128.DetachCertificateFromDistribution"] }
def x-amz-target-completer-54 [] { ["Lightsail_20161128.DetachDisk"] }
def x-amz-target-completer-55 [] { ["Lightsail_20161128.DetachInstancesFromLoadBalancer"] }
def x-amz-target-completer-56 [] { ["Lightsail_20161128.DetachStaticIp"] }
def add-on-type-completer [] { ["AutoSnapshot" "StopInstanceOnIdle"] }
def x-amz-target-completer-57 [] { ["Lightsail_20161128.DisableAddOn"] }
def x-amz-target-completer-58 [] { ["Lightsail_20161128.DownloadDefaultKeyPair"] }
def x-amz-target-completer-59 [] { ["Lightsail_20161128.EnableAddOn"] }
def x-amz-target-completer-60 [] { ["Lightsail_20161128.ExportSnapshot"] }
def x-amz-target-completer-61 [] { ["Lightsail_20161128.GetActiveNames"] }
def x-amz-target-completer-62 [] { ["Lightsail_20161128.GetAlarms"] }
def x-amz-target-completer-63 [] { ["Lightsail_20161128.GetAutoSnapshots"] }
def app-category-completer [] { ["LfR"] }
def x-amz-target-completer-64 [] { ["Lightsail_20161128.GetBlueprints"] }
def x-amz-target-completer-65 [] { ["Lightsail_20161128.GetBucketAccessKeys"] }
def x-amz-target-completer-66 [] { ["Lightsail_20161128.GetBucketBundles"] }
def metric-name-completer [] { ["BucketSizeBytes" "NumberOfObjects"] }
def unit-completer [] { ["Bits" "Bits/Second" "Bytes" "Bytes/Second" "Count" "Count/Second" "Gigabits" "Gigabits/Second" "Gigabytes" "Gigabytes/Second" "Kilobits" "Kilobits/Second" "Kilobytes" "Kilobytes/Second" "Megabits" "Megabits/Second" "Megabytes" "Megabytes/Second" "Microseconds" "Milliseconds" "None" "Percent" "Seconds" "Terabits" "Terabits/Second" "Terabytes" "Terabytes/Second"] }
def x-amz-target-completer-67 [] { ["Lightsail_20161128.GetBucketMetricData"] }
def x-amz-target-completer-68 [] { ["Lightsail_20161128.GetBuckets"] }
def x-amz-target-completer-69 [] { ["Lightsail_20161128.GetBundles"] }
def x-amz-target-completer-70 [] { ["Lightsail_20161128.GetCertificates"] }
def x-amz-target-completer-71 [] { ["Lightsail_20161128.GetCloudFormationStackRecords"] }
def x-amz-target-completer-72 [] { ["Lightsail_20161128.GetContactMethods"] }
def x-amz-target-completer-73 [] { ["Lightsail_20161128.GetContainerAPIMetadata"] }
def x-amz-target-completer-74 [] { ["Lightsail_20161128.GetContainerImages"] }
def x-amz-target-completer-75 [] { ["Lightsail_20161128.GetContainerLog"] }
def x-amz-target-completer-76 [] { ["Lightsail_20161128.GetContainerServiceDeployments"] }
def metric-name-completer-1 [] { ["CPUUtilization" "MemoryUtilization"] }
def x-amz-target-completer-77 [] { ["Lightsail_20161128.GetContainerServiceMetricData"] }
def x-amz-target-completer-78 [] { ["Lightsail_20161128.GetContainerServicePowers"] }
def x-amz-target-completer-79 [] { ["Lightsail_20161128.GetContainerServices"] }
def x-amz-target-completer-80 [] { ["Lightsail_20161128.GetCostEstimate"] }
def x-amz-target-completer-81 [] { ["Lightsail_20161128.GetDisk"] }
def x-amz-target-completer-82 [] { ["Lightsail_20161128.GetDiskSnapshot"] }
def x-amz-target-completer-83 [] { ["Lightsail_20161128.GetDiskSnapshots"] }
def x-amz-target-completer-84 [] { ["Lightsail_20161128.GetDisks"] }
def x-amz-target-completer-85 [] { ["Lightsail_20161128.GetDistributionBundles"] }
def x-amz-target-completer-86 [] { ["Lightsail_20161128.GetDistributionLatestCacheReset"] }
def metric-name-completer-2 [] { ["BytesDownloaded" "BytesUploaded" "Http4xxErrorRate" "Http5xxErrorRate" "Requests" "TotalErrorRate"] }
def x-amz-target-completer-87 [] { ["Lightsail_20161128.GetDistributionMetricData"] }
def x-amz-target-completer-88 [] { ["Lightsail_20161128.GetDistributions"] }
def x-amz-target-completer-89 [] { ["Lightsail_20161128.GetDomain"] }
def x-amz-target-completer-90 [] { ["Lightsail_20161128.GetDomains"] }
def x-amz-target-completer-91 [] { ["Lightsail_20161128.GetExportSnapshotRecords"] }
def x-amz-target-completer-92 [] { ["Lightsail_20161128.GetInstance"] }
def protocol-completer-1 [] { ["rdp" "ssh"] }
def x-amz-target-completer-93 [] { ["Lightsail_20161128.GetInstanceAccessDetails"] }
def metric-name-completer-3 [] { ["BurstCapacityPercentage" "BurstCapacityTime" "CPUUtilization" "MetadataNoToken" "NetworkIn" "NetworkOut" "StatusCheckFailed" "StatusCheckFailed_Instance" "StatusCheckFailed_System"] }
def x-amz-target-completer-94 [] { ["Lightsail_20161128.GetInstanceMetricData"] }
def x-amz-target-completer-95 [] { ["Lightsail_20161128.GetInstancePortStates"] }
def x-amz-target-completer-96 [] { ["Lightsail_20161128.GetInstanceSnapshot"] }
def x-amz-target-completer-97 [] { ["Lightsail_20161128.GetInstanceSnapshots"] }
def x-amz-target-completer-98 [] { ["Lightsail_20161128.GetInstanceState"] }
def x-amz-target-completer-99 [] { ["Lightsail_20161128.GetInstances"] }
def x-amz-target-completer-100 [] { ["Lightsail_20161128.GetKeyPair"] }
def x-amz-target-completer-101 [] { ["Lightsail_20161128.GetKeyPairs"] }
def x-amz-target-completer-102 [] { ["Lightsail_20161128.GetLoadBalancer"] }
def metric-name-completer-4 [] { ["ClientTLSNegotiationErrorCount" "HTTPCode_Instance_2XX_Count" "HTTPCode_Instance_3XX_Count" "HTTPCode_Instance_4XX_Count" "HTTPCode_Instance_5XX_Count" "HTTPCode_LB_4XX_Count" "HTTPCode_LB_5XX_Count" "HealthyHostCount" "InstanceResponseTime" "RejectedConnectionCount" "RequestCount" "UnhealthyHostCount"] }
def x-amz-target-completer-103 [] { ["Lightsail_20161128.GetLoadBalancerMetricData"] }
def x-amz-target-completer-104 [] { ["Lightsail_20161128.GetLoadBalancerTlsCertificates"] }
def x-amz-target-completer-105 [] { ["Lightsail_20161128.GetLoadBalancerTlsPolicies"] }
def x-amz-target-completer-106 [] { ["Lightsail_20161128.GetLoadBalancers"] }
def x-amz-target-completer-107 [] { ["Lightsail_20161128.GetOperation"] }
def x-amz-target-completer-108 [] { ["Lightsail_20161128.GetOperations"] }
def x-amz-target-completer-109 [] { ["Lightsail_20161128.GetOperationsForResource"] }
def x-amz-target-completer-110 [] { ["Lightsail_20161128.GetRegions"] }
def x-amz-target-completer-111 [] { ["Lightsail_20161128.GetRelationalDatabase"] }
def x-amz-target-completer-112 [] { ["Lightsail_20161128.GetRelationalDatabaseBlueprints"] }
def x-amz-target-completer-113 [] { ["Lightsail_20161128.GetRelationalDatabaseBundles"] }
def x-amz-target-completer-114 [] { ["Lightsail_20161128.GetRelationalDatabaseEvents"] }
def x-amz-target-completer-115 [] { ["Lightsail_20161128.GetRelationalDatabaseLogEvents"] }
def x-amz-target-completer-116 [] { ["Lightsail_20161128.GetRelationalDatabaseLogStreams"] }
def password-version-completer [] { ["CURRENT" "PENDING" "PREVIOUS"] }
def x-amz-target-completer-117 [] { ["Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"] }
def metric-name-completer-5 [] { ["CPUUtilization" "DatabaseConnections" "DiskQueueDepth" "FreeStorageSpace" "NetworkReceiveThroughput" "NetworkTransmitThroughput"] }
def x-amz-target-completer-118 [] { ["Lightsail_20161128.GetRelationalDatabaseMetricData"] }
def x-amz-target-completer-119 [] { ["Lightsail_20161128.GetRelationalDatabaseParameters"] }
def x-amz-target-completer-120 [] { ["Lightsail_20161128.GetRelationalDatabaseSnapshot"] }
def x-amz-target-completer-121 [] { ["Lightsail_20161128.GetRelationalDatabaseSnapshots"] }
def x-amz-target-completer-122 [] { ["Lightsail_20161128.GetRelationalDatabases"] }
def x-amz-target-completer-123 [] { ["Lightsail_20161128.GetStaticIp"] }
def x-amz-target-completer-124 [] { ["Lightsail_20161128.GetStaticIps"] }
def x-amz-target-completer-125 [] { ["Lightsail_20161128.ImportKeyPair"] }
def x-amz-target-completer-126 [] { ["Lightsail_20161128.IsVpcPeered"] }
def x-amz-target-completer-127 [] { ["Lightsail_20161128.OpenInstancePublicPorts"] }
def x-amz-target-completer-128 [] { ["Lightsail_20161128.PeerVpc"] }
def metric-name-completer-6 [] { ["BurstCapacityPercentage" "BurstCapacityTime" "CPUUtilization" "ClientTLSNegotiationErrorCount" "DatabaseConnections" "DiskQueueDepth" "FreeStorageSpace" "HTTPCode_Instance_2XX_Count" "HTTPCode_Instance_3XX_Count" "HTTPCode_Instance_4XX_Count" "HTTPCode_Instance_5XX_Count" "HTTPCode_LB_4XX_Count" "HTTPCode_LB_5XX_Count" "HealthyHostCount" "InstanceResponseTime" "NetworkIn" "NetworkOut" "NetworkReceiveThroughput" "NetworkTransmitThroughput" "RejectedConnectionCount" "RequestCount" "StatusCheckFailed" "StatusCheckFailed_Instance" "StatusCheckFailed_System" "UnhealthyHostCount"] }
def comparison-operator-completer [] { ["GreaterThanOrEqualToThreshold" "GreaterThanThreshold" "LessThanOrEqualToThreshold" "LessThanThreshold"] }
def treat-missing-data-completer [] { ["breaching" "ignore" "missing" "notBreaching"] }
def x-amz-target-completer-129 [] { ["Lightsail_20161128.PutAlarm"] }
def x-amz-target-completer-130 [] { ["Lightsail_20161128.PutInstancePublicPorts"] }
def x-amz-target-completer-131 [] { ["Lightsail_20161128.RebootInstance"] }
def x-amz-target-completer-132 [] { ["Lightsail_20161128.RebootRelationalDatabase"] }
def x-amz-target-completer-133 [] { ["Lightsail_20161128.RegisterContainerImage"] }
def x-amz-target-completer-134 [] { ["Lightsail_20161128.ReleaseStaticIp"] }
def x-amz-target-completer-135 [] { ["Lightsail_20161128.ResetDistributionCache"] }
def protocol-completer-2 [] { ["Email"] }
def x-amz-target-completer-136 [] { ["Lightsail_20161128.SendContactMethodVerification"] }
def resource-type-completer [] { ["Alarm" "Bucket" "Certificate" "CloudFormationStackRecord" "ContactMethod" "ContainerService" "Disk" "DiskSnapshot" "Distribution" "Domain" "ExportSnapshotRecord" "Instance" "InstanceSnapshot" "KeyPair" "LoadBalancer" "LoadBalancerTlsCertificate" "PeeredVpc" "RelationalDatabase" "RelationalDatabaseSnapshot" "StaticIp"] }
def x-amz-target-completer-137 [] { ["Lightsail_20161128.SetIpAddressType"] }
def access-completer [] { ["allow" "deny"] }
def x-amz-target-completer-138 [] { ["Lightsail_20161128.SetResourceAccessForBucket"] }
def x-amz-target-completer-139 [] { ["Lightsail_20161128.StartGUISession"] }
def x-amz-target-completer-140 [] { ["Lightsail_20161128.StartInstance"] }
def x-amz-target-completer-141 [] { ["Lightsail_20161128.StartRelationalDatabase"] }
def x-amz-target-completer-142 [] { ["Lightsail_20161128.StopGUISession"] }
def x-amz-target-completer-143 [] { ["Lightsail_20161128.StopInstance"] }
def x-amz-target-completer-144 [] { ["Lightsail_20161128.StopRelationalDatabase"] }
def x-amz-target-completer-145 [] { ["Lightsail_20161128.TagResource"] }
def state-completer [] { ["ALARM" "INSUFFICIENT_DATA" "OK"] }
def x-amz-target-completer-146 [] { ["Lightsail_20161128.TestAlarm"] }
def x-amz-target-completer-147 [] { ["Lightsail_20161128.UnpeerVpc"] }
def x-amz-target-completer-148 [] { ["Lightsail_20161128.UntagResource"] }
def x-amz-target-completer-149 [] { ["Lightsail_20161128.UpdateBucket"] }
def x-amz-target-completer-150 [] { ["Lightsail_20161128.UpdateBucketBundle"] }
def x-amz-target-completer-151 [] { ["Lightsail_20161128.UpdateContainerService"] }
def x-amz-target-completer-152 [] { ["Lightsail_20161128.UpdateDistribution"] }
def x-amz-target-completer-153 [] { ["Lightsail_20161128.UpdateDistributionBundle"] }
def x-amz-target-completer-154 [] { ["Lightsail_20161128.UpdateDomainEntry"] }
def http-tokens-completer [] { ["optional" "required"] }
def http-endpoint-completer [] { ["disabled" "enabled"] }
def http-protocol-ipv6-completer [] { ["disabled" "enabled"] }
def x-amz-target-completer-155 [] { ["Lightsail_20161128.UpdateInstanceMetadataOptions"] }
def attribute-name-completer [] { ["HealthCheckPath" "HttpsRedirectionEnabled" "SessionStickinessEnabled" "SessionStickiness_LB_CookieDurationSeconds" "TlsPolicyName"] }
def x-amz-target-completer-156 [] { ["Lightsail_20161128.UpdateLoadBalancerAttribute"] }
def x-amz-target-completer-157 [] { ["Lightsail_20161128.UpdateRelationalDatabase"] }
def x-amz-target-completer-158 [] { ["Lightsail_20161128.UpdateRelationalDatabaseParameters"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    allocate-static-ip: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    attach-certificate-to-distribution: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    attach-disk: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    attach-instances-to-load-balancer: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    attach-load-balancer-tls-certificate: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    attach-static-ip: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    close-instance-public-ports: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    copy-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-bucket: "record<bucket: record<resourceType: string, accessRules: record<getObject: string, allowPublicOverrides: bool>, arn: string, bundleId: string, createdAt: string, url: string, location: record<availabilityZone: string, regionName: string>, name: string, supportCode: string, tags: list<record>, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list<string>, resourcesReceivingAccess: list<record>, state: record<code: string, message: string>, accessLogConfig: record<enabled: bool, destination: string, prefix: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-bucket-access-key: "record<accessKey: record<accessKeyId: string, secretAccessKey: string, status: string, createdAt: string, lastUsed: record<lastUsedDate: string, region: string, serviceName: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-certificate: "record<certificate: record<certificateArn: string, certificateName: string, domainName: string, certificateDetail: record<arn: string, name: string, domainName: string, status: string, serialNumber: string, subjectAlternativeNames: list, domainValidationRecords: list, requestFailureReason: string, inUseResourceCount: int, keyAlgorithm: string, createdAt: string, issuedAt: string, issuerCA: string, notBefore: string, notAfter: string, eligibleToRenew: string, renewalSummary: record, revokedAt: string, revocationReason: string, tags: list, supportCode: string>, tags: list<record>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-cloud-formation-stack: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-contact-method: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-container-service: "record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>"
    create-container-service-deployment: "record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>"
    create-container-service-registry-login: "record<registryLogin: record<username: string, password: string, expiresAt: string, registry: string>>"
    create-disk: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-disk-from-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-disk-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-distribution: "record<distribution: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, alternativeDomainNames: list<string>, status: string, isEnabled: bool, domainName: string, bundleId: string, certificateName: string, origin: record<name: string, resourceType: string, regionName: string, protocolPolicy: string>, originPublicDNS: string, defaultCacheBehavior: record<behavior: string>, cacheBehaviorSettings: record<defaultTTL: int, minimumTTL: int, maximumTTL: int, allowedHTTPMethods: string, cachedHTTPMethods: string, forwardedCookies: record, forwardedHeaders: record, forwardedQueryStrings: record>, cacheBehaviors: list<record>, ableToUpdateBundle: bool, ipAddressType: string, tags: list<record>>, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-domain: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-domain-entry: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-gui-session-access-details: "record<resourceName: string, status: string, percentageComplete: int, failureReason: string, sessions: table<name: string, url: string, isPrimary: bool>>"
    create-instance-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-instances: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-instances-from-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-key-pair: "record<keyPair: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, fingerprint: string>, publicKeyBase64: string, privateKeyBase64: string, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-load-balancer: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-load-balancer-tls-certificate: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-relational-database-from-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    create-relational-database-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-alarm: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-auto-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-bucket: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-bucket-access-key: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-certificate: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-contact-method: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-container-image: "record"
    delete-container-service: "record"
    delete-disk: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-disk-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-distribution: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-domain: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-domain-entry: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-instance: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-instance-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-key-pair: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-known-host-keys: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-load-balancer: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-load-balancer-tls-certificate: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    delete-relational-database-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    detach-certificate-from-distribution: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    detach-disk: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    detach-instances-from-load-balancer: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    detach-static-ip: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    disable-add-on: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    download-default-key-pair: "record<publicKeyBase64: string, privateKeyBase64: string, createdAt: string>"
    enable-add-on: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    export-snapshot: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    get-active-names: "record<activeNames: list<string>, nextPageToken: string>"
    get-alarms: "record<alarms: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, supportCode: string, monitoredResourceInfo: record, comparisonOperator: string, evaluationPeriods: int, period: int, threshold: float, datapointsToAlarm: int, treatMissingData: string, statistic: string, metricName: string, state: string, unit: string, contactProtocols: list, notificationTriggers: list, notificationEnabled: bool>, nextPageToken: string>"
    get-auto-snapshots: "record<resourceName: string, resourceType: string, autoSnapshots: table<date: string, createdAt: string, status: string, fromAttachedDisks: list>>"
    get-blueprints: "record<blueprints: table<blueprintId: string, name: string, group: string, type: string, description: string, isActive: bool, minPower: int, version: string, versionCode: string, productUrl: string, licenseUrl: string, platform: string, appCategory: string>, nextPageToken: string>"
    get-bucket-access-keys: "record<accessKeys: table<accessKeyId: string, secretAccessKey: string, status: string, createdAt: string, lastUsed: record>>"
    get-bucket-bundles: "record<bundles: table<bundleId: string, name: string, price: float, storagePerMonthInGb: int, transferPerMonthInGb: int, isActive: bool>>"
    get-bucket-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-buckets: "record<buckets: table<resourceType: string, accessRules: record, arn: string, bundleId: string, createdAt: string, url: string, location: record, name: string, supportCode: string, tags: list, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list, resourcesReceivingAccess: list, state: record, accessLogConfig: record>, nextPageToken: string, accountLevelBpaSync: record<status: string, lastSyncedAt: string, message: string, bpaImpactsLightsail: bool>>"
    get-bundles: "record<bundles: table<price: float, cpuCount: int, diskSizeInGb: int, bundleId: string, instanceType: string, isActive: bool, name: string, power: int, ramSizeInGb: float, transferPerMonthInGb: int, supportedPlatforms: list, supportedAppCategories: list>, nextPageToken: string>"
    get-certificates: "record<certificates: table<certificateArn: string, certificateName: string, domainName: string, certificateDetail: record, tags: list>>"
    get-cloud-formation-stack-records: "record<cloudFormationStackRecords: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, state: string, sourceInfo: list, destinationInfo: record>, nextPageToken: string>"
    get-contact-methods: "record<contactMethods: table<contactEndpoint: string, status: string, protocol: string, name: string, arn: string, createdAt: string, location: record, resourceType: string, supportCode: string>>"
    get-container-api-metadata: "record<metadata: list<record>>"
    get-container-images: "record<containerImages: table<image: string, digest: string, createdAt: string>>"
    get-container-log: "record<logEvents: table<createdAt: string, message: string>, nextPageToken: string>"
    get-container-service-deployments: "record<deployments: table<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>>"
    get-container-service-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-container-service-powers: "record<powers: table<powerId: string, price: float, cpuCount: float, ramSizeInGb: float, name: string, isActive: bool>>"
    get-container-services: "record<containerServices: table<containerServiceName: string, arn: string, createdAt: string, location: record, resourceType: string, tags: list, power: string, powerId: string, state: string, stateDetail: record, scale: int, currentDeployment: record, nextDeployment: record, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record>>"
    get-cost-estimate: "record<resourcesBudgetEstimate: table<resourceName: string, resourceType: string, costEstimates: list, startTime: string, endTime: string>>"
    get-disk: "record<disk: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, addOns: list<record>, sizeInGb: int, isSystemDisk: bool, iops: int, path: string, state: string, attachedTo: string, isAttached: bool, attachmentState: string, gbInUse: int, autoMountStatus: string>>"
    get-disk-snapshot: "record<diskSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, sizeInGb: int, state: string, progress: string, fromDiskName: string, fromDiskArn: string, fromInstanceName: string, fromInstanceArn: string, isFromAutoSnapshot: bool>>"
    get-disk-snapshots: "record<diskSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, sizeInGb: int, state: string, progress: string, fromDiskName: string, fromDiskArn: string, fromInstanceName: string, fromInstanceArn: string, isFromAutoSnapshot: bool>, nextPageToken: string>"
    get-disks: "record<disks: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, addOns: list, sizeInGb: int, isSystemDisk: bool, iops: int, path: string, state: string, attachedTo: string, isAttached: bool, attachmentState: string, gbInUse: int, autoMountStatus: string>, nextPageToken: string>"
    get-distribution-bundles: "record<bundles: table<bundleId: string, name: string, price: float, transferPerMonthInGb: int, isActive: bool>>"
    get-distribution-latest-cache-reset: "record<status: string, createTime: string>"
    get-distribution-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-distributions: "record<distributions: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, alternativeDomainNames: list, status: string, isEnabled: bool, domainName: string, bundleId: string, certificateName: string, origin: record, originPublicDNS: string, defaultCacheBehavior: record, cacheBehaviorSettings: record, cacheBehaviors: list, ableToUpdateBundle: bool, ipAddressType: string, tags: list>, nextPageToken: string>"
    get-domain: "record<domain: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, domainEntries: list<record>, registeredDomainDelegationInfo: record<nameServersUpdateState: record, r53HostedZoneDeletionState: record>>>"
    get-domains: "record<domains: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, domainEntries: list, registeredDomainDelegationInfo: record>, nextPageToken: string>"
    get-export-snapshot-records: "record<exportSnapshotRecords: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, state: string, sourceInfo: record, destinationInfo: record>, nextPageToken: string>"
    get-instance: "record<instance: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, blueprintId: string, blueprintName: string, bundleId: string, addOns: list<record>, isStaticIp: bool, privateIpAddress: string, publicIpAddress: string, ipv6Addresses: list<string>, ipAddressType: string, hardware: record<cpuCount: int, disks: list, ramSizeInGb: float>, networking: record<monthlyTransfer: record, ports: list>, state: record<code: int, name: string>, username: string, sshKeyName: string, metadataOptions: record<state: string, httpTokens: string, httpEndpoint: string, httpPutResponseHopLimit: int, httpProtocolIpv6: string>>>"
    get-instance-access-details: "record<accessDetails: record<certKey: string, expiresAt: string, ipAddress: string, password: string, passwordData: record<ciphertext: string, keyPairName: string>, privateKey: string, protocol: string, instanceName: string, username: string, hostKeys: list<record>>>"
    get-instance-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-instance-port-states: "record<portStates: table<fromPort: int, toPort: int, protocol: string, state: string, cidrs: list, ipv6Cidrs: list, cidrListAliases: list>>"
    get-instance-snapshot: "record<instanceSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, state: string, progress: string, fromAttachedDisks: list<record>, fromInstanceName: string, fromInstanceArn: string, fromBlueprintId: string, fromBundleId: string, isFromAutoSnapshot: bool, sizeInGb: int>>"
    get-instance-snapshots: "record<instanceSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, state: string, progress: string, fromAttachedDisks: list, fromInstanceName: string, fromInstanceArn: string, fromBlueprintId: string, fromBundleId: string, isFromAutoSnapshot: bool, sizeInGb: int>, nextPageToken: string>"
    get-instance-state: "record<state: record<code: int, name: string>>"
    get-instances: "record<instances: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, blueprintId: string, blueprintName: string, bundleId: string, addOns: list, isStaticIp: bool, privateIpAddress: string, publicIpAddress: string, ipv6Addresses: list, ipAddressType: string, hardware: record, networking: record, state: record, username: string, sshKeyName: string, metadataOptions: record>, nextPageToken: string>"
    get-key-pair: "record<keyPair: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, fingerprint: string>>"
    get-key-pairs: "record<keyPairs: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, fingerprint: string>, nextPageToken: string>"
    get-load-balancer: "record<loadBalancer: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, dnsName: string, state: string, protocol: string, publicPorts: list<int>, healthCheckPath: string, instancePort: int, instanceHealthSummary: list<record>, tlsCertificateSummaries: list<record>, configurationOptions: record, ipAddressType: string, httpsRedirectionEnabled: bool, tlsPolicyName: string>>"
    get-load-balancer-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-load-balancer-tls-certificates: "record<tlsCertificates: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, loadBalancerName: string, isAttached: bool, status: string, domainName: string, domainValidationRecords: list, failureReason: string, issuedAt: string, issuer: string, keyAlgorithm: string, notAfter: string, notBefore: string, renewalSummary: record, revocationReason: string, revokedAt: string, serial: string, signatureAlgorithm: string, subject: string, subjectAlternativeNames: list>>"
    get-load-balancer-tls-policies: "record<tlsPolicies: table<name: string, isDefault: bool, description: string, protocols: list, ciphers: list>, nextPageToken: string>"
    get-load-balancers: "record<loadBalancers: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, dnsName: string, state: string, protocol: string, publicPorts: list, healthCheckPath: string, instancePort: int, instanceHealthSummary: list, tlsCertificateSummaries: list, configurationOptions: record, ipAddressType: string, httpsRedirectionEnabled: bool, tlsPolicyName: string>, nextPageToken: string>"
    get-operation: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    get-operations: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>, nextPageToken: string>"
    get-operations-for-resource: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>, nextPageCount: string, nextPageToken: string>"
    get-regions: "record<regions: table<continentCode: string, description: string, displayName: string, name: string, availabilityZones: list, relationalDatabaseAvailabilityZones: list>>"
    get-relational-database: "record<relationalDatabase: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, relationalDatabaseBlueprintId: string, relationalDatabaseBundleId: string, masterDatabaseName: string, hardware: record<cpuCount: int, diskSizeInGb: int, ramSizeInGb: float>, state: string, secondaryAvailabilityZone: string, backupRetentionEnabled: bool, pendingModifiedValues: record<masterUserPassword: string, engineVersion: string, backupRetentionEnabled: bool>, engine: string, engineVersion: string, latestRestorableTime: string, masterUsername: string, parameterApplyStatus: string, preferredBackupWindow: string, preferredMaintenanceWindow: string, publiclyAccessible: bool, masterEndpoint: record<port: int, address: string>, pendingMaintenanceActions: list<record>, caCertificateIdentifier: string>>"
    get-relational-database-blueprints: "record<blueprints: table<blueprintId: string, engine: string, engineVersion: string, engineDescription: string, engineVersionDescription: string, isEngineDefault: bool>, nextPageToken: string>"
    get-relational-database-bundles: "record<bundles: table<bundleId: string, name: string, price: float, ramSizeInGb: float, diskSizeInGb: int, transferPerMonthInGb: int, cpuCount: int, isEncrypted: bool, isActive: bool>, nextPageToken: string>"
    get-relational-database-events: "record<relationalDatabaseEvents: table<resource: string, createdAt: string, message: string, eventCategories: list>, nextPageToken: string>"
    get-relational-database-log-events: "record<resourceLogEvents: table<createdAt: string, message: string>, nextBackwardToken: string, nextForwardToken: string>"
    get-relational-database-log-streams: "record<logStreams: list<string>>"
    get-relational-database-master-user-password: "record<masterUserPassword: string, createdAt: string>"
    get-relational-database-metric-data: "record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>"
    get-relational-database-parameters: "record<parameters: table<allowedValues: string, applyMethod: string, applyType: string, dataType: string, description: string, isModifiable: bool, parameterName: string, parameterValue: string>, nextPageToken: string>"
    get-relational-database-snapshot: "record<relationalDatabaseSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, engine: string, engineVersion: string, sizeInGb: int, state: string, fromRelationalDatabaseName: string, fromRelationalDatabaseArn: string, fromRelationalDatabaseBundleId: string, fromRelationalDatabaseBlueprintId: string>>"
    get-relational-database-snapshots: "record<relationalDatabaseSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, engine: string, engineVersion: string, sizeInGb: int, state: string, fromRelationalDatabaseName: string, fromRelationalDatabaseArn: string, fromRelationalDatabaseBundleId: string, fromRelationalDatabaseBlueprintId: string>, nextPageToken: string>"
    get-relational-databases: "record<relationalDatabases: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, relationalDatabaseBlueprintId: string, relationalDatabaseBundleId: string, masterDatabaseName: string, hardware: record, state: string, secondaryAvailabilityZone: string, backupRetentionEnabled: bool, pendingModifiedValues: record, engine: string, engineVersion: string, latestRestorableTime: string, masterUsername: string, parameterApplyStatus: string, preferredBackupWindow: string, preferredMaintenanceWindow: string, publiclyAccessible: bool, masterEndpoint: record, pendingMaintenanceActions: list, caCertificateIdentifier: string>, nextPageToken: string>"
    get-static-ip: "record<staticIp: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, ipAddress: string, attachedTo: string, isAttached: bool>>"
    get-static-ips: "record<staticIps: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, ipAddress: string, attachedTo: string, isAttached: bool>, nextPageToken: string>"
    import-key-pair: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    is-vpc-peered: "record<isPeered: bool>"
    open-instance-public-ports: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    peer-vpc: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    put-alarm: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    put-instance-public-ports: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    reboot-instance: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    reboot-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    register-container-image: "record<containerImage: record<image: string, digest: string, createdAt: string>>"
    release-static-ip: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    reset-distribution-cache: "record<status: string, createTime: string, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    send-contact-method-verification: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    set-ip-address-type: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    set-resource-access-for-bucket: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    start-gui-session: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    start-instance: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    start-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    stop-gui-session: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    stop-instance: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    stop-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    tag-resource: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    test-alarm: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    unpeer-vpc: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    untag-resource: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-bucket: "record<bucket: record<resourceType: string, accessRules: record<getObject: string, allowPublicOverrides: bool>, arn: string, bundleId: string, createdAt: string, url: string, location: record<availabilityZone: string, regionName: string>, name: string, supportCode: string, tags: list<record>, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list<string>, resourcesReceivingAccess: list<record>, state: record<code: string, message: string>, accessLogConfig: record<enabled: bool, destination: string, prefix: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-bucket-bundle: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-container-service: "record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>"
    update-distribution: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-distribution-bundle: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-domain-entry: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-instance-metadata-options: "record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-load-balancer-attribute: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-relational-database: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
    update-relational-database-parameters: "record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["allocate-static-ip" "attach-certificate-to-distribution" "attach-disk" "attach-instances-to-load-balancer" "attach-load-balancer-tls-certificate" "attach-static-ip" "close-instance-public-ports" "copy-snapshot" "create-bucket" "create-bucket-access-key" "create-certificate" "create-cloud-formation-stack" "create-contact-method" "create-container-service" "create-container-service-deployment" "create-container-service-registry-login" "create-disk" "create-disk-from-snapshot" "create-disk-snapshot" "create-distribution" "create-domain" "create-domain-entry" "create-gui-session-access-details" "create-instance-snapshot" "create-instances" "create-instances-from-snapshot" "create-key-pair" "create-load-balancer" "create-load-balancer-tls-certificate" "create-relational-database" "create-relational-database-from-snapshot" "create-relational-database-snapshot" "delete-alarm" "delete-auto-snapshot" "delete-bucket" "delete-bucket-access-key" "delete-certificate" "delete-contact-method" "delete-container-image" "delete-container-service" "delete-disk" "delete-disk-snapshot" "delete-distribution" "delete-domain" "delete-domain-entry" "delete-instance" "delete-instance-snapshot" "delete-key-pair" "delete-known-host-keys" "delete-load-balancer" "delete-load-balancer-tls-certificate" "delete-relational-database" "delete-relational-database-snapshot" "detach-certificate-from-distribution" "detach-disk" "detach-instances-from-load-balancer" "detach-static-ip" "disable-add-on" "download-default-key-pair" "enable-add-on" "export-snapshot" "get-active-names" "get-alarms" "get-auto-snapshots" "get-blueprints" "get-bucket-access-keys" "get-bucket-bundles" "get-bucket-metric-data" "get-buckets" "get-bundles" "get-certificates" "get-cloud-formation-stack-records" "get-contact-methods" "get-container-api-metadata" "get-container-images" "get-container-log" "get-container-service-deployments" "get-container-service-metric-data" "get-container-service-powers" "get-container-services" "get-cost-estimate" "get-disk" "get-disk-snapshot" "get-disk-snapshots" "get-disks" "get-distribution-bundles" "get-distribution-latest-cache-reset" "get-distribution-metric-data" "get-distributions" "get-domain" "get-domains" "get-export-snapshot-records" "get-instance" "get-instance-access-details" "get-instance-metric-data" "get-instance-port-states" "get-instance-snapshot" "get-instance-snapshots" "get-instance-state" "get-instances" "get-key-pair" "get-key-pairs" "get-load-balancer" "get-load-balancer-metric-data" "get-load-balancer-tls-certificates" "get-load-balancer-tls-policies" "get-load-balancers" "get-operation" "get-operations" "get-operations-for-resource" "get-regions" "get-relational-database" "get-relational-database-blueprints" "get-relational-database-bundles" "get-relational-database-events" "get-relational-database-log-events" "get-relational-database-log-streams" "get-relational-database-master-user-password" "get-relational-database-metric-data" "get-relational-database-parameters" "get-relational-database-snapshot" "get-relational-database-snapshots" "get-relational-databases" "get-static-ip" "get-static-ips" "import-key-pair" "is-vpc-peered" "open-instance-public-ports" "peer-vpc" "put-alarm" "put-instance-public-ports" "reboot-instance" "reboot-relational-database" "register-container-image" "release-static-ip" "reset-distribution-cache" "send-contact-method-verification" "set-ip-address-type" "set-resource-access-for-bucket" "start-gui-session" "start-instance" "start-relational-database" "stop-gui-session" "stop-instance" "stop-relational-database" "tag-resource" "test-alarm" "unpeer-vpc" "untag-resource" "update-bucket" "update-bucket-bundle" "update-container-service" "update-distribution" "update-distribution-bundle" "update-domain-entry" "update-instance-metadata-options" "update-load-balancer-attribute" "update-relational-database" "update-relational-database-parameters" "commands"] | sort) } | get name | first)
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

# Allocates a static IP address.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AllocateStaticIp
export def "allocate-static-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  static_ip_name: string # The name of the static IP address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AllocateStaticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: staticIpName, var: static_ip_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, static_ip_name: $static_ip_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches an SSL/TLS certificate to your Amazon Lightsail content delivery network (CDN) distribution. After the certificate is attached, your distribution accepts HTTPS traffic for all of the domains that are associated with the certificate. Use the CreateCertificate action to create a certificate that you can attach to your distribution. Only certificates created in the us-east-1 Amazon Web Services Region can be attached to Lightsail distributions. Lightsail distributions are global resources that can reference an origin in any Amazon Web Services Region, and distribute its content globally. However, all distributions are located in the us-east-1 Region.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AttachCertificateToDistribution
export def "attach-certificate-to-distribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  distribution_name: string # The name of the distribution that the certificate will be attached to. Use the GetDistributions action to get a list of distribution names that you can specify.
  certificate_name: string # The name of the certificate to attach to a distribution. Only certificates with a status of ISSUED can be attached to a distribution. Use the GetCertificates action to get a list of certificate names that you can specify. This is the name of the certificate resource type and is used only to reference the certificate in other API actions. It can be different than the domain name of the certificate. For example, your certificate name might be WordPress-Blog-Certificate and the domain name of the certificate might be example.com.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AttachCertificateToDistribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: certificateName, var: certificate_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, certificate_name: $certificate_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a block storage disk to a running or stopped Lightsail instance and exposes it to the instance with the specified disk name. The attach disk operation supports tag-based access control via resource tags applied to the resource identified by disk name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AttachDisk
export def "attach-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_name: string # The unique Lightsail disk name (e.g., my-disk).
  instance_name: string # The name of the Lightsail instance where you want to utilize the storage disk.
  disk_path: string # The disk path to expose to the instance (e.g., /dev/xvdf).
  --auto-mounting: oneof<nothing, bool> # A Boolean value used to determine the automatic mounting of a storage volume to a virtual computer. The default value is False. This value only applies to Lightsail for Research resources.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AttachDisk"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}, {name: instanceName, var: instance_name}, {name: diskPath, var: disk_path}, {name: autoMounting, var: auto_mounting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name, instance_name: $instance_name, disk_path: $disk_path, auto_mounting: $auto_mounting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches one or more Lightsail instances to a load balancer. After some time, the instances are attached to the load balancer and the health check status is available. The attach instances to load balancer operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AttachInstancesToLoadBalancer
export def "attach-instances-to-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The name of the load balancer.
  instance_names: list<string> # An array of strings representing the instance name(s) you want to attach to your load balancer. An instance must be running before you can attach it to your load balancer. There are no additional limits on the number of instances you can attach to your load balancer, aside from the limit of Lightsail instances you can create in your account (20).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AttachInstancesToLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: instanceNames, var: instance_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, instance_names: $instance_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a Transport Layer Security (TLS) certificate to your load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL). Once you create and validate your certificate, you can attach it to your load balancer. You can also use this API to rotate the certificates on your account. Use the AttachLoadBalancerTlsCertificate action with the non-attached certificate, and it will replace the existing one and become the attached certificate. The AttachLoadBalancerTlsCertificate operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AttachLoadBalancerTlsCertificate
export def "attach-load-balancer-tls-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The name of the load balancer to which you want to associate the SSL/TLS certificate.
  certificate_name: string # The name of your SSL/TLS certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AttachLoadBalancerTlsCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: certificateName, var: certificate_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, certificate_name: $certificate_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a static IP address to a specific Amazon Lightsail instance.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: AttachStaticIp
export def "attach-static-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  static_ip_name: string # The name of the static IP.
  instance_name: string # The instance name to which you want to attach the static IP address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.AttachStaticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: staticIpName, var: static_ip_name}, {name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, static_ip_name: $static_ip_name, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Closes ports for a specific Amazon Lightsail instance. The CloseInstancePublicPorts action supports tag-based access control via resource tags applied to the resource identified by instanceName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CloseInstancePublicPorts
export def "close-instance-public-ports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  port_info: record # Describes ports to open on an instance, the IP addresses allowed to connect to the instance through the ports, and the protocol. — shape: {fromPort?: int, toPort?: int, protocol?: "tcp"|"all"|"udp"|"icmp", cidrs?: list<string>, ipv6Cidrs?: list<string>, cidrListAliases?: list<string>}
  instance_name: string # The name of the instance for which to close ports.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CloseInstancePublicPorts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: portInfo, var: port_info}, {name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, port_info: $port_info, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies a manual snapshot of an instance or disk as another manual snapshot, or copies an automatic snapshot of an instance or disk as a manual snapshot. This operation can also be used to copy a manual or automatic snapshot of an instance or a disk from one Amazon Web Services Region to another in Amazon Lightsail. When copying a manual snapshot, be sure to define the source region, source snapshot name, and target snapshot name parameters. When copying an automatic snapshot, be sure to define the source region, source resource name, target snapshot name, and either the restore date or the use latest restorable auto snapshot parameters.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CopySnapshot
export def "copy-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --source-snapshot-name: string # The name of the source manual snapshot to copy. Constraint: Define this parameter only when copying a manual snapshot as another manual snapshot.
  --source-resource-name: string # The name of the source instance or disk from which the source automatic snapshot was created. Constraint: Define this parameter only when copying an automatic snapshot as a manual snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-keeping-automatic-snapshots).
  --restore-date: string # The date of the source automatic snapshot to copy. Use the get auto snapshots operation to identify the dates of the available automatic snapshots. Constraints: Must be specified in YYYY-MM-DD format. This parameter cannot be defined together with the use latest restorable auto snapshot parameter. The restore date and use latest restorable auto snapshot parameters are mutually exclusive. Define this parameter only when copying an automatic snapshot as a manual snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-keeping-automatic-snapshots).
  --use-latest-restorable-auto-snapshot: oneof<nothing, bool> # A Boolean value to indicate whether to use the latest available automatic snapshot of the specified source instance or disk. Constraints: This parameter cannot be defined together with the restore date parameter. The use latest restorable auto snapshot and restore date parameters are mutually exclusive. Define this parameter only when copying an automatic snapshot as a manual snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-keeping-automatic-snapshots).
  target_snapshot_name: string # The name of the new manual snapshot to be created as a copy.
  source_region: string@source-region-completer # The Amazon Web Services Region where the source manual or automatic snapshot is located.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CopySnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceSnapshotName, var: source_snapshot_name}, {name: sourceResourceName, var: source_resource_name}, {name: restoreDate, var: restore_date}, {name: useLatestRestorableAutoSnapshot, var: use_latest_restorable_auto_snapshot}, {name: targetSnapshotName, var: target_snapshot_name}, {name: sourceRegion, var: source_region}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_snapshot_name: $source_snapshot_name, source_resource_name: $source_resource_name, restore_date: $restore_date, use_latest_restorable_auto_snapshot: $use_latest_restorable_auto_snapshot, target_snapshot_name: $target_snapshot_name, source_region: $source_region
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Lightsail bucket. A bucket is a cloud storage resource available in the Lightsail object storage service. Use buckets to store objects such as data and its descriptive metadata. For more information about buckets, see Buckets in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/buckets-in-amazon-lightsail) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<bucket: record<resourceType: string, accessRules: record<getObject: string, allowPublicOverrides: bool>, arn: string, bundleId: string, createdAt: string, url: string, location: record<availabilityZone: string, regionName: string>, name: string, supportCode: string, tags: list<record>, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list<string>, resourcesReceivingAccess: list<record>, state: record<code: string, message: string>, accessLogConfig: record<enabled: bool, destination: string, prefix: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateBucket
export def "create-bucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  bucket_name: string # The name for the bucket. For more information about bucket names, see Bucket naming rules in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/bucket-naming-rules-in-amazon-lightsail) in the Amazon Lightsail Developer Guide.
  bundle_id: string # The ID of the bundle to use for the bucket. A bucket bundle specifies the monthly cost, storage space, and data transfer quota for a bucket. Use the GetBucketBundles (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBucketBundles.html) action to get a list of bundle IDs that you can specify. Use the UpdateBucketBundle (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_UpdateBucketBundle.html) action to change the bundle after the bucket is created.
  --tags: list # The tag keys and optional values to add to the bucket during creation. Use the TagResource (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_TagResource.html) action to tag the bucket after it's created. — item shape: {key?: string, value?: string}
  --enable-object-versioning: oneof<nothing, bool> # A Boolean value that indicates whether to enable versioning of objects in the bucket. For more information about versioning, see Enabling and suspending object versioning in a bucket in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-managing-bucket-object-versioning) in the Amazon Lightsail Developer Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateBucket"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: bundleId, var: bundle_id}, {name: tags, var: tags}, {name: enableObjectVersioning, var: enable_object_versioning}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, bundle_id: $bundle_id, tags: $tags, enable_object_versioning: $enable_object_versioning
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new access key for the specified Amazon Lightsail bucket. Access keys consist of an access key ID and corresponding secret access key. Access keys grant full programmatic access to the specified bucket and its objects. You can have a maximum of two access keys per bucket. Use the GetBucketAccessKeys (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBucketAccessKeys.html) action to get a list of current access keys for a specific bucket. For more information about access keys, see Creating access keys for a bucket in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-creating-bucket-access-keys) in the Amazon Lightsail Developer Guide. The secretAccessKey value is returned only in response to the CreateBucketAccessKey action. You can get a secret access key only when you first create an access key; you cannot get the secret access key later. If you lose the secret access key, you must create a new access key.
#
# POST /
# Returns: record<accessKey: record<accessKeyId: string, secretAccessKey: string, status: string, createdAt: string, lastUsed: record<lastUsedDate: string, region: string, serviceName: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateBucketAccessKey
export def "create-bucket-access-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  bucket_name: string # The name of the bucket that the new access key will belong to, and grant access to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateBucketAccessKey"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an SSL/TLS certificate for an Amazon Lightsail content delivery network (CDN) distribution and a container service. After the certificate is valid, use the AttachCertificateToDistribution action to use the certificate and its domains with your distribution. Or use the UpdateContainerService action to use the certificate and its domains with your container service. Only certificates created in the us-east-1 Amazon Web Services Region can be attached to Lightsail distributions. Lightsail distributions are global resources that can reference an origin in any Amazon Web Services Region, and distribute its content globally. However, all distributions are located in the us-east-1 Region.
#
# POST /
# Returns: record<certificate: record<certificateArn: string, certificateName: string, domainName: string, certificateDetail: record<arn: string, name: string, domainName: string, status: string, serialNumber: string, subjectAlternativeNames: list, domainValidationRecords: list, requestFailureReason: string, inUseResourceCount: int, keyAlgorithm: string, createdAt: string, issuedAt: string, issuerCA: string, notBefore: string, notAfter: string, eligibleToRenew: string, renewalSummary: record, revokedAt: string, revocationReason: string, tags: list, supportCode: string>, tags: list<record>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateCertificate
export def "create-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  certificate_name: string # The name for the certificate.
  domain_name: string # The domain name (e.g., example.com) for the certificate.
  --subject-alternative-names: list<string> # An array of strings that specify the alternate domains (e.g., example2.com) and subdomains (e.g., blog.example.com) for the certificate. You can specify a maximum of nine alternate domains (in addition to the primary domain name). Wildcard domain entries (e.g., *.example.com) are not supported.
  --tags: list # The tag keys and optional values to add to the certificate during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateName, var: certificate_name}, {name: domainName, var: domain_name}, {name: subjectAlternativeNames, var: subject_alternative_names}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, certificate_name: $certificate_name, domain_name: $domain_name, subject_alternative_names: $subject_alternative_names, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an AWS CloudFormation stack, which creates a new Amazon EC2 instance from an exported Amazon Lightsail snapshot. This operation results in a CloudFormation stack record that can be used to track the AWS CloudFormation stack created. Use the get cloud formation stack records operation to get a list of the CloudFormation stacks created. Wait until after your new Amazon EC2 instance is created before running the create cloud formation stack operation again with the same export snapshot record.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateCloudFormationStack
export def "create-cloud-formation-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instances: list # An array of parameters that will be used to create the new Amazon EC2 instance. You can only pass one instance entry at a time in this array. You will get an invalid parameter error if you pass more than one instance entry in this array. — item shape: {sourceName: string, instanceType: string, portInfoSource: "DEFAULT"|"INSTANCE"|"NONE"|"CLOSED", userData?: string, availabilityZone: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateCloudFormationStack"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instances, var: instances}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instances: $instances
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an email or SMS text message contact method. A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each Amazon Web Services Region. However, SMS text messaging is not supported in some Amazon Web Services Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see Notifications in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateContactMethod
export def "create-contact-method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  protocol: string@protocol-completer # The protocol of the contact method, such as Email or SMS (text messaging). The SMS protocol is supported only in the following Amazon Web Services Regions. US East (N. Virginia) (us-east-1) US West (Oregon) (us-west-2) Europe (Ireland) (eu-west-1) Asia Pacific (Tokyo) (ap-northeast-1) Asia Pacific (Singapore) (ap-southeast-1) Asia Pacific (Sydney) (ap-southeast-2) For a list of countries/regions where SMS text messages can be sent, and the latest Amazon Web Services Regions where SMS text messaging is supported, see Supported Regions and Countries (https://docs.aws.amazon.com/sns/latest/dg/sns-supported-regions-countries.html) in the Amazon SNS Developer Guide. For more information about notifications in Amazon Lightsail, see Notifications in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications).
  contact_endpoint: string # The destination of the contact method, such as an email address or a mobile phone number. Use the E.164 format when specifying a mobile phone number. E.164 is a standard for the phone number structure used for international telecommunication. Phone numbers that follow this format can have a maximum of 15 digits, and they are prefixed with the plus character (+) and the country code. For example, a U.S. phone number in E.164 format would be specified as +1XXX5550100. For more information, see E.164 (https://en.wikipedia.org/wiki/E.164) on Wikipedia.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateContactMethod"}]
    body: {content_type: "application/json", kind: json, fields: [{name: protocol, var: protocol}, {name: contactEndpoint, var: contact_endpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, protocol: $protocol, contact_endpoint: $contact_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Lightsail container service. A Lightsail container service is a compute resource to which you can deploy containers. For more information, see Container services in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-container-services) in the Lightsail Dev Guide.
#
# POST /
# Returns: record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>
# operationId: CreateContainerService
export def "create-container-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_name: string # The name for the container service. The name that you specify for your container service will make up part of its default domain. The default domain of a container service is typically https://<ServiceName>.<RandomGUID>.<AWSRegion>.cs.amazonlightsail.com. If the name of your container service is container-service-1, and it's located in the US East (Ohio) Amazon Web Services Region (us-east-2), then the domain for your container service will be like the following example: https://container-service-1.ur4EXAMPLE2uq.us-east-2.cs.amazonlightsail.com The following are the requirements for container service names: Must be unique within each Amazon Web Services Region in your Lightsail account. Must contain 1 to 63 characters. Must contain only alphanumeric characters and hyphens. A hyphen (-) can separate words but cannot be at the start or end of the name.
  power: string@power-completer # The power specification for the container service. The power specifies the amount of memory, vCPUs, and base monthly cost of each node of the container service. The power and scale of a container service makes up its configured capacity. To determine the monthly price of your container service, multiply the base price of the power with the scale (the number of nodes) of the service. Use the GetContainerServicePowers action to get a list of power options that you can specify using this parameter, and their base monthly cost.
  scale: int # The scale specification for the container service. The scale specifies the allocated compute nodes of the container service. The power and scale of a container service makes up its configured capacity. To determine the monthly price of your container service, multiply the base price of the power with the scale (the number of nodes) of the service.
  --tags: list # The tag keys and optional values to add to the container service during create. Use the TagResource action to tag a resource after it's created. For more information about tags in Lightsail, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-tags). — item shape: {key?: string, value?: string}
  --public-domain-names: record # The public domain names to use with the container service, such as example.com and www.example.com. You can specify up to four public domain names for a container service. The domain names that you specify are used when you create a deployment with a container configured as the public endpoint of your container service. If you don't specify public domain names, then you can use the default domain of the container service. You must create and validate an SSL/TLS certificate before you can use public domain names with your container service. Use the CreateCertificate action to create a certificate for the public domain names you want to use with your container service. You can specify public domain names using a string to array map as shown in the example later on this page.
  --deployment: record # Describes a container deployment configuration of an Amazon Lightsail container service. A deployment specifies the settings, such as the ports and launch command, of containers that are deployed to your container service. — shape: {containers?: record, publicEndpoint?: record}
  --private-registry-access: record # Describes a request to configure an Amazon Lightsail container service to access private container image repositories, such as Amazon Elastic Container Registry (Amazon ECR) private repositories. For more information, see Configuring access to an Amazon ECR private repository for an Amazon Lightsail container service (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-container-service-ecr-private-repo-access) in the Amazon Lightsail Developer Guide. — shape: {ecrImagePullerRole?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateContainerService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: power, var: power}, {name: scale, var: scale}, {name: tags, var: tags}, {name: publicDomainNames, var: public_domain_names}, {name: deployment, var: deployment}, {name: privateRegistryAccess, var: private_registry_access}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, power: $power, scale: $scale, tags: $tags, public_domain_names: $public_domain_names, deployment: $deployment, private_registry_access: $private_registry_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a deployment for your Amazon Lightsail container service. A deployment specifies the containers that will be launched on the container service and their settings, such as the ports to open, the environment variables to apply, and the launch command to run. It also specifies the container that will serve as the public endpoint of the deployment and its settings, such as the HTTP or HTTPS port to use, and the health check configuration. You can deploy containers to your container service using container images from a public registry such as Amazon ECR Public, or from your local machine. For more information, see Creating container images for your Amazon Lightsail container services (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-creating-container-images) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>
# operationId: CreateContainerServiceDeployment
export def "create-container-service-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_name: string # The name of the container service for which to create the deployment.
  --containers: record # An object that describes the settings of the containers that will be launched on the container service.
  --public-endpoint: record # Describes the settings of a public endpoint for an Amazon Lightsail container service. — shape: {containerName: string, containerPort: int, healthCheck?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateContainerServiceDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: containers, var: containers}, {name: publicEndpoint, var: public_endpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, containers: $containers, public_endpoint: $public_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a temporary set of log in credentials that you can use to log in to the Docker process on your local machine. After you're logged in, you can use the native Docker commands to push your local container images to the container image registry of your Amazon Lightsail account so that you can use them with your Lightsail container service. The log in credentials expire 12 hours after they are created, at which point you will need to create a new set of log in credentials. You can only push container images to the container service registry of your Lightsail account. You cannot pull container images or perform any other container image management actions on the container service registry. After you push your container images to the container image registry of your Lightsail account, use the RegisterContainerImage action to register the pushed images to a specific Lightsail container service. This action is not required if you install and use the Lightsail Control (lightsailctl) plugin to push container images to your Lightsail container service. For more information, see Pushing and managing container images on your Amazon Lightsail container services (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-pushing-container-images) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<registryLogin: record<username: string, password: string, expiresAt: string, registry: string>>
# operationId: CreateContainerServiceRegistryLogin
export def "create-container-service-registry-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateContainerServiceRegistryLogin"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a block storage disk that can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., us-east-2a). The create disk operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateDisk
export def "create-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_name: string # The unique Lightsail disk name (e.g., my-disk).
  availability_zone: string # The Availability Zone where you want to create the disk (e.g., us-east-2a). Use the same Availability Zone as the Lightsail instance to which you want to attach the disk. Use the get regions operation to list the Availability Zones where Lightsail is currently available.
  size_in_gb: int # The size of the disk in GB (e.g., 32).
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
  --add-ons: list # An array of objects that represent the add-ons to enable for the new disk. — item shape: {addOnType: "AutoSnapshot"|"StopInstanceOnIdle", autoSnapshotAddOnRequest?: record, stopInstanceOnIdleRequest?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDisk"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}, {name: availabilityZone, var: availability_zone}, {name: sizeInGb, var: size_in_gb}, {name: tags, var: tags}, {name: addOns, var: add_ons}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name, availability_zone: $availability_zone, size_in_gb: $size_in_gb, tags: $tags, add_ons: $add_ons
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a block storage disk from a manual or automatic snapshot of a disk. The resulting disk can be attached to an Amazon Lightsail instance in the same Availability Zone (e.g., us-east-2a). The create disk from snapshot operation supports tag-based access control via request tags and resource tags applied to the resource identified by disk snapshot name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateDiskFromSnapshot
export def "create-disk-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_name: string # The unique Lightsail disk name (e.g., my-disk).
  --disk-snapshot-name: string # The name of the disk snapshot (e.g., my-snapshot) from which to create the new storage disk. Constraint: This parameter cannot be defined together with the source disk name parameter. The disk snapshot name and source disk name parameters are mutually exclusive.
  availability_zone: string # The Availability Zone where you want to create the disk (e.g., us-east-2a). Choose the same Availability Zone as the Lightsail instance where you want to create the disk. Use the GetRegions operation to list the Availability Zones where Lightsail is currently available.
  size_in_gb: int # The size of the disk in GB (e.g., 32).
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
  --add-ons: list # An array of objects that represent the add-ons to enable for the new disk. — item shape: {addOnType: "AutoSnapshot"|"StopInstanceOnIdle", autoSnapshotAddOnRequest?: record, stopInstanceOnIdleRequest?: record}
  --source-disk-name: string # The name of the source disk from which the source automatic snapshot was created. Constraints: This parameter cannot be defined together with the disk snapshot name parameter. The source disk name and disk snapshot name parameters are mutually exclusive. Define this parameter only when creating a new disk from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
  --restore-date: string # The date of the automatic snapshot to use for the new disk. Use the get auto snapshots operation to identify the dates of the available automatic snapshots. Constraints: Must be specified in YYYY-MM-DD format. This parameter cannot be defined together with the use latest restorable auto snapshot parameter. The restore date and use latest restorable auto snapshot parameters are mutually exclusive. Define this parameter only when creating a new disk from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
  --use-latest-restorable-auto-snapshot: oneof<nothing, bool> # A Boolean value to indicate whether to use the latest available automatic snapshot. Constraints: This parameter cannot be defined together with the restore date parameter. The use latest restorable auto snapshot and restore date parameters are mutually exclusive. Define this parameter only when creating a new disk from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDiskFromSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}, {name: diskSnapshotName, var: disk_snapshot_name}, {name: availabilityZone, var: availability_zone}, {name: sizeInGb, var: size_in_gb}, {name: tags, var: tags}, {name: addOns, var: add_ons}, {name: sourceDiskName, var: source_disk_name}, {name: restoreDate, var: restore_date}, {name: useLatestRestorableAutoSnapshot, var: use_latest_restorable_auto_snapshot}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name, disk_snapshot_name: $disk_snapshot_name, availability_zone: $availability_zone, size_in_gb: $size_in_gb, tags: $tags, add_ons: $add_ons, source_disk_name: $source_disk_name, restore_date: $restore_date, use_latest_restorable_auto_snapshot: $use_latest_restorable_auto_snapshot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of a block storage disk. You can use snapshots for backups, to make copies of disks, and to save data before shutting down a Lightsail instance. You can take a snapshot of an attached disk that is in use; however, snapshots only capture data that has been written to your disk at the time the snapshot command is issued. This may exclude any data that has been cached by any applications or the operating system. If you can pause any file systems on the disk long enough to take a snapshot, your snapshot should be complete. Nevertheless, if you cannot pause all file writes to the disk, you should unmount the disk from within the Lightsail instance, issue the create disk snapshot command, and then remount the disk to ensure a consistent and complete snapshot. You may remount and use your disk while the snapshot status is pending. You can also use this operation to create a snapshot of an instance's system volume. You might want to do this, for example, to recover data from the system volume of a botched instance or to create a backup of the system volume like you would for a block storage disk. To create a snapshot of a system volume, just define the instance name parameter when issuing the snapshot command, and a snapshot of the defined instance's system volume will be created. After the snapshot is available, you can create a block storage disk from the snapshot and attach it to a running instance to access the data on the disk. The create disk snapshot operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateDiskSnapshot
export def "create-disk-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --disk-name: string # The unique name of the source disk (e.g., Disk-Virginia-1). This parameter cannot be defined together with the instance name parameter. The disk name and instance name parameters are mutually exclusive.
  disk_snapshot_name: string # The name of the destination disk snapshot (e.g., my-disk-snapshot) based on the source disk.
  --instance-name: string # The unique name of the source instance (e.g., Amazon_Linux-512MB-Virginia-1). When this is defined, a snapshot of the instance's system volume is created. This parameter cannot be defined together with the disk name parameter. The instance name and disk name parameters are mutually exclusive.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDiskSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}, {name: diskSnapshotName, var: disk_snapshot_name}, {name: instanceName, var: instance_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name, disk_snapshot_name: $disk_snapshot_name, instance_name: $instance_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Lightsail content delivery network (CDN) distribution. A distribution is a globally distributed network of caching servers that improve the performance of your website or web application hosted on a Lightsail instance. For more information, see Content delivery networks in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-content-delivery-network-distributions).
#
# POST /
# Returns: record<distribution: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, alternativeDomainNames: list<string>, status: string, isEnabled: bool, domainName: string, bundleId: string, certificateName: string, origin: record<name: string, resourceType: string, regionName: string, protocolPolicy: string>, originPublicDNS: string, defaultCacheBehavior: record<behavior: string>, cacheBehaviorSettings: record<defaultTTL: int, minimumTTL: int, maximumTTL: int, allowedHTTPMethods: string, cachedHTTPMethods: string, forwardedCookies: record, forwardedHeaders: record, forwardedQueryStrings: record>, cacheBehaviors: list<record>, ableToUpdateBundle: bool, ipAddressType: string, tags: list<record>>, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateDistribution
export def "create-distribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  distribution_name: string # The name for the distribution.
  origin: record # Describes the origin resource of an Amazon Lightsail content delivery network (CDN) distribution. An origin can be a Lightsail instance, bucket, or load balancer. A distribution pulls content from an origin, caches it, and serves it to viewers via a worldwide network of edge servers. — shape: {name?: string, regionName?: "us-east-1"|"us-east-2"|"us-west-1"|"us-west-2"|"eu-west-1"|"eu-west-2"|"eu-west-3"|"eu-central-1"|"ca-central-1"|"ap-south-1"|"ap-southeast-1"|"ap-southeast-2"|"ap-northeast-1"|"ap-northeast-2"|"eu-north-1", protocolPolicy?: "http-only"|"https-only"}
  default_cache_behavior: record # Describes the default cache behavior of an Amazon Lightsail content delivery network (CDN) distribution. — shape: {behavior?: "dont-cache"|"cache"}
  --cache-behavior-settings: record # Describes the cache settings of an Amazon Lightsail content delivery network (CDN) distribution. These settings apply only to your distribution's cacheBehaviors (including the defaultCacheBehavior) that have a behavior of cache. — shape: {defaultTTL?: int, minimumTTL?: int, maximumTTL?: int, allowedHTTPMethods?: string, cachedHTTPMethods?: string, forwardedCookies?: record, forwardedHeaders?: record, forwardedQueryStrings?: record}
  --cache-behaviors: list # An array of objects that describe the per-path cache behavior for the distribution. — item shape: {path?: string, behavior?: "dont-cache"|"cache"}
  bundle_id: string # The bundle ID to use for the distribution. A distribution bundle describes the specifications of your distribution, such as the monthly cost and monthly network transfer quota. Use the GetDistributionBundles action to get a list of distribution bundle IDs that you can specify.
  --ip-address-type: string@ip-address-type-completer # The IP address type for the distribution. The possible values are ipv4 for IPv4 only, and dualstack for IPv4 and IPv6. The default value is dualstack.
  --tags: list # The tag keys and optional values to add to the distribution during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDistribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: origin, var: origin}, {name: defaultCacheBehavior, var: default_cache_behavior}, {name: cacheBehaviorSettings, var: cache_behavior_settings}, {name: cacheBehaviors, var: cache_behaviors}, {name: bundleId, var: bundle_id}, {name: ipAddressType, var: ip_address_type}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, origin: $origin, default_cache_behavior: $default_cache_behavior, cache_behavior_settings: $cache_behavior_settings, cache_behaviors: $cache_behaviors, bundle_id: $bundle_id, ip_address_type: $ip_address_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a domain resource for the specified domain (e.g., example.com). The create domain operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  domain_name: string # The domain name to manage (e.g., example.com).
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one of the following domain name system (DNS) records in a domain DNS zone: Address (A), canonical name (CNAME), mail exchanger (MX), name server (NS), start of authority (SOA), service locator (SRV), or text (TXT). The create domain entry operation supports tag-based access control via resource tags applied to the resource identified by domain name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateDomainEntry
export def "create-domain-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  domain_name: string # The domain name (e.g., example.com) for which you want to create the domain entry.
  domain_entry: record # Describes a domain recordset entry. — shape: {id?: string, name?: string, target?: string, isAlias?: bool, type?: string, options?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateDomainEntry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: domainEntry, var: domain_entry}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, domain_entry: $domain_entry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates two URLs that are used to access a virtual computer’s graphical user interface (GUI) session. The primary URL initiates a web-based NICE DCV session to the virtual computer's application. The secondary URL initiates a web-based NICE DCV session to the virtual computer's operating session. Use StartGUISession to open the session.
#
# POST /
# Returns: record<resourceName: string, status: string, percentageComplete: int, failureReason: string, sessions: table<name: string, url: string, isPrimary: bool>>
# operationId: CreateGUISessionAccessDetails
export def "create-gui-session-access-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_name: string # The resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateGUISessionAccessDetails"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of a specific virtual private server, or instance. You can use a snapshot to create a new instance that is based on that snapshot. The create instance snapshot operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateInstanceSnapshot
export def "create-instance-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_snapshot_name: string # The name for your new snapshot.
  instance_name: string # The Lightsail instance on which to base your snapshot.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateInstanceSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceSnapshotName, var: instance_snapshot_name}, {name: instanceName, var: instance_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_snapshot_name: $instance_snapshot_name, instance_name: $instance_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more Amazon Lightsail instances. The create instances operation supports tag-based access control via request tags. For more information, see the Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateInstances
export def "create-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_names: list<string> # The names to use for your new Lightsail instances. Separate multiple values using quotation marks and commas, for example: ["MyFirstInstance","MySecondInstance"]
  availability_zone: string # The Availability Zone in which to create your instance. Use the following format: us-east-2a (case sensitive). You can get a list of Availability Zones by using the get regions (http://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetRegions.html) operation. Be sure to add the include Availability Zones parameter to your request.
  --custom-image-name: string # (Deprecated) The name for your custom image. In releases prior to June 12, 2017, this parameter was ignored by the API. It is now deprecated.
  blueprint_id: string # The ID for a virtual private server image (e.g., app_wordpress_4_4 or app_lamp_7_0). Use the get blueprints operation to return a list of available images (or blueprints). Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.
  bundle_id: string # The bundle of specification information for your virtual private server (or instance), including the pricing plan (e.g., micro_1_0).
  --user-data: string # A launch script you can create that configures a server with additional user data. For example, you might want to run apt-get -y update. Depending on the machine image you choose, the command to get software on your instance varies. Amazon Linux and CentOS use yum, Debian and Ubuntu use apt-get, and FreeBSD uses pkg. For a complete list, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/compare-options-choose-lightsail-instance-image).
  --key-pair-name: string # The name of your key pair.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
  --add-ons: list # An array of objects representing the add-ons to enable for the new instance. — item shape: {addOnType: "AutoSnapshot"|"StopInstanceOnIdle", autoSnapshotAddOnRequest?: record, stopInstanceOnIdleRequest?: record}
  --ip-address-type: string@ip-address-type-completer # The IP address type for the instance. The possible values are ipv4 for IPv4 only, and dualstack for IPv4 and IPv6. The default value is dualstack.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceNames, var: instance_names}, {name: availabilityZone, var: availability_zone}, {name: customImageName, var: custom_image_name}, {name: blueprintId, var: blueprint_id}, {name: bundleId, var: bundle_id}, {name: userData, var: user_data}, {name: keyPairName, var: key_pair_name}, {name: tags, var: tags}, {name: addOns, var: add_ons}, {name: ipAddressType, var: ip_address_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_names: $instance_names, availability_zone: $availability_zone, custom_image_name: $custom_image_name, blueprint_id: $blueprint_id, bundle_id: $bundle_id, user_data: $user_data, key_pair_name: $key_pair_name, tags: $tags, add_ons: $add_ons, ip_address_type: $ip_address_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more new instances from a manual or automatic snapshot of an instance. The create instances from snapshot operation supports tag-based access control via request tags and resource tags applied to the resource identified by instance snapshot name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateInstancesFromSnapshot
export def "create-instances-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_names: list<string> # The names for your new instances.
  --attached-disk-mapping: record # An object containing information about one or more disk mappings.
  availability_zone: string # The Availability Zone where you want to create your instances. Use the following formatting: us-east-2a (case sensitive). You can get a list of Availability Zones by using the get regions (http://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetRegions.html) operation. Be sure to add the include Availability Zones parameter to your request.
  --instance-snapshot-name: string # The name of the instance snapshot on which you are basing your new instances. Use the get instance snapshots operation to return information about your existing snapshots. Constraint: This parameter cannot be defined together with the source instance name parameter. The instance snapshot name and source instance name parameters are mutually exclusive.
  bundle_id: string # The bundle of specification information for your virtual private server (or instance), including the pricing plan (e.g., micro_1_0).
  --user-data: string # You can create a launch script that configures a server with additional user data. For example, apt-get -y update. Depending on the machine image you choose, the command to get software on your instance varies. Amazon Linux and CentOS use yum, Debian and Ubuntu use apt-get, and FreeBSD uses pkg. For a complete list, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/compare-options-choose-lightsail-instance-image).
  --key-pair-name: string # The name for your key pair.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
  --add-ons: list # An array of objects representing the add-ons to enable for the new instance. — item shape: {addOnType: "AutoSnapshot"|"StopInstanceOnIdle", autoSnapshotAddOnRequest?: record, stopInstanceOnIdleRequest?: record}
  --ip-address-type: string@ip-address-type-completer # The IP address type for the instance. The possible values are ipv4 for IPv4 only, and dualstack for IPv4 and IPv6. The default value is dualstack.
  --source-instance-name: string # The name of the source instance from which the source automatic snapshot was created. Constraints: This parameter cannot be defined together with the instance snapshot name parameter. The source instance name and instance snapshot name parameters are mutually exclusive. Define this parameter only when creating a new instance from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
  --restore-date: string # The date of the automatic snapshot to use for the new instance. Use the get auto snapshots operation to identify the dates of the available automatic snapshots. Constraints: Must be specified in YYYY-MM-DD format. This parameter cannot be defined together with the use latest restorable auto snapshot parameter. The restore date and use latest restorable auto snapshot parameters are mutually exclusive. Define this parameter only when creating a new instance from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
  --use-latest-restorable-auto-snapshot: oneof<nothing, bool> # A Boolean value to indicate whether to use the latest available automatic snapshot. Constraints: This parameter cannot be defined together with the restore date parameter. The use latest restorable auto snapshot and restore date parameters are mutually exclusive. Define this parameter only when creating a new instance from an automatic snapshot. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateInstancesFromSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceNames, var: instance_names}, {name: attachedDiskMapping, var: attached_disk_mapping}, {name: availabilityZone, var: availability_zone}, {name: instanceSnapshotName, var: instance_snapshot_name}, {name: bundleId, var: bundle_id}, {name: userData, var: user_data}, {name: keyPairName, var: key_pair_name}, {name: tags, var: tags}, {name: addOns, var: add_ons}, {name: ipAddressType, var: ip_address_type}, {name: sourceInstanceName, var: source_instance_name}, {name: restoreDate, var: restore_date}, {name: useLatestRestorableAutoSnapshot, var: use_latest_restorable_auto_snapshot}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_names: $instance_names, attached_disk_mapping: $attached_disk_mapping, availability_zone: $availability_zone, instance_snapshot_name: $instance_snapshot_name, bundle_id: $bundle_id, user_data: $user_data, key_pair_name: $key_pair_name, tags: $tags, add_ons: $add_ons, ip_address_type: $ip_address_type, source_instance_name: $source_instance_name, restore_date: $restore_date, use_latest_restorable_auto_snapshot: $use_latest_restorable_auto_snapshot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom SSH key pair that you can use with an Amazon Lightsail instance. Use the DownloadDefaultKeyPair (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_DownloadDefaultKeyPair.html) action to create a Lightsail default key pair in an Amazon Web Services Region where a default key pair does not currently exist. The create key pair operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<keyPair: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, fingerprint: string>, publicKeyBase64: string, privateKeyBase64: string, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateKeyPair
export def "create-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  key_pair_name: string # The name for your new key pair.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateKeyPair"}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyPairName, var: key_pair_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, key_pair_name: $key_pair_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Lightsail load balancer. To learn more about deciding whether to load balance your application, see Configure your Lightsail instances for load balancing (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/configure-lightsail-instances-for-load-balancing). You can create up to 5 load balancers per AWS Region in your account. When you create a load balancer, you can specify a unique name and port settings. To change additional load balancer settings, use the UpdateLoadBalancerAttribute operation. The create load balancer operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateLoadBalancer
export def "create-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The name of your load balancer.
  instance_port: int # The instance port where you're creating your load balancer.
  --health-check-path: string # The path you provided to perform the load balancer health check. If you didn't specify a health check path, Lightsail uses the root path of your website (e.g., "/"). You may want to specify a custom health check path other than the root of your application if your home page loads slowly or has a lot of media or scripting on it.
  --certificate-name: string # The name of the SSL/TLS certificate. If you specify certificateName, then certificateDomainName is required (and vice-versa).
  --certificate-domain-name: string # The domain name with which your certificate is associated (e.g., example.com). If you specify certificateDomainName, then certificateName is required (and vice-versa).
  --certificate-alternative-names: list<string> # The optional alternative domains and subdomains to use with your SSL/TLS certificate (e.g., www.example.com, example.com, m.example.com, blog.example.com).
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
  --ip-address-type: string@ip-address-type-completer # The IP address type for the load balancer. The possible values are ipv4 for IPv4 only, and dualstack for IPv4 and IPv6. The default value is dualstack.
  --tls-policy-name: string # The name of the TLS policy to apply to the load balancer. Use the GetLoadBalancerTlsPolicies (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetLoadBalancerTlsPolicies.html) action to get a list of TLS policy names that you can specify. For more information about load balancer TLS policies, see Configuring TLS security policies on your Amazon Lightsail load balancers (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configure-load-balancer-tls-security-policy) in the Amazon Lightsail Developer Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: instancePort, var: instance_port}, {name: healthCheckPath, var: health_check_path}, {name: certificateName, var: certificate_name}, {name: certificateDomainName, var: certificate_domain_name}, {name: certificateAlternativeNames, var: certificate_alternative_names}, {name: tags, var: tags}, {name: ipAddressType, var: ip_address_type}, {name: tlsPolicyName, var: tls_policy_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, instance_port: $instance_port, health_check_path: $health_check_path, certificate_name: $certificate_name, certificate_domain_name: $certificate_domain_name, certificate_alternative_names: $certificate_alternative_names, tags: $tags, ip_address_type: $ip_address_type, tls_policy_name: $tls_policy_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an SSL/TLS certificate for an Amazon Lightsail load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL). The CreateLoadBalancerTlsCertificate operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateLoadBalancerTlsCertificate
export def "create-load-balancer-tls-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The load balancer name where you want to create the SSL/TLS certificate.
  certificate_name: string # The SSL/TLS certificate name. You can have up to 10 certificates in your account at one time. Each Lightsail load balancer can have up to 2 certificates associated with it at one time. There is also an overall limit to the number of certificates that can be issue in a 365-day period. For more information, see Limits (http://docs.aws.amazon.com/acm/latest/userguide/acm-limits.html).
  certificate_domain_name: string # The domain name (e.g., example.com) for your SSL/TLS certificate.
  --certificate-alternative-names: list<string> # An array of strings listing alternative domains and subdomains for your SSL/TLS certificate. Lightsail will de-dupe the names for you. You can have a maximum of 9 alternative names (in addition to the 1 primary domain). We do not support wildcards (e.g., *.example.com).
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateLoadBalancerTlsCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: certificateName, var: certificate_name}, {name: certificateDomainName, var: certificate_domain_name}, {name: certificateAlternativeNames, var: certificate_alternative_names}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, certificate_name: $certificate_name, certificate_domain_name: $certificate_domain_name, certificate_alternative_names: $certificate_alternative_names, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new database in Amazon Lightsail. The create relational database operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateRelationalDatabase
export def "create-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  relational_database_name: string # The name to use for your new Lightsail database resource. Constraints: Must contain from 2 to 255 alphanumeric characters, or hyphens. The first and last character must be a letter or number.
  --availability-zone: string # The Availability Zone in which to create your new database. Use the us-east-2a case-sensitive format. You can get a list of Availability Zones by using the get regions operation. Be sure to add the include relational database Availability Zones parameter to your request.
  relational_database_blueprint_id: string # The blueprint ID for your new database. A blueprint describes the major engine version of a database. You can get a list of database blueprints IDs by using the get relational database blueprints operation.
  relational_database_bundle_id: string # The bundle ID for your new database. A bundle describes the performance specifications for your database. You can get a list of database bundle IDs by using the get relational database bundles operation.
  master_database_name: string # The meaning of this parameter differs according to the database engine you use. MySQL The name of the database to create when the Lightsail database resource is created. If this parameter isn't specified, no database is created in the database resource. Constraints: Must contain 1 to 64 letters or numbers. Must begin with a letter. Subsequent characters can be letters, underscores, or digits (0- 9). Can't be a word reserved by the specified database engine. For more information about reserved words in MySQL, see the Keywords and Reserved Words articles for MySQL 5.6 (https://dev.mysql.com/doc/refman/5.6/en/keywords.html), MySQL 5.7 (https://dev.mysql.com/doc/refman/5.7/en/keywords.html), and MySQL 8.0 (https://dev.mysql.com/doc/refman/8.0/en/keywords.html). PostgreSQL The name of the database to create when the Lightsail database resource is created. If this parameter isn't specified, a database named postgres is created in the database resource. Constraints: Must contain 1 to 63 letters or numbers. Must begin with a letter. Subsequent characters can be letters, underscores, or digits (0- 9). Can't be a word reserved by the specified database engine. For more information about reserved words in PostgreSQL, see the SQL Key Words articles for PostgreSQL 9.6 (https://www.postgresql.org/docs/9.6/sql-keywords-appendix.html), PostgreSQL 10 (https://www.postgresql.org/docs/10/sql-keywords-appendix.html), PostgreSQL 11 (https://www.postgresql.org/docs/11/sql-keywords-appendix.html), and PostgreSQL 12 (https://www.postgresql.org/docs/12/sql-keywords-appendix.html).
  master_username: string # The name for the master user. MySQL Constraints: Required for MySQL. Must be 1 to 16 letters or numbers. Can contain underscores. First character must be a letter. Can't be a reserved word for the chosen database engine. For more information about reserved words in MySQL 5.6 or 5.7, see the Keywords and Reserved Words articles for MySQL 5.6 (https://dev.mysql.com/doc/refman/5.6/en/keywords.html), MySQL 5.7 (https://dev.mysql.com/doc/refman/5.7/en/keywords.html), or MySQL 8.0 (https://dev.mysql.com/doc/refman/8.0/en/keywords.html). PostgreSQL Constraints: Required for PostgreSQL. Must be 1 to 63 letters or numbers. Can contain underscores. First character must be a letter. Can't be a reserved word for the chosen database engine. For more information about reserved words in MySQL 5.6 or 5.7, see the Keywords and Reserved Words articles for PostgreSQL 9.6 (https://www.postgresql.org/docs/9.6/sql-keywords-appendix.html), PostgreSQL 10 (https://www.postgresql.org/docs/10/sql-keywords-appendix.html), PostgreSQL 11 (https://www.postgresql.org/docs/11/sql-keywords-appendix.html), and PostgreSQL 12 (https://www.postgresql.org/docs/12/sql-keywords-appendix.html).
  --master-user-password: string # The password for the master user. The password can include any printable ASCII character except "/", """, or "@". It cannot contain spaces. MySQL Constraints: Must contain from 8 to 41 characters. PostgreSQL Constraints: Must contain from 8 to 128 characters. (format: password)
  --preferred-backup-window: string # The daily time range during which automated backups are created for your new database if automated backups are enabled. The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. For more information about the preferred backup window time blocks for each region, see the Working With Backups (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html#USER_WorkingWithAutomatedBackups.BackupWindow) guide in the Amazon Relational Database Service documentation. Constraints: Must be in the hh24:mi-hh24:mi format. Example: 16:00-16:30 Specified in Coordinated Universal Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur on your new database. The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. Constraints: Must be in the ddd:hh24:mi-ddd:hh24:mi format. Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun. Must be at least 30 minutes. Specified in Coordinated Universal Time (UTC). Example: Tue:17:00-Tue:17:30
  --publicly-accessible: oneof<nothing, bool> # Specifies the accessibility options for your new database. A value of true specifies a database that is available to resources outside of your Lightsail account. A value of false specifies a database that is available only to your Lightsail resources in the same region as your database.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: availabilityZone, var: availability_zone}, {name: relationalDatabaseBlueprintId, var: relational_database_blueprint_id}, {name: relationalDatabaseBundleId, var: relational_database_bundle_id}, {name: masterDatabaseName, var: master_database_name}, {name: masterUsername, var: master_username}, {name: masterUserPassword, var: master_user_password}, {name: preferredBackupWindow, var: preferred_backup_window}, {name: preferredMaintenanceWindow, var: preferred_maintenance_window}, {name: publiclyAccessible, var: publicly_accessible}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, availability_zone: $availability_zone, relational_database_blueprint_id: $relational_database_blueprint_id, relational_database_bundle_id: $relational_database_bundle_id, master_database_name: $master_database_name, master_username: $master_username, master_user_password: $master_user_password, preferred_backup_window: $preferred_backup_window, preferred_maintenance_window: $preferred_maintenance_window, publicly_accessible: $publicly_accessible, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new database from an existing database snapshot in Amazon Lightsail. You can create a new database from a snapshot in if something goes wrong with your original database, or to change it to a different plan, such as a high availability or standard plan. The create relational database from snapshot operation supports tag-based access control via request tags and resource tags applied to the resource identified by relationalDatabaseSnapshotName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateRelationalDatabaseFromSnapshot
export def "create-relational-database-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  relational_database_name: string # The name to use for your new Lightsail database resource. Constraints: Must contain from 2 to 255 alphanumeric characters, or hyphens. The first and last character must be a letter or number.
  --availability-zone: string # The Availability Zone in which to create your new database. Use the us-east-2a case-sensitive format. You can get a list of Availability Zones by using the get regions operation. Be sure to add the include relational database Availability Zones parameter to your request.
  --publicly-accessible: oneof<nothing, bool> # Specifies the accessibility options for your new database. A value of true specifies a database that is available to resources outside of your Lightsail account. A value of false specifies a database that is available only to your Lightsail resources in the same region as your database.
  --relational-database-snapshot-name: string # The name of the database snapshot from which to create your new database.
  --relational-database-bundle-id: string # The bundle ID for your new database. A bundle describes the performance specifications for your database. You can get a list of database bundle IDs by using the get relational database bundles operation. When creating a new database from a snapshot, you cannot choose a bundle that is smaller than the bundle of the source database.
  --source-relational-database-name: string # The name of the source database.
  --restore-time: string # The date and time to restore your database from. Constraints: Must be before the latest restorable time for the database. Cannot be specified if the use latest restorable time parameter is true. Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a restore time of October 1, 2018, at 8 PM UTC, then you input 1538424000 as the restore time. (format: date-time)
  --use-latest-restorable-time: oneof<nothing, bool> # Specifies whether your database is restored from the latest backup time. A value of true restores from the latest backup time. Default: false Constraints: Cannot be specified if the restore time parameter is provided.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateRelationalDatabaseFromSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: availabilityZone, var: availability_zone}, {name: publiclyAccessible, var: publicly_accessible}, {name: relationalDatabaseSnapshotName, var: relational_database_snapshot_name}, {name: relationalDatabaseBundleId, var: relational_database_bundle_id}, {name: sourceRelationalDatabaseName, var: source_relational_database_name}, {name: restoreTime, var: restore_time}, {name: useLatestRestorableTime, var: use_latest_restorable_time}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, availability_zone: $availability_zone, publicly_accessible: $publicly_accessible, relational_database_snapshot_name: $relational_database_snapshot_name, relational_database_bundle_id: $relational_database_bundle_id, source_relational_database_name: $source_relational_database_name, restore_time: $restore_time, use_latest_restorable_time: $use_latest_restorable_time, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a snapshot of your database in Amazon Lightsail. You can use snapshots for backups, to make copies of a database, and to save data before deleting a database. The create relational database snapshot operation supports tag-based access control via request tags. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: CreateRelationalDatabaseSnapshot
export def "create-relational-database-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  relational_database_name: string # The name of the database on which to base your new snapshot.
  relational_database_snapshot_name: string # The name for your new database snapshot. Constraints: Must contain from 2 to 255 alphanumeric characters, or hyphens. The first and last character must be a letter or number.
  --tags: list # The tag keys and optional values to add to the resource during create. Use the TagResource action to tag a resource after it's created. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.CreateRelationalDatabaseSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: relationalDatabaseSnapshotName, var: relational_database_snapshot_name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, relational_database_snapshot_name: $relational_database_snapshot_name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an alarm. An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see Alarms in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteAlarm
export def "delete-alarm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  alarm_name: string # The name of the alarm to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteAlarm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: alarmName, var: alarm_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, alarm_name: $alarm_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an automatic snapshot of an instance or disk. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteAutoSnapshot
export def "delete-auto-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_name: string # The name of the source instance or disk from which to delete the automatic snapshot.
  date: string # The date of the automatic snapshot to delete in YYYY-MM-DD format. Use the get auto snapshots operation to get the available automatic snapshots for a resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteAutoSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: date, var: date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Amazon Lightsail bucket. When you delete your bucket, the bucket name is released and can be reused for a new bucket in your account or another Amazon Web Services account.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteBucket
export def "delete-bucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  bucket_name: string # The name of the bucket to delete. Use the GetBuckets (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBuckets.html) action to get a list of bucket names that you can specify.
  --force-delete: oneof<nothing, bool> # A Boolean value that indicates whether to force delete the bucket. You must force delete the bucket if it has one of the following conditions: The bucket is the origin of a distribution. The bucket has instances that were granted access to it using the SetResourceAccessForBucket (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_SetResourceAccessForBucket.html) action. The bucket has objects. The bucket has access keys. Force deleting a bucket might impact other resources that rely on the bucket, such as instances, distributions, or software that use the issued access keys.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteBucket"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: forceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an access key for the specified Amazon Lightsail bucket. We recommend that you delete an access key if the secret access key is compromised. For more information about access keys, see Creating access keys for a bucket in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-creating-bucket-access-keys) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteBucketAccessKey
export def "delete-bucket-access-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  bucket_name: string # The name of the bucket that the access key belongs to.
  access_key_id: string # The ID of the access key to delete. Use the GetBucketAccessKeys (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBucketAccessKeys.html) action to get a list of access key IDs that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteBucketAccessKey"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: accessKeyId, var: access_key_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, access_key_id: $access_key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an SSL/TLS certificate for your Amazon Lightsail content delivery network (CDN) distribution. Certificates that are currently attached to a distribution cannot be deleted. Use the DetachCertificateFromDistribution action to detach a certificate from a distribution.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteCertificate
export def "delete-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  certificate_name: string # The name of the certificate to delete. Use the GetCertificates action to get a list of certificate names that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateName, var: certificate_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, certificate_name: $certificate_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a contact method. A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each Amazon Web Services Region. However, SMS text messaging is not supported in some Amazon Web Services Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see Notifications in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteContactMethod
export def "delete-contact-method" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  protocol: string@protocol-completer # The protocol that will be deleted, such as Email or SMS (text messaging). To delete an Email and an SMS contact method if you added both, you must run separate DeleteContactMethod actions to delete each protocol.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteContactMethod"}]
    body: {content_type: "application/json", kind: json, fields: [{name: protocol, var: protocol}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a container image that is registered to your Amazon Lightsail container service.
#
# POST /
# Returns: record
# operationId: DeleteContainerImage
export def "delete-container-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_name: string # The name of the container service for which to delete a registered container image.
  image: string # The name of the container image to delete from the container service. Use the GetContainerImages action to get the name of the container images that are registered to a container service. Container images sourced from your Lightsail container service, that are registered and stored on your service, start with a colon (:). For example, :container-service-1.mystaticwebsite.1. Container images sourced from a public registry like Docker Hub don't start with a colon. For example, nginx:latest or nginx.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteContainerImage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: image, var: image}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes your Amazon Lightsail container service.
#
# POST /
# Returns: record
# operationId: DeleteContainerService
export def "delete-container-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  service_name: string # The name of the container service to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteContainerService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified block storage disk. The disk must be in the available state (not attached to a Lightsail instance). The disk may remain in the deleting state for several minutes. The delete disk operation supports tag-based access control via resource tags applied to the resource identified by disk name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteDisk
export def "delete-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_name: string # The unique name of the disk you want to delete (e.g., my-disk).
  --force-delete-add-ons: oneof<nothing, bool> # A Boolean value to indicate whether to delete all add-ons for the disk.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteDisk"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}, {name: forceDeleteAddOns, var: force_delete_add_ons}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name, force_delete_add_ons: $force_delete_add_ons
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified disk snapshot. When you make periodic snapshots of a disk, the snapshots are incremental, and only the blocks on the device that have changed since your last snapshot are saved in the new snapshot. When you delete a snapshot, only the data not needed for any other snapshot is removed. So regardless of which prior snapshots have been deleted, all active snapshots will have access to all the information needed to restore the disk. The delete disk snapshot operation supports tag-based access control via resource tags applied to the resource identified by disk snapshot name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteDiskSnapshot
export def "delete-disk-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_snapshot_name: string # The name of the disk snapshot you want to delete (e.g., my-disk-snapshot).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteDiskSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskSnapshotName, var: disk_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_snapshot_name: $disk_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes your Amazon Lightsail content delivery network (CDN) distribution.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteDistribution
export def "delete-distribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --distribution-name: string # The name of the distribution to delete. Use the GetDistributions action to get a list of distribution names that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteDistribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified domain recordset and all of its domain records. The delete domain operation supports tag-based access control via resource tags applied to the resource identified by domain name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  domain_name: string # The specific domain name to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific domain entry. The delete domain entry operation supports tag-based access control via resource tags applied to the resource identified by domain name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteDomainEntry
export def "delete-domain-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  domain_name: string # The name of the domain entry to delete.
  domain_entry: record # Describes a domain recordset entry. — shape: {id?: string, name?: string, target?: string, isAlias?: bool, type?: string, options?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteDomainEntry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: domainEntry, var: domain_entry}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, domain_entry: $domain_entry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon Lightsail instance. The delete instance operation supports tag-based access control via resource tags applied to the resource identified by instance name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteInstance
export def "delete-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_name: string # The name of the instance to delete.
  --force-delete-add-ons: oneof<nothing, bool> # A Boolean value to indicate whether to delete all add-ons for the instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: forceDeleteAddOns, var: force_delete_add_ons}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, force_delete_add_ons: $force_delete_add_ons
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific snapshot of a virtual private server (or instance). The delete instance snapshot operation supports tag-based access control via resource tags applied to the resource identified by instance snapshot name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteInstanceSnapshot
export def "delete-instance-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_snapshot_name: string # The name of the snapshot to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteInstanceSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceSnapshotName, var: instance_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_snapshot_name: $instance_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified key pair by removing the public key from Amazon Lightsail. You can delete key pairs that were created using the ImportKeyPair (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_ImportKeyPair.html) and CreateKeyPair (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_CreateKeyPair.html) actions, as well as the Lightsail default key pair. A new default key pair will not be created unless you launch an instance without specifying a custom key pair, or you call the DownloadDefaultKeyPair (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_DownloadDefaultKeyPair.html) API. The delete key pair operation supports tag-based access control via resource tags applied to the resource identified by key pair name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteKeyPair
export def "delete-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  key_pair_name: string # The name of the key pair to delete.
  --expected-fingerprint: string # The RSA fingerprint of the Lightsail default key pair to delete. The expectedFingerprint parameter is required only when specifying to delete a Lightsail default key pair.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteKeyPair"}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyPairName, var: key_pair_name}, {name: expectedFingerprint, var: expected_fingerprint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, key_pair_name: $key_pair_name, expected_fingerprint: $expected_fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the known host key or certificate used by the Amazon Lightsail browser-based SSH or RDP clients to authenticate an instance. This operation enables the Lightsail browser-based SSH or RDP clients to connect to the instance after a host key mismatch. Perform this operation only if you were expecting the host key or certificate mismatch or if you are familiar with the new host key or certificate on the instance. For more information, see Troubleshooting connection issues when using the Amazon Lightsail browser-based SSH or RDP client (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-troubleshooting-browser-based-ssh-rdp-client-connection).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteKnownHostKeys
export def "delete-known-host-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  instance_name: string # The name of the instance for which you want to reset the host key or certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteKnownHostKeys"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Lightsail load balancer and all its associated SSL/TLS certificates. Once the load balancer is deleted, you will need to create a new load balancer, create a new certificate, and verify domain ownership again. The delete load balancer operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteLoadBalancer
export def "delete-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The name of the load balancer you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an SSL/TLS certificate associated with a Lightsail load balancer. The DeleteLoadBalancerTlsCertificate operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteLoadBalancerTlsCertificate
export def "delete-load-balancer-tls-certificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The load balancer name.
  certificate_name: string # The SSL/TLS certificate name.
  --force: oneof<nothing, bool> # When true, forces the deletion of an SSL/TLS certificate. There can be two certificates associated with a Lightsail load balancer: the primary and the backup. The force parameter is required when the primary SSL/TLS certificate is in use by an instance attached to the load balancer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteLoadBalancerTlsCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: certificateName, var: certificate_name}, {name: force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, certificate_name: $certificate_name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a database in Amazon Lightsail. The delete relational database operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteRelationalDatabase
export def "delete-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  relational_database_name: string # The name of the database that you are deleting.
  --skip-final-snapshot: oneof<nothing, bool> # Determines whether a final database snapshot is created before your database is deleted. If true is specified, no database snapshot is created. If false is specified, a database snapshot is created before your database is deleted. You must specify the final relational database snapshot name parameter if the skip final snapshot parameter is false. Default: false
  --final-relational-database-snapshot-name: string # The name of the database snapshot created if skip final snapshot is false, which is the default value for that parameter. Specifying this parameter and also specifying the skip final snapshot parameter to true results in an error. Constraints: Must contain from 2 to 255 alphanumeric characters, or hyphens. The first and last character must be a letter or number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: skipFinalSnapshot, var: skip_final_snapshot}, {name: finalRelationalDatabaseSnapshotName, var: final_relational_database_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, skip_final_snapshot: $skip_final_snapshot, final_relational_database_snapshot_name: $final_relational_database_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a database snapshot in Amazon Lightsail. The delete relational database snapshot operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DeleteRelationalDatabaseSnapshot
export def "delete-relational-database-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  relational_database_snapshot_name: string # The name of the database snapshot that you are deleting.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DeleteRelationalDatabaseSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseSnapshotName, var: relational_database_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_snapshot_name: $relational_database_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches an SSL/TLS certificate from your Amazon Lightsail content delivery network (CDN) distribution. After the certificate is detached, your distribution stops accepting traffic for all of the domains that are associated with the certificate.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DetachCertificateFromDistribution
export def "detach-certificate-from-distribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  distribution_name: string # The name of the distribution from which to detach the certificate. Use the GetDistributions action to get a list of distribution names that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DetachCertificateFromDistribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a stopped block storage disk from a Lightsail instance. Make sure to unmount any file systems on the device within your operating system before stopping the instance and detaching the disk. The detach disk operation supports tag-based access control via resource tags applied to the resource identified by disk name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DetachDisk
export def "detach-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  disk_name: string # The unique name of the disk you want to detach from your instance (e.g., my-disk).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DetachDisk"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches the specified instances from a Lightsail load balancer. This operation waits until the instances are no longer needed before they are detached from the load balancer. The detach instances from load balancer operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DetachInstancesFromLoadBalancer
export def "detach-instances-from-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  load_balancer_name: string # The name of the Lightsail load balancer.
  instance_names: list<string> # An array of strings containing the names of the instances you want to detach from the load balancer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DetachInstancesFromLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: instanceNames, var: instance_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, instance_names: $instance_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a static IP from the Amazon Lightsail instance to which it is attached.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DetachStaticIp
export def "detach-static-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  static_ip_name: string # The name of the static IP to detach from the instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DetachStaticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: staticIpName, var: static_ip_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, static_ip_name: $static_ip_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables an add-on for an Amazon Lightsail resource. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: DisableAddOn
export def "disable-add-on" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  add_on_type: string@add-on-type-completer # The add-on type to disable.
  resource_name: string # The name of the source resource for which to disable the add-on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DisableAddOn"}]
    body: {content_type: "application/json", kind: json, fields: [{name: addOnType, var: add_on_type}, {name: resourceName, var: resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, add_on_type: $add_on_type, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Downloads the regional Amazon Lightsail default key pair. This action also creates a Lightsail default key pair if a default key pair does not currently exist in the Amazon Web Services Region.
#
# POST /
# Returns: record<publicKeyBase64: string, privateKeyBase64: string, createdAt: string>
# operationId: DownloadDefaultKeyPair
export def "download-default-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.DownloadDefaultKeyPair"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or modifies an add-on for an Amazon Lightsail resource. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: EnableAddOn
export def "enable-add-on" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_name: string # The name of the source resource for which to enable or modify the add-on.
  add_on_request: record # Describes a request to enable, modify, or disable an add-on for an Amazon Lightsail resource. An additional cost may be associated with enabling add-ons. For more information, see the Lightsail pricing page (https://aws.amazon.com/lightsail/pricing/). — shape: {addOnType: "AutoSnapshot"|"StopInstanceOnIdle", autoSnapshotAddOnRequest?: record, stopInstanceOnIdleRequest?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.EnableAddOn"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: addOnRequest, var: add_on_request}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, add_on_request: $add_on_request
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports an Amazon Lightsail instance or block storage disk snapshot to Amazon Elastic Compute Cloud (Amazon EC2). This operation results in an export snapshot record that can be used with the create cloud formation stack operation to create new Amazon EC2 instances. Exported instance snapshots appear in Amazon EC2 as Amazon Machine Images (AMIs), and the instance system disk appears as an Amazon Elastic Block Store (Amazon EBS) volume. Exported disk snapshots appear in Amazon EC2 as Amazon EBS volumes. Snapshots are exported to the same Amazon Web Services Region in Amazon EC2 as the source Lightsail snapshot. The export snapshot operation supports tag-based access control via resource tags applied to the resource identified by source snapshot name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags). Use the get instance snapshots or get disk snapshots operations to get a list of snapshots that you can export to Amazon EC2.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: ExportSnapshot
export def "export-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  source_snapshot_name: string # The name of the instance or disk snapshot to be exported to Amazon EC2.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.ExportSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceSnapshotName, var: source_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_snapshot_name: $source_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the names of all active (not deleted) resources.
#
# POST /
# Returns: record<activeNames: list<string>, nextPageToken: string>
# operationId: GetActiveNames
export def "get-active-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetActiveNames request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetActiveNames"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the configured alarms. Specify an alarm name in your request to return information about a specific alarm, or specify a monitored resource name to return information about all alarms for a specific resource. An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see Alarms in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms).
#
# POST /
# Returns: record<alarms: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, supportCode: string, monitoredResourceInfo: record, comparisonOperator: string, evaluationPeriods: int, period: int, threshold: float, datapointsToAlarm: int, treatMissingData: string, statistic: string, metricName: string, state: string, unit: string, contactProtocols: list, notificationTriggers: list, notificationEnabled: bool>, nextPageToken: string>
# operationId: GetAlarms
export def "get-alarms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --alarm-name: string # The name of the alarm. Specify an alarm name to return information about a specific alarm.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetAlarms request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --monitored-resource-name: string # The name of the Lightsail resource being monitored by the alarm. Specify a monitored resource name to return information about all alarms for a specific resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetAlarms"}]
    body: {content_type: "application/json", kind: json, fields: [{name: alarmName, var: alarm_name}, {name: pageToken, var: page_token}, {name: monitoredResourceName, var: monitored_resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, alarm_name: $alarm_name, page_token: $page_token, monitored_resource_name: $monitored_resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the available automatic snapshots for an instance or disk. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-automatic-snapshots).
#
# POST /
# Returns: record<resourceName: string, resourceType: string, autoSnapshots: table<date: string, createdAt: string, status: string, fromAttachedDisks: list>>
# operationId: GetAutoSnapshots
export def "get-auto-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63 # required
  resource_name: string # The name of the source instance or disk from which to get automatic snapshot information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetAutoSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of available instance images, or blueprints. You can use a blueprint to create a new instance already running a specific operating system, as well as a preinstalled app or development stack. The software each instance is running depends on the blueprint image you choose. Use active blueprints when creating new instances. Inactive blueprints are listed to support customers with existing instances and are not necessarily available to create new instances. Blueprints are marked inactive when they become outdated due to operating system updates or new application releases.
#
# POST /
# Returns: record<blueprints: table<blueprintId: string, name: string, group: string, type: string, description: string, isActive: bool, minPower: int, version: string, versionCode: string, productUrl: string, licenseUrl: string, platform: string, appCategory: string>, nextPageToken: string>
# operationId: GetBlueprints
export def "get-blueprints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64 # required
  --include-inactive: oneof<nothing, bool> # A Boolean value that indicates whether to include inactive (unavailable) blueprints in the response of your request.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetBlueprints request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --app-category: string@app-category-completer # Returns a list of blueprints that are specific to Lightsail for Research. You must use this parameter to view Lightsail for Research blueprints.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBlueprints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: includeInactive, var: include_inactive}, {name: pageToken, var: page_token}, {name: appCategory, var: app_category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, include_inactive: $include_inactive, page_token: $page_token, app_category: $app_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the existing access key IDs for the specified Amazon Lightsail bucket. This action does not return the secret access key value of an access key. You can get a secret access key only when you create it from the response of the CreateBucketAccessKey (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_CreateBucketAccessKey.html) action. If you lose the secret access key, you must create a new access key.
#
# POST /
# Returns: record<accessKeys: table<accessKeyId: string, secretAccessKey: string, status: string, createdAt: string, lastUsed: record>>
# operationId: GetBucketAccessKeys
export def "get-bucket-access-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65 # required
  bucket_name: string # The name of the bucket for which to return access keys.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBucketAccessKeys"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bundles that you can apply to a Amazon Lightsail bucket. The bucket bundle specifies the monthly cost, storage quota, and data transfer quota for a bucket. Use the UpdateBucketBundle (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_UpdateBucketBundle.html) action to update the bundle for a bucket.
#
# POST /
# Returns: record<bundles: table<bundleId: string, name: string, price: float, storagePerMonthInGb: int, transferPerMonthInGb: int, isActive: bool>>
# operationId: GetBucketBundles
export def "get-bucket-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66 # required
  --include-inactive: oneof<nothing, bool> # A Boolean value that indicates whether to include inactive (unavailable) bundles in the response of your request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBucketBundles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: includeInactive, var: include_inactive}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, include_inactive: $include_inactive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the data points of a specific metric for an Amazon Lightsail bucket. Metrics report the utilization of a bucket. View and collect metric data regularly to monitor the number of objects stored in a bucket (including object versions) and the storage space used by those objects.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetBucketMetricData
export def "get-bucket-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67 # required
  bucket_name: string # The name of the bucket for which to get metric data.
  metric_name: string@metric-name-completer # The metric for which you want to return information. Valid bucket metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. These bucket metrics are reported once per day. BucketSizeBytes - The amount of data in bytes stored in a bucket. This value is calculated by summing the size of all objects in the bucket (including object versions), including the size of all parts for all incomplete multipart uploads to the bucket. Statistics: The most useful statistic is Maximum. Unit: The published unit is Bytes. NumberOfObjects - The total number of objects stored in a bucket. This value is calculated by counting all objects in the bucket (including object versions) and the total number of parts for all incomplete multipart uploads to the bucket. Statistics: The most useful statistic is Average. Unit: The published unit is Count.
  start_time: string # The timestamp indicating the earliest data to be returned. (format: date-time)
  end_time: string # The timestamp indicating the latest data to be returned. (format: date-time)
  period: int # The granularity, in seconds, of the returned data points. Bucket storage metrics are reported once per day. Therefore, you should specify a period of 86400 seconds, which is the number of seconds in a day.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - The sum of all values submitted for the matching metric. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
  unit: string@unit-completer # The unit for the metric data request. Valid units depend on the metric data being requested. For the valid units with each available metric, see the metricName parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBucketMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: metricName, var: metric_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: period, var: period}, {name: statistics, var: statistics}, {name: unit, var: unit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, metric_name: $metric_name, start_time: $start_time, end_time: $end_time, period: $period, statistics: $statistics, unit: $unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more Amazon Lightsail buckets. The information returned includes the synchronization status of the Amazon Simple Storage Service (Amazon S3) account-level block public access feature for your Lightsail buckets. For more information about buckets, see Buckets in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/buckets-in-amazon-lightsail) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<buckets: table<resourceType: string, accessRules: record, arn: string, bundleId: string, createdAt: string, url: string, location: record, name: string, supportCode: string, tags: list, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list, resourcesReceivingAccess: list, state: record, accessLogConfig: record>, nextPageToken: string, accountLevelBpaSync: record<status: string, lastSyncedAt: string, message: string, bpaImpactsLightsail: bool>>
# operationId: GetBuckets
export def "get-buckets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68 # required
  --bucket-name: string # The name of the bucket for which to return information. When omitted, the response includes all of your buckets in the Amazon Web Services Region where the request is made.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetBuckets request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --include-connected-resources: oneof<nothing, bool> # A Boolean value that indicates whether to include Lightsail instances that were given access to the bucket using the SetResourceAccessForBucket (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_SetResourceAccessForBucket.html) action.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBuckets"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: pageToken, var: page_token}, {name: includeConnectedResources, var: include_connected_resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, page_token: $page_token, include_connected_resources: $include_connected_resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bundles that you can apply to an Amazon Lightsail instance when you create it. A bundle describes the specifications of an instance, such as the monthly cost, amount of memory, the number of vCPUs, amount of storage space, and monthly network data transfer quota. Bundles are referred to as instance plans in the Lightsail console.
#
# POST /
# Returns: record<bundles: table<price: float, cpuCount: int, diskSizeInGb: int, bundleId: string, instanceType: string, isActive: bool, name: string, power: int, ramSizeInGb: float, transferPerMonthInGb: int, supportedPlatforms: list, supportedAppCategories: list>, nextPageToken: string>
# operationId: GetBundles
export def "get-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69 # required
  --include-inactive: oneof<nothing, bool> # A Boolean value that indicates whether to include inactive (unavailable) bundles in the response of your request.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetBundles request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --app-category: string@app-category-completer # Returns a list of bundles that are specific to Lightsail for Research. You must use this parameter to view Lightsail for Research bundles.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetBundles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: includeInactive, var: include_inactive}, {name: pageToken, var: page_token}, {name: appCategory, var: app_category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, include_inactive: $include_inactive, page_token: $page_token, app_category: $app_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more Amazon Lightsail SSL/TLS certificates. To get a summary of a certificate, ommit includeCertificateDetails from your request. The response will include only the certificate Amazon Resource Name (ARN), certificate name, domain name, and tags.
#
# POST /
# Returns: record<certificates: table<certificateArn: string, certificateName: string, domainName: string, certificateDetail: record, tags: list>>
# operationId: GetCertificates
export def "get-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70 # required
  --certificate-statuses: list<string> # The status of the certificates for which to return information. For example, specify ISSUED to return only certificates with an ISSUED status. When omitted, the response includes all of your certificates in the Amazon Web Services Region where the request is made, regardless of their current status.
  --include-certificate-details: oneof<nothing, bool> # Indicates whether to include detailed information about the certificates in the response. When omitted, the response includes only the certificate names, Amazon Resource Names (ARNs), domain names, and tags.
  --certificate-name: string # The name for the certificate for which to return information. When omitted, the response includes all of your certificates in the Amazon Web Services Region where the request is made.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetCertificates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateStatuses, var: certificate_statuses}, {name: includeCertificateDetails, var: include_certificate_details}, {name: certificateName, var: certificate_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, certificate_statuses: $certificate_statuses, include_certificate_details: $include_certificate_details, certificate_name: $certificate_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the CloudFormation stack record created as a result of the create cloud formation stack operation. An AWS CloudFormation stack is used to create a new Amazon EC2 instance from an exported Lightsail snapshot.
#
# POST /
# Returns: record<cloudFormationStackRecords: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, state: string, sourceInfo: list, destinationInfo: record>, nextPageToken: string>
# operationId: GetCloudFormationStackRecords
export def "get-cloud-formation-stack-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetClouFormationStackRecords request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetCloudFormationStackRecords"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the configured contact methods. Specify a protocol in your request to return information about a specific contact method. A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each Amazon Web Services Region. However, SMS text messaging is not supported in some Amazon Web Services Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see Notifications in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications).
#
# POST /
# Returns: record<contactMethods: table<contactEndpoint: string, status: string, protocol: string, name: string, arn: string, createdAt: string, location: record, resourceType: string, supportCode: string>>
# operationId: GetContactMethods
export def "get-contact-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72 # required
  --protocols: list<string> # The protocols used to send notifications, such as Email, or SMS (text messaging). Specify a protocol in your request to return information about a specific contact method protocol.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContactMethods"}]
    body: {content_type: "application/json", kind: json, fields: [{name: protocols, var: protocols}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, protocols: $protocols
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about Amazon Lightsail containers, such as the current version of the Lightsail Control (lightsailctl) plugin.
#
# POST /
# Returns: record<metadata: list<record>>
# operationId: GetContainerAPIMetadata
export def "get-container-api-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-73 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerAPIMetadata"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the container images that are registered to your Amazon Lightsail container service. If you created a deployment on your Lightsail container service that uses container images from a public registry like Docker Hub, those images are not returned as part of this action. Those images are not registered to your Lightsail container service.
#
# POST /
# Returns: record<containerImages: table<image: string, digest: string, createdAt: string>>
# operationId: GetContainerImages
export def "get-container-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-74 # required
  service_name: string # The name of the container service for which to return registered container images.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerImages"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the log events of a container of your Amazon Lightsail container service. If your container service has more than one node (i.e., a scale greater than 1), then the log events that are returned for the specified container are merged from all nodes on your container service. Container logs are retained for a certain amount of time. For more information, see Amazon Lightsail endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/lightsail.html) in the Amazon Web Services General Reference.
#
# POST /
# Returns: record<logEvents: table<createdAt: string, message: string>, nextPageToken: string>
# operationId: GetContainerLog
export def "get-container-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-75 # required
  service_name: string # The name of the container service for which to get a container log.
  container_name: string # The name of the container that is either running or previously ran on the container service for which to return a log.
  --start-time: string # The start of the time interval for which to get log data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a start time of October 1, 2018, at 8 PM UTC, specify 1538424000 as the start time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
  --end-time: string # The end of the time interval for which to get log data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use an end time of October 1, 2018, at 9 PM UTC, specify 1538427600 as the end time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
  --filter-pattern: string # The pattern to use to filter the returned log events to a specific term. The following are a few examples of filter patterns that you can specify: To return all log events, specify a filter pattern of "". To exclude log events that contain the ERROR term, and return all other log events, specify a filter pattern of "-ERROR". To return log events that contain the ERROR term, specify a filter pattern of "ERROR". To return log events that contain both the ERROR and Exception terms, specify a filter pattern of "ERROR Exception". To return log events that contain the ERROR or the Exception term, specify a filter pattern of "?ERROR ?Exception".
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetContainerLog request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerLog"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: containerName, var: container_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: filterPattern, var: filter_pattern}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, container_name: $container_name, start_time: $start_time, end_time: $end_time, filter_pattern: $filter_pattern, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the deployments for your Amazon Lightsail container service A deployment specifies the settings, such as the ports and launch command, of containers that are deployed to your container service. The deployments are ordered by version in ascending order. The newest version is listed at the top of the response. A set number of deployments are kept before the oldest one is replaced with the newest one. For more information, see Amazon Lightsail endpoints and quotas (https://docs.aws.amazon.com/general/latest/gr/lightsail.html) in the Amazon Web Services General Reference.
#
# POST /
# Returns: record<deployments: table<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>>
# operationId: GetContainerServiceDeployments
export def "get-container-service-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-76 # required
  service_name: string # The name of the container service for which to return deployments.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerServiceDeployments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the data points of a specific metric of your Amazon Lightsail container service. Metrics report the utilization of your resources. Monitor and collect metric data regularly to maintain the reliability, availability, and performance of your resources.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetContainerServiceMetricData
export def "get-container-service-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77 # required
  service_name: string # The name of the container service for which to get metric data.
  metric_name: string@metric-name-completer-1 # The metric for which you want to return information. Valid container service metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. CPUUtilization - The average percentage of compute units that are currently in use across all nodes of the container service. This metric identifies the processing power required to run containers on each node of the container service. Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Percent. MemoryUtilization - The average percentage of available memory that is currently in use across all nodes of the container service. This metric identifies the memory required to run containers on each node of the container service. Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Percent.
  start_time: string # The start time of the time period. (format: date-time)
  end_time: string # The end time of the time period. (format: date-time)
  period: int # The granularity, in seconds, of the returned data points. All container service metric data is available in 5-minute (300 seconds) granularity.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - All values submitted for the matching metric added together. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerServiceMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: metricName, var: metric_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: period, var: period}, {name: statistics, var: statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, metric_name: $metric_name, start_time: $start_time, end_time: $end_time, period: $period, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of powers that can be specified for your Amazon Lightsail container services. The power specifies the amount of memory, the number of vCPUs, and the base price of the container service.
#
# POST /
# Returns: record<powers: table<powerId: string, price: float, cpuCount: float, ramSizeInGb: float, name: string, isActive: bool>>
# operationId: GetContainerServicePowers
export def "get-container-service-powers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerServicePowers"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more of your Amazon Lightsail container services.
#
# POST /
# Returns: record<containerServices: table<containerServiceName: string, arn: string, createdAt: string, location: record, resourceType: string, tags: list, power: string, powerId: string, state: string, stateDetail: record, scale: int, currentDeployment: record, nextDeployment: record, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record>>
# operationId: GetContainerServices
export def "get-container-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79 # required
  --service-name: string # The name of the container service for which to return information. When omitted, the response includes all of your container services in the Amazon Web Services Region where the request is made.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetContainerServices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the cost estimate for a specified resource. A cost estimate will not generate for a resource that has been deleted.
#
# POST /
# Returns: record<resourcesBudgetEstimate: table<resourceName: string, resourceType: string, costEstimates: list, startTime: string, endTime: string>>
# operationId: GetCostEstimate
export def "get-cost-estimate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-80 # required
  resource_name: string # The resource name.
  start_time: string # The cost estimate start time. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a start time of October 1, 2018, at 8 PM UTC, specify 1538424000 as the start time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
  end_time: string # The cost estimate end time. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use an end time of October 1, 2018, at 9 PM UTC, specify 1538427600 as the end time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetCostEstimate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, start_time: $start_time, end_time: $end_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific block storage disk.
#
# POST /
# Returns: record<disk: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, addOns: list<record>, sizeInGb: int, isSystemDisk: bool, iops: int, path: string, state: string, attachedTo: string, isAttached: bool, attachmentState: string, gbInUse: int, autoMountStatus: string>>
# operationId: GetDisk
export def "get-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-81 # required
  disk_name: string # The name of the disk (e.g., my-disk).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDisk"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskName, var: disk_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_name: $disk_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific block storage disk snapshot.
#
# POST /
# Returns: record<diskSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, sizeInGb: int, state: string, progress: string, fromDiskName: string, fromDiskArn: string, fromInstanceName: string, fromInstanceArn: string, isFromAutoSnapshot: bool>>
# operationId: GetDiskSnapshot
export def "get-disk-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-82 # required
  disk_snapshot_name: string # The name of the disk snapshot (e.g., my-disk-snapshot).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDiskSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: diskSnapshotName, var: disk_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, disk_snapshot_name: $disk_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all block storage disk snapshots in your AWS account and region.
#
# POST /
# Returns: record<diskSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, sizeInGb: int, state: string, progress: string, fromDiskName: string, fromDiskArn: string, fromInstanceName: string, fromInstanceArn: string, isFromAutoSnapshot: bool>, nextPageToken: string>
# operationId: GetDiskSnapshots
export def "get-disk-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-83 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetDiskSnapshots request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDiskSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all block storage disks in your AWS account and region.
#
# POST /
# Returns: record<disks: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, addOns: list, sizeInGb: int, isSystemDisk: bool, iops: int, path: string, state: string, attachedTo: string, isAttached: bool, attachmentState: string, gbInUse: int, autoMountStatus: string>, nextPageToken: string>
# operationId: GetDisks
export def "get-disks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetDisks request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDisks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the bundles that can be applied to your Amazon Lightsail content delivery network (CDN) distributions. A distribution bundle specifies the monthly network transfer quota and monthly cost of your distribution.
#
# POST /
# Returns: record<bundles: table<bundleId: string, name: string, price: float, transferPerMonthInGb: int, isActive: bool>>
# operationId: GetDistributionBundles
export def "get-distribution-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-85 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDistributionBundles"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the timestamp and status of the last cache reset of a specific Amazon Lightsail content delivery network (CDN) distribution.
#
# POST /
# Returns: record<status: string, createTime: string>
# operationId: GetDistributionLatestCacheReset
export def "get-distribution-latest-cache-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-86 # required
  --distribution-name: string # The name of the distribution for which to return the timestamp of the last cache reset. Use the GetDistributions action to get a list of distribution names that you can specify. When omitted, the response includes the latest cache reset timestamp of all your distributions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDistributionLatestCacheReset"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the data points of a specific metric for an Amazon Lightsail content delivery network (CDN) distribution. Metrics report the utilization of your resources, and the error counts generated by them. Monitor and collect metric data regularly to maintain the reliability, availability, and performance of your resources.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetDistributionMetricData
export def "get-distribution-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87 # required
  distribution_name: string # The name of the distribution for which to get metric data. Use the GetDistributions action to get a list of distribution names that you can specify.
  metric_name: string@metric-name-completer-2 # The metric for which you want to return information. Valid distribution metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. Requests - The total number of viewer requests received by your Lightsail distribution, for all HTTP methods, and for both HTTP and HTTPS requests. Statistics: The most useful statistic is Sum. Unit: The published unit is None. BytesDownloaded - The number of bytes downloaded by viewers for GET, HEAD, and OPTIONS requests. Statistics: The most useful statistic is Sum. Unit: The published unit is None. BytesUploaded - The number of bytes uploaded to your origin by your Lightsail distribution, using POST and PUT requests. Statistics: The most useful statistic is Sum. Unit: The published unit is None. TotalErrorRate - The percentage of all viewer requests for which the response's HTTP status code was 4xx or 5xx. Statistics: The most useful statistic is Average. Unit: The published unit is Percent. 4xxErrorRate - The percentage of all viewer requests for which the response's HTTP status cod was 4xx. In these cases, the client or client viewer may have made an error. For example, a status code of 404 (Not Found) means that the client requested an object that could not be found. Statistics: The most useful statistic is Average. Unit: The published unit is Percent. 5xxErrorRate - The percentage of all viewer requests for which the response's HTTP status code was 5xx. In these cases, the origin server did not satisfy the requests. For example, a status code of 503 (Service Unavailable) means that the origin server is currently unavailable. Statistics: The most useful statistic is Average. Unit: The published unit is Percent.
  start_time: string # The start of the time interval for which to get metric data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a start time of October 1, 2018, at 8 PM UTC, specify 1538424000 as the start time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
  end_time: string # The end of the time interval for which to get metric data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use an end time of October 1, 2018, at 9 PM UTC, specify 1538427600 as the end time. You can convert a human-friendly time to Unix time format using a converter like Epoch converter (https://www.epochconverter.com/). (format: date-time)
  period: int # The granularity, in seconds, for the metric data points that will be returned.
  unit: string@unit-completer # The unit for the metric data request. Valid units depend on the metric data being requested. For the valid units with each available metric, see the metricName parameter.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - All values submitted for the matching metric added together. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDistributionMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: metricName, var: metric_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: period, var: period}, {name: unit, var: unit}, {name: statistics, var: statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, metric_name: $metric_name, start_time: $start_time, end_time: $end_time, period: $period, unit: $unit, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about one or more of your Amazon Lightsail content delivery network (CDN) distributions.
#
# POST /
# Returns: record<distributions: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, alternativeDomainNames: list, status: string, isEnabled: bool, domainName: string, bundleId: string, certificateName: string, origin: record, originPublicDNS: string, defaultCacheBehavior: record, cacheBehaviorSettings: record, cacheBehaviors: list, ableToUpdateBundle: bool, ipAddressType: string, tags: list>, nextPageToken: string>
# operationId: GetDistributions
export def "get-distributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-88 # required
  --distribution-name: string # The name of the distribution for which to return information. When omitted, the response includes all of your distributions in the Amazon Web Services Region where the request is made.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetDistributions request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDistributions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific domain recordset.
#
# POST /
# Returns: record<domain: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, domainEntries: list<record>, registeredDomainDelegationInfo: record<nameServersUpdateState: record, r53HostedZoneDeletionState: record>>>
# operationId: GetDomain
export def "get-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-89 # required
  domain_name: string # The domain name for which your want to return information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all domains in the user's account.
#
# POST /
# Returns: record<domains: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, domainEntries: list, registeredDomainDelegationInfo: record>, nextPageToken: string>
# operationId: GetDomains
export def "get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-90 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetDomains request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all export snapshot records created as a result of the export snapshot operation. An export snapshot record can be used to create a new Amazon EC2 instance and its related resources with the CreateCloudFormationStack (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_CreateCloudFormationStack.html) action.
#
# POST /
# Returns: record<exportSnapshotRecords: table<name: string, arn: string, createdAt: string, location: record, resourceType: string, state: string, sourceInfo: record, destinationInfo: record>, nextPageToken: string>
# operationId: GetExportSnapshotRecords
export def "get-export-snapshot-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-91 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetExportSnapshotRecords request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetExportSnapshotRecords"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific Amazon Lightsail instance, which is a virtual private server.
#
# POST /
# Returns: record<instance: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, blueprintId: string, blueprintName: string, bundleId: string, addOns: list<record>, isStaticIp: bool, privateIpAddress: string, publicIpAddress: string, ipv6Addresses: list<string>, ipAddressType: string, hardware: record<cpuCount: int, disks: list, ramSizeInGb: float>, networking: record<monthlyTransfer: record, ports: list>, state: record<code: int, name: string>, username: string, sshKeyName: string, metadataOptions: record<state: string, httpTokens: string, httpEndpoint: string, httpPutResponseHopLimit: int, httpProtocolIpv6: string>>>
# operationId: GetInstance
export def "get-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-92 # required
  instance_name: string # The name of the instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns temporary SSH keys you can use to connect to a specific virtual private server, or instance. The get instance access details operation supports tag-based access control via resource tags applied to the resource identified by instance name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<accessDetails: record<certKey: string, expiresAt: string, ipAddress: string, password: string, passwordData: record<ciphertext: string, keyPairName: string>, privateKey: string, protocol: string, instanceName: string, username: string, hostKeys: list<record>>>
# operationId: GetInstanceAccessDetails
export def "get-instance-access-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-93 # required
  instance_name: string # The name of the instance to access.
  --protocol: string@protocol-completer-1 # The protocol to use to connect to your instance. Defaults to ssh.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstanceAccessDetails"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: protocol, var: protocol}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the data points for the specified Amazon Lightsail instance metric, given an instance name. Metrics report the utilization of your resources, and the error counts generated by them. Monitor and collect metric data regularly to maintain the reliability, availability, and performance of your resources.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetInstanceMetricData
export def "get-instance-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-94 # required
  instance_name: string # The name of the instance for which you want to get metrics data.
  metric_name: string@metric-name-completer-3 # The metric for which you want to return information. Valid instance metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. BurstCapacityPercentage - The percentage of CPU performance available for your instance to burst above its baseline. Your instance continuously accrues and consumes burst capacity. Burst capacity stops accruing when your instance's BurstCapacityPercentage reaches 100%. For more information, see Viewing instance burst capacity in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-viewing-instance-burst-capacity). Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Percent. BurstCapacityTime - The available amount of time for your instance to burst at 100% CPU utilization. Your instance continuously accrues and consumes burst capacity. Burst capacity time stops accruing when your instance's BurstCapacityPercentage metric reaches 100%. Burst capacity time is consumed at the full rate only when your instance operates at 100% CPU utilization. For example, if your instance operates at 50% CPU utilization in the burstable zone for a 5-minute period, then it consumes CPU burst capacity minutes at a 50% rate in that period. Your instance consumed 2 minutes and 30 seconds of CPU burst capacity minutes in the 5-minute period. For more information, see Viewing instance burst capacity in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-viewing-instance-burst-capacity). Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Seconds. CPUUtilization - The percentage of allocated compute units that are currently in use on the instance. This metric identifies the processing power to run the applications on the instance. Tools in your operating system can show a lower percentage than Lightsail when the instance is not allocated a full processor core. Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Percent. NetworkIn - The number of bytes received on all network interfaces by the instance. This metric identifies the volume of incoming network traffic to the instance. The number reported is the number of bytes received during the period. Because this metric is reported in 5-minute intervals, divide the reported number by 300 to find Bytes/second. Statistics: The most useful statistic is Sum. Unit: The published unit is Bytes. NetworkOut - The number of bytes sent out on all network interfaces by the instance. This metric identifies the volume of outgoing network traffic from the instance. The number reported is the number of bytes sent during the period. Because this metric is reported in 5-minute intervals, divide the reported number by 300 to find Bytes/second. Statistics: The most useful statistic is Sum. Unit: The published unit is Bytes. StatusCheckFailed - Reports whether the instance passed or failed both the instance status check and the system status check. This metric can be either 0 (passed) or 1 (failed). This metric data is available in 1-minute (60 seconds) granularity. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. StatusCheckFailed_Instance - Reports whether the instance passed or failed the instance status check. This metric can be either 0 (passed) or 1 (failed). This metric data is available in 1-minute (60 seconds) granularity. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. StatusCheckFailed_System - Reports whether the instance passed or failed the system status check. This metric can be either 0 (passed) or 1 (failed). This metric data is available in 1-minute (60 seconds) granularity. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. MetadataNoToken - Reports the number of times that the instance metadata service was successfully accessed without a token. This metric determines if there are any processes accessing instance metadata by using Instance Metadata Service Version 1, which doesn't use a token. If all requests use token-backed sessions, such as Instance Metadata Service Version 2, then the value is 0. Statistics: The most useful statistic is Sum. Unit: The published unit is Count.
  period: int # The granularity, in seconds, of the returned data points. The StatusCheckFailed, StatusCheckFailed_Instance, and StatusCheckFailed_System instance metric data is available in 1-minute (60 seconds) granularity. All other instance metric data is available in 5-minute (300 seconds) granularity.
  start_time: string # The start time of the time period. (format: date-time)
  end_time: string # The end time of the time period. (format: date-time)
  unit: string@unit-completer # The unit for the metric data request. Valid units depend on the metric data being requested. For the valid units to specify with each available metric, see the metricName parameter.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - All values submitted for the matching metric added together. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstanceMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: metricName, var: metric_name}, {name: period, var: period}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: unit, var: unit}, {name: statistics, var: statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, metric_name: $metric_name, period: $period, start_time: $start_time, end_time: $end_time, unit: $unit, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the firewall port states for a specific Amazon Lightsail instance, the IP addresses allowed to connect to the instance through the ports, and the protocol.
#
# POST /
# Returns: record<portStates: table<fromPort: int, toPort: int, protocol: string, state: string, cidrs: list, ipv6Cidrs: list, cidrListAliases: list>>
# operationId: GetInstancePortStates
export def "get-instance-port-states" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-95 # required
  instance_name: string # The name of the instance for which to return firewall port states.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstancePortStates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific instance snapshot.
#
# POST /
# Returns: record<instanceSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, state: string, progress: string, fromAttachedDisks: list<record>, fromInstanceName: string, fromInstanceArn: string, fromBlueprintId: string, fromBundleId: string, isFromAutoSnapshot: bool, sizeInGb: int>>
# operationId: GetInstanceSnapshot
export def "get-instance-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-96 # required
  instance_snapshot_name: string # The name of the snapshot for which you are requesting information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstanceSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceSnapshotName, var: instance_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_snapshot_name: $instance_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all instance snapshots for the user's account.
#
# POST /
# Returns: record<instanceSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, state: string, progress: string, fromAttachedDisks: list, fromInstanceName: string, fromInstanceArn: string, fromBlueprintId: string, fromBundleId: string, isFromAutoSnapshot: bool, sizeInGb: int>, nextPageToken: string>
# operationId: GetInstanceSnapshots
export def "get-instance-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-97 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetInstanceSnapshots request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstanceSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the state of a specific instance. Works on one instance at a time.
#
# POST /
# Returns: record<state: record<code: int, name: string>>
# operationId: GetInstanceState
export def "get-instance-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-98 # required
  instance_name: string # The name of the instance to get state information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstanceState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all Amazon Lightsail virtual private servers, or instances.
#
# POST /
# Returns: record<instances: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, blueprintId: string, blueprintName: string, bundleId: string, addOns: list, isStaticIp: bool, privateIpAddress: string, publicIpAddress: string, ipv6Addresses: list, ipAddressType: string, hardware: record, networking: record, state: record, username: string, sshKeyName: string, metadataOptions: record>, nextPageToken: string>
# operationId: GetInstances
export def "get-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-99 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetInstances request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific key pair.
#
# POST /
# Returns: record<keyPair: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, fingerprint: string>>
# operationId: GetKeyPair
export def "get-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-100 # required
  key_pair_name: string # The name of the key pair for which you are requesting information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetKeyPair"}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyPairName, var: key_pair_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, key_pair_name: $key_pair_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all key pairs in the user's account.
#
# POST /
# Returns: record<keyPairs: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, fingerprint: string>, nextPageToken: string>
# operationId: GetKeyPairs
export def "get-key-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-101 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetKeyPairs request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --include-default-key-pair: oneof<nothing, bool> # A Boolean value that indicates whether to include the default key pair in the response of your request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetKeyPairs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}, {name: includeDefaultKeyPair, var: include_default_key_pair}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token, include_default_key_pair: $include_default_key_pair
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the specified Lightsail load balancer.
#
# POST /
# Returns: record<loadBalancer: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, dnsName: string, state: string, protocol: string, publicPorts: list<int>, healthCheckPath: string, instancePort: int, instanceHealthSummary: list<record>, tlsCertificateSummaries: list<record>, configurationOptions: record, ipAddressType: string, httpsRedirectionEnabled: bool, tlsPolicyName: string>>
# operationId: GetLoadBalancer
export def "get-load-balancer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-102 # required
  load_balancer_name: string # The name of the load balancer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetLoadBalancer"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about health metrics for your Lightsail load balancer. Metrics report the utilization of your resources, and the error counts generated by them. Monitor and collect metric data regularly to maintain the reliability, availability, and performance of your resources.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetLoadBalancerMetricData
export def "get-load-balancer-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-103 # required
  load_balancer_name: string # The name of the load balancer.
  metric_name: string@metric-name-completer-4 # The metric for which you want to return information. Valid load balancer metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. ClientTLSNegotiationErrorCount - The number of TLS connections initiated by the client that did not establish a session with the load balancer due to a TLS error generated by the load balancer. Possible causes include a mismatch of ciphers or protocols. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. HealthyHostCount - The number of target instances that are considered healthy. Statistics: The most useful statistic are Average, Minimum, and Maximum. Unit: The published unit is Count. HTTPCode_Instance_2XX_Count - The number of HTTP 2XX response codes generated by the target instances. This does not include any response codes generated by the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. HTTPCode_Instance_3XX_Count - The number of HTTP 3XX response codes generated by the target instances. This does not include any response codes generated by the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. HTTPCode_Instance_4XX_Count - The number of HTTP 4XX response codes generated by the target instances. This does not include any response codes generated by the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. HTTPCode_Instance_5XX_Count - The number of HTTP 5XX response codes generated by the target instances. This does not include any response codes generated by the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. HTTPCode_LB_4XX_Count - The number of HTTP 4XX client error codes that originated from the load balancer. Client errors are generated when requests are malformed or incomplete. These requests were not received by the target instance. This count does not include response codes generated by the target instances. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. HTTPCode_LB_5XX_Count - The number of HTTP 5XX server error codes that originated from the load balancer. This does not include any response codes generated by the target instance. This metric is reported if there are no healthy instances attached to the load balancer, or if the request rate exceeds the capacity of the instances (spillover) or the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. InstanceResponseTime - The time elapsed, in seconds, after the request leaves the load balancer until a response from the target instance is received. Statistics: The most useful statistic is Average. Unit: The published unit is Seconds. RejectedConnectionCount - The number of connections that were rejected because the load balancer had reached its maximum number of connections. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. RequestCount - The number of requests processed over IPv4. This count includes only the requests with a response generated by a target instance of the load balancer. Statistics: The most useful statistic is Sum. Note that Minimum, Maximum, and Average all return 1. Unit: The published unit is Count. UnhealthyHostCount - The number of target instances that are considered unhealthy. Statistics: The most useful statistic are Average, Minimum, and Maximum. Unit: The published unit is Count.
  period: int # The granularity, in seconds, of the returned data points.
  start_time: string # The start time of the period. (format: date-time)
  end_time: string # The end time of the period. (format: date-time)
  unit: string@unit-completer # The unit for the metric data request. Valid units depend on the metric data being requested. For the valid units with each available metric, see the metricName parameter.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - All values submitted for the matching metric added together. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetLoadBalancerMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: metricName, var: metric_name}, {name: period, var: period}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: unit, var: unit}, {name: statistics, var: statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, metric_name: $metric_name, period: $period, start_time: $start_time, end_time: $end_time, unit: $unit, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the TLS certificates that are associated with the specified Lightsail load balancer. TLS is just an updated, more secure version of Secure Socket Layer (SSL). You can have a maximum of 2 certificates associated with a Lightsail load balancer. One is active and the other is inactive.
#
# POST /
# Returns: record<tlsCertificates: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, loadBalancerName: string, isAttached: bool, status: string, domainName: string, domainValidationRecords: list, failureReason: string, issuedAt: string, issuer: string, keyAlgorithm: string, notAfter: string, notBefore: string, renewalSummary: record, revocationReason: string, revokedAt: string, serial: string, signatureAlgorithm: string, subject: string, subjectAlternativeNames: list>>
# operationId: GetLoadBalancerTlsCertificates
export def "get-load-balancer-tls-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-104 # required
  load_balancer_name: string # The name of the load balancer you associated with your SSL/TLS certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetLoadBalancerTlsCertificates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of TLS security policies that you can apply to Lightsail load balancers. For more information about load balancer TLS security policies, see Configuring TLS security policies on your Amazon Lightsail load balancers (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configure-load-balancer-tls-security-policy) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<tlsPolicies: table<name: string, isDefault: bool, description: string, protocols: list, ciphers: list>, nextPageToken: string>
# operationId: GetLoadBalancerTlsPolicies
export def "get-load-balancer-tls-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-105 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetLoadBalancerTlsPolicies request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetLoadBalancerTlsPolicies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all load balancers in an account.
#
# POST /
# Returns: record<loadBalancers: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, dnsName: string, state: string, protocol: string, publicPorts: list, healthCheckPath: string, instancePort: int, instanceHealthSummary: list, tlsCertificateSummaries: list, configurationOptions: record, ipAddressType: string, httpsRedirectionEnabled: bool, tlsPolicyName: string>, nextPageToken: string>
# operationId: GetLoadBalancers
export def "get-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-106 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetLoadBalancers request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetLoadBalancers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific operation. Operations include events such as when you create an instance, allocate a static IP, attach a static IP, and so on.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: GetOperation
export def "get-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-107 # required
  operation_id: string # A GUID used to identify the operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetOperation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: operationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all operations. Results are returned from oldest to newest, up to a maximum of 200. Results can be paged by making each subsequent call to GetOperations use the maximum (last) statusChangedAt value from the previous request.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>, nextPageToken: string>
# operationId: GetOperations
export def "get-operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-108 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetOperations request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetOperations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets operations for a specific resource (e.g., an instance or a static IP).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>, nextPageCount: string, nextPageToken: string>
# operationId: GetOperationsForResource
export def "get-operations-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-109 # required
  resource_name: string # The name of the resource for which you are requesting information.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetOperationsForResource request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetOperationsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all valid regions for Amazon Lightsail. Use the include availability zones parameter to also return the Availability Zones in a region.
#
# POST /
# Returns: record<regions: table<continentCode: string, description: string, displayName: string, name: string, availabilityZones: list, relationalDatabaseAvailabilityZones: list>>
# operationId: GetRegions
export def "get-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-110 # required
  --include-availability-zones: oneof<nothing, bool> # A Boolean value indicating whether to also include Availability Zones in your get regions request. Availability Zones are indicated with a letter: e.g., us-east-2a.
  --include-relational-database-availability-zones: oneof<nothing, bool> # A Boolean value indicating whether to also include Availability Zones for databases in your get regions request. Availability Zones are indicated with a letter (e.g., us-east-2a).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRegions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: includeAvailabilityZones, var: include_availability_zones}, {name: includeRelationalDatabaseAvailabilityZones, var: include_relational_database_availability_zones}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, include_availability_zones: $include_availability_zones, include_relational_database_availability_zones: $include_relational_database_availability_zones
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific database in Amazon Lightsail.
#
# POST /
# Returns: record<relationalDatabase: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, relationalDatabaseBlueprintId: string, relationalDatabaseBundleId: string, masterDatabaseName: string, hardware: record<cpuCount: int, diskSizeInGb: int, ramSizeInGb: float>, state: string, secondaryAvailabilityZone: string, backupRetentionEnabled: bool, pendingModifiedValues: record<masterUserPassword: string, engineVersion: string, backupRetentionEnabled: bool>, engine: string, engineVersion: string, latestRestorableTime: string, masterUsername: string, parameterApplyStatus: string, preferredBackupWindow: string, preferredMaintenanceWindow: string, publiclyAccessible: bool, masterEndpoint: record<port: int, address: string>, pendingMaintenanceActions: list<record>, caCertificateIdentifier: string>>
# operationId: GetRelationalDatabase
export def "get-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-111 # required
  relational_database_name: string # The name of the database that you are looking up.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available database blueprints in Amazon Lightsail. A blueprint describes the major engine version of a database. You can use a blueprint ID to create a new database that runs a specific database engine.
#
# POST /
# Returns: record<blueprints: table<blueprintId: string, engine: string, engineVersion: string, engineDescription: string, engineVersionDescription: string, isEngineDefault: bool>, nextPageToken: string>
# operationId: GetRelationalDatabaseBlueprints
export def "get-relational-database-blueprints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-112 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabaseBlueprints request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseBlueprints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of bundles that are available in Amazon Lightsail. A bundle describes the performance specifications for a database. You can use a bundle ID to create a new database with explicit performance specifications.
#
# POST /
# Returns: record<bundles: table<bundleId: string, name: string, price: float, ramSizeInGb: float, diskSizeInGb: int, transferPerMonthInGb: int, cpuCount: int, isEncrypted: bool, isActive: bool>, nextPageToken: string>
# operationId: GetRelationalDatabaseBundles
export def "get-relational-database-bundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-113 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabaseBundles request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
  --include-inactive: oneof<nothing, bool> # A Boolean value that indicates whether to include inactive (unavailable) bundles in the response of your request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseBundles"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}, {name: includeInactive, var: include_inactive}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token, include_inactive: $include_inactive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of events for a specific database in Amazon Lightsail.
#
# POST /
# Returns: record<relationalDatabaseEvents: table<resource: string, createdAt: string, message: string, eventCategories: list>, nextPageToken: string>
# operationId: GetRelationalDatabaseEvents
export def "get-relational-database-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-114 # required
  relational_database_name: string # The name of the database from which to get events.
  --duration-in-minutes: int # The number of minutes in the past from which to retrieve events. For example, to get all events from the past 2 hours, enter 120. Default: 60 The minimum is 1 and the maximum is 14 days (20160 minutes).
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabaseEvents request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: durationInMinutes, var: duration_in_minutes}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, duration_in_minutes: $duration_in_minutes, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of log events for a database in Amazon Lightsail.
#
# POST /
# Returns: record<resourceLogEvents: table<createdAt: string, message: string>, nextBackwardToken: string, nextForwardToken: string>
# operationId: GetRelationalDatabaseLogEvents
export def "get-relational-database-log-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-115 # required
  relational_database_name: string # The name of your database for which to get log events.
  log_stream_name: string # The name of the log stream. Use the get relational database log streams operation to get a list of available log streams.
  --start-time: string # The start of the time interval from which to get log events. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a start time of October 1, 2018, at 8 PM UTC, then you input 1538424000 as the start time. (format: date-time)
  --end-time: string # The end of the time interval from which to get log events. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use an end time of October 1, 2018, at 8 PM UTC, then you input 1538424000 as the end time. (format: date-time)
  --start-from-head: oneof<nothing, bool> # Parameter to specify if the log should start from head or tail. If true is specified, the log event starts from the head of the log. If false is specified, the log event starts from the tail of the log. For PostgreSQL, the default value of false is the only option available.
  --page-token: string # The token to advance to the next or previous page of results from your request. To get a page token, perform an initial GetRelationalDatabaseLogEvents request. If your results are paginated, the response will return a next forward token and/or next backward token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseLogEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: logStreamName, var: log_stream_name}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: startFromHead, var: start_from_head}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, log_stream_name: $log_stream_name, start_time: $start_time, end_time: $end_time, start_from_head: $start_from_head, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available log streams for a specific database in Amazon Lightsail.
#
# POST /
# Returns: record<logStreams: list<string>>
# operationId: GetRelationalDatabaseLogStreams
export def "get-relational-database-log-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-116 # required
  relational_database_name: string # The name of your database for which to get log streams.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseLogStreams"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current, previous, or pending versions of the master user password for a Lightsail database. The GetRelationalDatabaseMasterUserPassword operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName.
#
# POST /
# Returns: record<masterUserPassword: string, createdAt: string>
# operationId: GetRelationalDatabaseMasterUserPassword
export def "get-relational-database-master-user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-117 # required
  relational_database_name: string # The name of your database for which to get the master user password.
  --password-version: string@password-version-completer # The password version to return. Specifying CURRENT or PREVIOUS returns the current or previous passwords respectively. Specifying PENDING returns the newest version of the password that will rotate to CURRENT. After the PENDING password rotates to CURRENT, the PENDING password is no longer available. Default: CURRENT
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseMasterUserPassword"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: passwordVersion, var: password_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, password_version: $password_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the data points of the specified metric for a database in Amazon Lightsail. Metrics report the utilization of your resources, and the error counts generated by them. Monitor and collect metric data regularly to maintain the reliability, availability, and performance of your resources.
#
# POST /
# Returns: record<metricName: string, metricData: table<average: float, maximum: float, minimum: float, sampleCount: float, sum: float, timestamp: string, unit: string>>
# operationId: GetRelationalDatabaseMetricData
export def "get-relational-database-metric-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-118 # required
  relational_database_name: string # The name of your database from which to get metric data.
  metric_name: string@metric-name-completer-5 # The metric for which you want to return information. Valid relational database metric names are listed below, along with the most useful statistics to include in your request, and the published unit value. All relational database metric data is available in 1-minute (60 seconds) granularity. CPUUtilization - The percentage of CPU utilization currently in use on the database. Statistics: The most useful statistics are Maximum and Average. Unit: The published unit is Percent. DatabaseConnections - The number of database connections in use. Statistics: The most useful statistics are Maximum and Sum. Unit: The published unit is Count. DiskQueueDepth - The number of outstanding IOs (read/write requests) that are waiting to access the disk. Statistics: The most useful statistic is Sum. Unit: The published unit is Count. FreeStorageSpace - The amount of available storage space. Statistics: The most useful statistic is Sum. Unit: The published unit is Bytes. NetworkReceiveThroughput - The incoming (Receive) network traffic on the database, including both customer database traffic and AWS traffic used for monitoring and replication. Statistics: The most useful statistic is Average. Unit: The published unit is Bytes/Second. NetworkTransmitThroughput - The outgoing (Transmit) network traffic on the database, including both customer database traffic and AWS traffic used for monitoring and replication. Statistics: The most useful statistic is Average. Unit: The published unit is Bytes/Second.
  period: int # The granularity, in seconds, of the returned data points. All relational database metric data is available in 1-minute (60 seconds) granularity.
  start_time: string # The start of the time interval from which to get metric data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use a start time of October 1, 2018, at 8 PM UTC, then you input 1538424000 as the start time. (format: date-time)
  end_time: string # The end of the time interval from which to get metric data. Constraints: Specified in Coordinated Universal Time (UTC). Specified in the Unix time format. For example, if you wish to use an end time of October 1, 2018, at 8 PM UTC, then you input 1538424000 as the end time. (format: date-time)
  unit: string@unit-completer # The unit for the metric data request. Valid units depend on the metric data being requested. For the valid units with each available metric, see the metricName parameter.
  statistics: list<string> # The statistic for the metric. The following statistics are available: Minimum - The lowest value observed during the specified period. Use this value to determine low volumes of activity for your application. Maximum - The highest value observed during the specified period. Use this value to determine high volumes of activity for your application. Sum - All values submitted for the matching metric added together. You can use this statistic to determine the total volume of a metric. Average - The value of Sum / SampleCount during the specified period. By comparing this statistic with the Minimum and Maximum values, you can determine the full scope of a metric and how close the average use is to the Minimum and Maximum values. This comparison helps you to know when to increase or decrease your resources. SampleCount - The count, or number, of data points used for the statistical calculation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseMetricData"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: metricName, var: metric_name}, {name: period, var: period}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: unit, var: unit}, {name: statistics, var: statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, metric_name: $metric_name, period: $period, start_time: $start_time, end_time: $end_time, unit: $unit, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all of the runtime parameters offered by the underlying database software, or engine, for a specific database in Amazon Lightsail. In addition to the parameter names and values, this operation returns other information about each parameter. This information includes whether changes require a reboot, whether the parameter is modifiable, the allowed values, and the data types.
#
# POST /
# Returns: record<parameters: table<allowedValues: string, applyMethod: string, applyType: string, dataType: string, description: string, isModifiable: bool, parameterName: string, parameterValue: string>, nextPageToken: string>
# operationId: GetRelationalDatabaseParameters
export def "get-relational-database-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-119 # required
  relational_database_name: string # The name of your database for which to get parameters.
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabaseParameters request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific database snapshot in Amazon Lightsail.
#
# POST /
# Returns: record<relationalDatabaseSnapshot: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, engine: string, engineVersion: string, sizeInGb: int, state: string, fromRelationalDatabaseName: string, fromRelationalDatabaseArn: string, fromRelationalDatabaseBundleId: string, fromRelationalDatabaseBlueprintId: string>>
# operationId: GetRelationalDatabaseSnapshot
export def "get-relational-database-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-120 # required
  relational_database_snapshot_name: string # The name of the database snapshot for which to get information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseSnapshot"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseSnapshotName, var: relational_database_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_snapshot_name: $relational_database_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all of your database snapshots in Amazon Lightsail.
#
# POST /
# Returns: record<relationalDatabaseSnapshots: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, engine: string, engineVersion: string, sizeInGb: int, state: string, fromRelationalDatabaseName: string, fromRelationalDatabaseArn: string, fromRelationalDatabaseBundleId: string, fromRelationalDatabaseBlueprintId: string>, nextPageToken: string>
# operationId: GetRelationalDatabaseSnapshots
export def "get-relational-database-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-121 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabaseSnapshots request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabaseSnapshots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all of your databases in Amazon Lightsail.
#
# POST /
# Returns: record<relationalDatabases: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, tags: list, relationalDatabaseBlueprintId: string, relationalDatabaseBundleId: string, masterDatabaseName: string, hardware: record, state: string, secondaryAvailabilityZone: string, backupRetentionEnabled: bool, pendingModifiedValues: record, engine: string, engineVersion: string, latestRestorableTime: string, masterUsername: string, parameterApplyStatus: string, preferredBackupWindow: string, preferredMaintenanceWindow: string, publiclyAccessible: bool, masterEndpoint: record, pendingMaintenanceActions: list, caCertificateIdentifier: string>, nextPageToken: string>
# operationId: GetRelationalDatabases
export def "get-relational-databases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-122 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetRelationalDatabases request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetRelationalDatabases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about an Amazon Lightsail static IP.
#
# POST /
# Returns: record<staticIp: record<name: string, arn: string, supportCode: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, ipAddress: string, attachedTo: string, isAttached: bool>>
# operationId: GetStaticIp
export def "get-static-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-123 # required
  static_ip_name: string # The name of the static IP in Lightsail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetStaticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: staticIpName, var: static_ip_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, static_ip_name: $static_ip_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all static IPs in the user's account.
#
# POST /
# Returns: record<staticIps: table<name: string, arn: string, supportCode: string, createdAt: string, location: record, resourceType: string, ipAddress: string, attachedTo: string, isAttached: bool>, nextPageToken: string>
# operationId: GetStaticIps
export def "get-static-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-124 # required
  --page-token: string # The token to advance to the next page of results from your request. To get a page token, perform an initial GetStaticIps request. If your results are paginated, the response will return a next page token that you can specify as the page token in a subsequent request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.GetStaticIps"}]
    body: {content_type: "application/json", kind: json, fields: [{name: pageToken, var: page_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports a public SSH key from a specific key pair.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: ImportKeyPair
export def "import-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-125 # required
  key_pair_name: string # The name of the key pair for which you want to import the public key.
  public_key_base64: string # A base64-encoded public key of the ssh-rsa type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.ImportKeyPair"}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyPairName, var: key_pair_name}, {name: publicKeyBase64, var: public_key_base64}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, key_pair_name: $key_pair_name, public_key_base64: $public_key_base64
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a Boolean value indicating whether your Lightsail VPC is peered.
#
# POST /
# Returns: record<isPeered: bool>
# operationId: IsVpcPeered
export def "is-vpc-peered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-126 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.IsVpcPeered"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Opens ports for a specific Amazon Lightsail instance, and specifies the IP addresses allowed to connect to the instance through the ports, and the protocol. The OpenInstancePublicPorts action supports tag-based access control via resource tags applied to the resource identified by instanceName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: OpenInstancePublicPorts
export def "open-instance-public-ports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-127 # required
  port_info: record # Describes ports to open on an instance, the IP addresses allowed to connect to the instance through the ports, and the protocol. — shape: {fromPort?: int, toPort?: int, protocol?: "tcp"|"all"|"udp"|"icmp", cidrs?: list<string>, ipv6Cidrs?: list<string>, cidrListAliases?: list<string>}
  instance_name: string # The name of the instance for which to open ports.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.OpenInstancePublicPorts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: portInfo, var: port_info}, {name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, port_info: $port_info, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Peers the Lightsail VPC with the user's default VPC.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: PeerVpc
export def "peer-vpc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-128 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.PeerVpc"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an alarm, and associates it with the specified metric. An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see Alarms in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms). When this action creates an alarm, the alarm state is immediately set to INSUFFICIENT_DATA. The alarm is then evaluated and its state is set appropriately. Any actions associated with the new state are then executed. When you update an existing alarm, its state is left unchanged, but the update completely overwrites the previous configuration of the alarm. The alarm is then evaluated with the updated configuration.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: PutAlarm
export def "put-alarm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-129 # required
  alarm_name: string # The name for the alarm. Specify the name of an existing alarm to update, and overwrite the previous configuration of the alarm.
  metric_name: string@metric-name-completer-6 # The name of the metric to associate with the alarm. You can configure up to two alarms per metric. The following metrics are available for each resource type: Instances: BurstCapacityPercentage, BurstCapacityTime, CPUUtilization, NetworkIn, NetworkOut, StatusCheckFailed, StatusCheckFailed_Instance, and StatusCheckFailed_System. Load balancers: ClientTLSNegotiationErrorCount, HealthyHostCount, UnhealthyHostCount, HTTPCode_LB_4XX_Count, HTTPCode_LB_5XX_Count, HTTPCode_Instance_2XX_Count, HTTPCode_Instance_3XX_Count, HTTPCode_Instance_4XX_Count, HTTPCode_Instance_5XX_Count, InstanceResponseTime, RejectedConnectionCount, and RequestCount. Relational databases: CPUUtilization, DatabaseConnections, DiskQueueDepth, FreeStorageSpace, NetworkReceiveThroughput, and NetworkTransmitThroughput. For more information about these metrics, see Metrics available in Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-resource-health-metrics#available-metrics).
  monitored_resource_name: string # The name of the Lightsail resource that will be monitored. Instances, load balancers, and relational databases are the only Lightsail resources that can currently be monitored by alarms.
  comparison_operator: string@comparison-operator-completer # The arithmetic operation to use when comparing the specified statistic to the threshold. The specified statistic value is used as the first operand.
  threshold: float # The value against which the specified statistic is compared. (format: double)
  evaluation_periods: int # The number of most recent periods over which data is compared to the specified threshold. If you are setting an "M out of N" alarm, this value (evaluationPeriods) is the N. If you are setting an alarm that requires that a number of consecutive data points be breaching to trigger the alarm, this value specifies the rolling period of time in which data points are evaluated. Each evaluation period is five minutes long. For example, specify an evaluation period of 24 to evaluate a metric over a rolling period of two hours. You can specify a minimum valuation period of 1 (5 minutes), and a maximum evaluation period of 288 (24 hours).
  --datapoints-to-alarm: int # The number of data points that must be not within the specified threshold to trigger the alarm. If you are setting an "M out of N" alarm, this value (datapointsToAlarm) is the M.
  --treat-missing-data: string@treat-missing-data-completer # Sets how this alarm will handle missing data points. An alarm can treat missing data in the following ways: breaching - Assume the missing data is not within the threshold. Missing data counts towards the number of times the metric is not within the threshold. notBreaching - Assume the missing data is within the threshold. Missing data does not count towards the number of times the metric is not within the threshold. ignore - Ignore the missing data. Maintains the current alarm state. missing - Missing data is treated as missing. If treatMissingData is not specified, the default behavior of missing is used.
  --contact-protocols: list<string> # The contact protocols to use for the alarm, such as Email, SMS (text messaging), or both. A notification is sent via the specified contact protocol if notifications are enabled for the alarm, and when the alarm is triggered. A notification is not sent if a contact protocol is not specified, if the specified contact protocol is not configured in the Amazon Web Services Region, or if notifications are not enabled for the alarm using the notificationEnabled paramater. Use the CreateContactMethod action to configure a contact protocol in an Amazon Web Services Region.
  --notification-triggers: list<string> # The alarm states that trigger a notification. An alarm has the following possible states: ALARM - The metric is outside of the defined threshold. INSUFFICIENT_DATA - The alarm has just started, the metric is not available, or not enough data is available for the metric to determine the alarm state. OK - The metric is within the defined threshold. When you specify a notification trigger, the ALARM state must be specified. The INSUFFICIENT_DATA and OK states can be specified in addition to the ALARM state. If you specify OK as an alarm trigger, a notification is sent when the alarm switches from an ALARM or INSUFFICIENT_DATA alarm state to an OK state. This can be thought of as an all clear alarm notification. If you specify INSUFFICIENT_DATA as the alarm trigger, a notification is sent when the alarm switches from an OK or ALARM alarm state to an INSUFFICIENT_DATA state. The notification trigger defaults to ALARM if you don't specify this parameter.
  --notification-enabled: oneof<nothing, bool> # Indicates whether the alarm is enabled. Notifications are enabled by default if you don't specify this parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.PutAlarm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: alarmName, var: alarm_name}, {name: metricName, var: metric_name}, {name: monitoredResourceName, var: monitored_resource_name}, {name: comparisonOperator, var: comparison_operator}, {name: threshold, var: threshold}, {name: evaluationPeriods, var: evaluation_periods}, {name: datapointsToAlarm, var: datapoints_to_alarm}, {name: treatMissingData, var: treat_missing_data}, {name: contactProtocols, var: contact_protocols}, {name: notificationTriggers, var: notification_triggers}, {name: notificationEnabled, var: notification_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, alarm_name: $alarm_name, metric_name: $metric_name, monitored_resource_name: $monitored_resource_name, comparison_operator: $comparison_operator, threshold: $threshold, evaluation_periods: $evaluation_periods, datapoints_to_alarm: $datapoints_to_alarm, treat_missing_data: $treat_missing_data, contact_protocols: $contact_protocols, notification_triggers: $notification_triggers, notification_enabled: $notification_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Opens ports for a specific Amazon Lightsail instance, and specifies the IP addresses allowed to connect to the instance through the ports, and the protocol. This action also closes all currently open ports that are not included in the request. Include all of the ports and the protocols you want to open in your PutInstancePublicPortsrequest. Or use the OpenInstancePublicPorts action to open ports without closing currently open ports. The PutInstancePublicPorts action supports tag-based access control via resource tags applied to the resource identified by instanceName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: PutInstancePublicPorts
export def "put-instance-public-ports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-130 # required
  port_infos: list # An array of objects to describe the ports to open for the specified instance. — item shape: {fromPort?: int, toPort?: int, protocol?: "tcp"|"all"|"udp"|"icmp", cidrs?: list<string>, ipv6Cidrs?: list<string>, cidrListAliases?: list<string>}
  instance_name: string # The name of the instance for which to open ports.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.PutInstancePublicPorts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: portInfos, var: port_infos}, {name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, port_infos: $port_infos, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a specific instance. The reboot instance operation supports tag-based access control via resource tags applied to the resource identified by instance name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: RebootInstance
export def "reboot-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-131 # required
  instance_name: string # The name of the instance to reboot.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.RebootInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a specific database in Amazon Lightsail. The reboot relational database operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: RebootRelationalDatabase
export def "reboot-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-132 # required
  relational_database_name: string # The name of your database to reboot.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.RebootRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a container image to your Amazon Lightsail container service. This action is not required if you install and use the Lightsail Control (lightsailctl) plugin to push container images to your Lightsail container service. For more information, see Pushing and managing container images on your Amazon Lightsail container services (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-pushing-container-images) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<containerImage: record<image: string, digest: string, createdAt: string>>
# operationId: RegisterContainerImage
export def "register-container-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-133 # required
  service_name: string # The name of the container service for which to register a container image.
  label: string # The label for the container image when it's registered to the container service. Use a descriptive label that you can use to track the different versions of your registered container images. Use the GetContainerImages action to return the container images registered to a Lightsail container service. The label is the <imagelabel> portion of the following image name example: :container-service-1.<imagelabel>.1 If the name of your container service is mycontainerservice, and the label that you specify is mystaticwebsite, then the name of the registered container image will be :mycontainerservice.mystaticwebsite.1. The number at the end of these image name examples represents the version of the registered container image. If you push and register another container image to the same Lightsail container service, with the same label, then the version number for the new registered container image will be 2. If you push and register another container image, the version number will be 3, and so on.
  digest: string # The digest of the container image to be registered.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.RegisterContainerImage"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: label, var: label}, {name: digest, var: digest}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, label: $label, digest: $digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific static IP from your account.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: ReleaseStaticIp
export def "release-static-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-134 # required
  static_ip_name: string # The name of the static IP to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.ReleaseStaticIp"}]
    body: {content_type: "application/json", kind: json, fields: [{name: staticIpName, var: static_ip_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, static_ip_name: $static_ip_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes currently cached content from your Amazon Lightsail content delivery network (CDN) distribution. After resetting the cache, the next time a content request is made, your distribution pulls, serves, and caches it from the origin.
#
# POST /
# Returns: record<status: string, createTime: string, operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: ResetDistributionCache
export def "reset-distribution-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-135 # required
  --distribution-name: string # The name of the distribution for which to reset cache. Use the GetDistributions action to get a list of distribution names that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.ResetDistributionCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a verification request to an email contact method to ensure it's owned by the requester. SMS contact methods don't need to be verified. A contact method is used to send you notifications about your Amazon Lightsail resources. You can add one email address and one mobile phone number contact method in each Amazon Web Services Region. However, SMS text messaging is not supported in some Amazon Web Services Regions, and SMS text messages cannot be sent to some countries/regions. For more information, see Notifications in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-notifications). A verification request is sent to the contact method when you initially create it. Use this action to send another verification request if a previous verification request was deleted, or has expired. Notifications are not sent to an email contact method until after it is verified, and confirmed as valid.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: SendContactMethodVerification
export def "send-contact-method-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-136 # required
  protocol: string@protocol-completer-2 # The protocol to verify, such as Email or SMS (text messaging).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.SendContactMethodVerification"}]
    body: {content_type: "application/json", kind: json, fields: [{name: protocol, var: protocol}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the IP address type for an Amazon Lightsail resource. Use this action to enable dual-stack for a resource, which enables IPv4 and IPv6 for the specified resource. Alternately, you can use this action to disable dual-stack, and enable IPv4 only.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: SetIpAddressType
export def "set-ip-address-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-137 # required
  resource_type: string@resource-type-completer # The resource type. The possible values are Distribution, Instance, and LoadBalancer. Distribution-related APIs are available only in the N. Virginia (us-east-1) Amazon Web Services Region. Set your Amazon Web Services Region configuration to us-east-1 to create, view, or edit distributions.
  resource_name: string # The name of the resource for which to set the IP address type.
  ip_address_type: string@ip-address-type-completer # The IP address type to set for the specified resource. The possible values are ipv4 for IPv4 only, and dualstack for IPv4 and IPv6.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.SetIpAddressType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceType, var: resource_type}, {name: resourceName, var: resource_name}, {name: ipAddressType, var: ip_address_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_type: $resource_type, resource_name: $resource_name, ip_address_type: $ip_address_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the Amazon Lightsail resources that can access the specified Lightsail bucket. Lightsail buckets currently support setting access for Lightsail instances in the same Amazon Web Services Region.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: SetResourceAccessForBucket
export def "set-resource-access-for-bucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-138 # required
  resource_name: string # The name of the Lightsail instance for which to set bucket access. The instance must be in a running or stopped state.
  bucket_name: string # The name of the bucket for which to set access to another Lightsail resource.
  access: string@access-completer # The access setting. The following access settings are available: allow - Allows access to the bucket and its objects. deny - Denies access to the bucket and its objects. Use this setting to remove access for a resource previously set to allow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.SetResourceAccessForBucket"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: bucketName, var: bucket_name}, {name: access, var: access}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, bucket_name: $bucket_name, access: $access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a graphical user interface (GUI) session that’s used to access a virtual computer’s operating system and application. The session will be active for 1 hour. Use this action to resume the session after it expires.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StartGUISession
export def "start-gui-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-139 # required
  resource_name: string # The resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StartGUISession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a specific Amazon Lightsail instance from a stopped state. To restart an instance, use the reboot instance operation. When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/lightsail-create-static-ip). The start instance operation supports tag-based access control via resource tags applied to the resource identified by instance name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StartInstance
export def "start-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-140 # required
  instance_name: string # The name of the instance (a virtual private server) to start.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StartInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a specific database from a stopped state in Amazon Lightsail. To restart a database, use the reboot relational database operation. The start relational database operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StartRelationalDatabase
export def "start-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-141 # required
  relational_database_name: string # The name of your database to start.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StartRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates a web-based NICE DCV session that’s used to access a virtual computer’s operating system or application. The session will close and any unsaved data will be lost.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StopGUISession
export def "stop-gui-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-142 # required
  resource_name: string # The resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StopGUISession"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specific Amazon Lightsail instance that is currently running. When you start a stopped instance, Lightsail assigns a new public IP address to the instance. To use the same IP address after stopping and starting an instance, create a static IP address and attach it to the instance. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/lightsail-create-static-ip). The stop instance operation supports tag-based access control via resource tags applied to the resource identified by instance name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StopInstance
export def "stop-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-143 # required
  instance_name: string # The name of the instance (a virtual private server) to stop.
  --force: oneof<nothing, bool> # When set to True, forces a Lightsail instance that is stuck in a stopping state to stop. Only use the force parameter if your instance is stuck in the stopping state. In any other state, your instance should stop normally without adding this parameter to your API request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StopInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a specific database that is currently running in Amazon Lightsail. The stop relational database operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: StopRelationalDatabase
export def "stop-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-144 # required
  relational_database_name: string # The name of your database to stop.
  --relational-database-snapshot-name: string # The name of your new database snapshot to be created before stopping your database.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.StopRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: relationalDatabaseSnapshotName, var: relational_database_snapshot_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, relational_database_snapshot_name: $relational_database_snapshot_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to the specified Amazon Lightsail resource. Each resource can have a maximum of 50 tags. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-tags). The tag resource operation supports tag-based access control via request tags and resource tags applied to the resource identified by resource name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
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
  --x-amz-target: string@x-amz-target-completer-145 # required
  resource_name: string # The name of the resource to which you are adding tags.
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource to which you want to add a tag.
  tags: list # The tag key and optional value. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests an alarm by displaying a banner on the Amazon Lightsail console. If a notification trigger is configured for the specified alarm, the test also sends a notification to the notification protocol (Email and/or SMS) configured for the alarm. An alarm is used to monitor a single metric for one of your resources. When a metric condition is met, the alarm can notify you by email, SMS text message, and a banner displayed on the Amazon Lightsail console. For more information, see Alarms in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-alarms).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: TestAlarm
export def "test-alarm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-146 # required
  alarm_name: string # The name of the alarm to test.
  state: string@state-completer # The alarm state to test. An alarm has the following possible states that can be tested: ALARM - The metric is outside of the defined threshold. INSUFFICIENT_DATA - The alarm has just started, the metric is not available, or not enough data is available for the metric to determine the alarm state. OK - The metric is within the defined threshold.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.TestAlarm"}]
    body: {content_type: "application/json", kind: json, fields: [{name: alarmName, var: alarm_name}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, alarm_name: $alarm_name, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpeers the Lightsail VPC from the user's default VPC.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UnpeerVpc
export def "unpeer-vpc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-147 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UnpeerVpc"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified set of tag keys and their values from the specified Amazon Lightsail resource. The untag resource operation supports tag-based access control via request tags and resource tags applied to the resource identified by resource name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
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
  --x-amz-target: string@x-amz-target-completer-148 # required
  resource_name: string # The name of the resource from which you are removing a tag.
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource from which you want to remove a tag.
  tag_keys: list<string> # The tag keys to delete from the specified resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceName, var: resource_name}, {name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_name: $resource_name, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Amazon Lightsail bucket. Use this action to update the configuration of an existing bucket, such as versioning, public accessibility, and the Amazon Web Services accounts that can access the bucket.
#
# POST /
# Returns: record<bucket: record<resourceType: string, accessRules: record<getObject: string, allowPublicOverrides: bool>, arn: string, bundleId: string, createdAt: string, url: string, location: record<availabilityZone: string, regionName: string>, name: string, supportCode: string, tags: list<record>, objectVersioning: string, ableToUpdateBundle: bool, readonlyAccessAccounts: list<string>, resourcesReceivingAccess: list<record>, state: record<code: string, message: string>, accessLogConfig: record<enabled: bool, destination: string, prefix: string>>, operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateBucket
export def "update-bucket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-149 # required
  bucket_name: string # The name of the bucket to update.
  --access-rules: record # Describes the anonymous access permissions for an Amazon Lightsail bucket and its objects. For more information about bucket access permissions, see Understanding bucket permissions in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-understanding-bucket-permissions) in the Amazon Lightsail Developer Guide. — shape: {getObject?: "public"|"private", allowPublicOverrides?: bool}
  --versioning: string # Specifies whether to enable or suspend versioning of objects in the bucket. The following options can be specified: Enabled - Enables versioning of objects in the specified bucket. Suspended - Suspends versioning of objects in the specified bucket. Existing object versions are retained.
  --readonly-access-accounts: list<string> # An array of strings to specify the Amazon Web Services account IDs that can access the bucket. You can give a maximum of 10 Amazon Web Services accounts access to a bucket.
  --access-log-config: record # Describes the access log configuration for a bucket in the Amazon Lightsail object storage service. For more information about bucket access logs, see Logging bucket requests using access logging in Amazon Lightsail (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-bucket-access-logs) in the Amazon Lightsail Developer Guide. — shape: {enabled: bool, destination?: string, prefix?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateBucket"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: accessRules, var: access_rules}, {name: versioning, var: versioning}, {name: readonlyAccessAccounts, var: readonly_access_accounts}, {name: accessLogConfig, var: access_log_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, access_rules: $access_rules, versioning: $versioning, readonly_access_accounts: $readonly_access_accounts, access_log_config: $access_log_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the bundle, or storage plan, of an existing Amazon Lightsail bucket. A bucket bundle specifies the monthly cost, storage space, and data transfer quota for a bucket. You can update a bucket's bundle only one time within a monthly Amazon Web Services billing cycle. To determine if you can update a bucket's bundle, use the GetBuckets (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBuckets.html) action. The ableToUpdateBundle parameter in the response will indicate whether you can currently update a bucket's bundle. Update a bucket's bundle if it's consistently going over its storage space or data transfer quota, or if a bucket's usage is consistently in the lower range of its storage space or data transfer quota. Due to the unpredictable usage fluctuations that a bucket might experience, we strongly recommend that you update a bucket's bundle only as a long-term strategy, instead of as a short-term, monthly cost-cutting measure. Choose a bucket bundle that will provide the bucket with ample storage space and data transfer for a long time to come.
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateBucketBundle
export def "update-bucket-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-150 # required
  bucket_name: string # The name of the bucket for which to update the bundle.
  bundle_id: string # The ID of the new bundle to apply to the bucket. Use the GetBucketBundles (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetBucketBundles.html) action to get a list of bundle IDs that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateBucketBundle"}]
    body: {content_type: "application/json", kind: json, fields: [{name: bucketName, var: bucket_name}, {name: bundleId, var: bundle_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, bucket_name: $bucket_name, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of your Amazon Lightsail container service, such as its power, scale, and public domain names.
#
# POST /
# Returns: record<containerService: record<containerServiceName: string, arn: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, resourceType: string, tags: list<record>, power: string, powerId: string, state: string, stateDetail: record<code: string, message: string>, scale: int, currentDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, nextDeployment: record<version: int, state: string, containers: record, publicEndpoint: record, createdAt: string>, isDisabled: bool, principalArn: string, privateDomainName: string, publicDomainNames: record, url: string, privateRegistryAccess: record<ecrImagePullerRole: record>>>
# operationId: UpdateContainerService
export def "update-container-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-151 # required
  service_name: string # The name of the container service to update.
  --power: string@power-completer # The power for the container service. The power specifies the amount of memory, vCPUs, and base monthly cost of each node of the container service. The power and scale of a container service makes up its configured capacity. To determine the monthly price of your container service, multiply the base price of the power with the scale (the number of nodes) of the service. Use the GetContainerServicePowers action to view the specifications of each power option.
  --scale: int # The scale for the container service. The scale specifies the allocated compute nodes of the container service. The power and scale of a container service makes up its configured capacity. To determine the monthly price of your container service, multiply the base price of the power with the scale (the number of nodes) of the service.
  --is-disabled: oneof<nothing, bool> # A Boolean value to indicate whether the container service is disabled.
  --public-domain-names: record # The public domain names to use with the container service, such as example.com and www.example.com. You can specify up to four public domain names for a container service. The domain names that you specify are used when you create a deployment with a container configured as the public endpoint of your container service. If you don't specify public domain names, then you can use the default domain of the container service. You must create and validate an SSL/TLS certificate before you can use public domain names with your container service. Use the CreateCertificate action to create a certificate for the public domain names you want to use with your container service. You can specify public domain names using a string to array map as shown in the example later on this page.
  --private-registry-access: record # Describes a request to configure an Amazon Lightsail container service to access private container image repositories, such as Amazon Elastic Container Registry (Amazon ECR) private repositories. For more information, see Configuring access to an Amazon ECR private repository for an Amazon Lightsail container service (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-container-service-ecr-private-repo-access) in the Amazon Lightsail Developer Guide. — shape: {ecrImagePullerRole?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateContainerService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}, {name: power, var: power}, {name: scale, var: scale}, {name: isDisabled, var: is_disabled}, {name: publicDomainNames, var: public_domain_names}, {name: privateRegistryAccess, var: private_registry_access}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, power: $power, scale: $scale, is_disabled: $is_disabled, public_domain_names: $public_domain_names, private_registry_access: $private_registry_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Amazon Lightsail content delivery network (CDN) distribution. Use this action to update the configuration of your existing distribution.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateDistribution
export def "update-distribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-152 # required
  distribution_name: string # The name of the distribution to update. Use the GetDistributions action to get a list of distribution names that you can specify.
  --origin: record # Describes the origin resource of an Amazon Lightsail content delivery network (CDN) distribution. An origin can be a Lightsail instance, bucket, or load balancer. A distribution pulls content from an origin, caches it, and serves it to viewers via a worldwide network of edge servers. — shape: {name?: string, regionName?: "us-east-1"|"us-east-2"|"us-west-1"|"us-west-2"|"eu-west-1"|"eu-west-2"|"eu-west-3"|"eu-central-1"|"ca-central-1"|"ap-south-1"|"ap-southeast-1"|"ap-southeast-2"|"ap-northeast-1"|"ap-northeast-2"|"eu-north-1", protocolPolicy?: "http-only"|"https-only"}
  --default-cache-behavior: record # Describes the default cache behavior of an Amazon Lightsail content delivery network (CDN) distribution. — shape: {behavior?: "dont-cache"|"cache"}
  --cache-behavior-settings: record # Describes the cache settings of an Amazon Lightsail content delivery network (CDN) distribution. These settings apply only to your distribution's cacheBehaviors (including the defaultCacheBehavior) that have a behavior of cache. — shape: {defaultTTL?: int, minimumTTL?: int, maximumTTL?: int, allowedHTTPMethods?: string, cachedHTTPMethods?: string, forwardedCookies?: record, forwardedHeaders?: record, forwardedQueryStrings?: record}
  --cache-behaviors: list # An array of objects that describe the per-path cache behavior for the distribution. — item shape: {path?: string, behavior?: "dont-cache"|"cache"}
  --is-enabled: oneof<nothing, bool> # Indicates whether to enable the distribution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateDistribution"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: origin, var: origin}, {name: defaultCacheBehavior, var: default_cache_behavior}, {name: cacheBehaviorSettings, var: cache_behavior_settings}, {name: cacheBehaviors, var: cache_behaviors}, {name: isEnabled, var: is_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, origin: $origin, default_cache_behavior: $default_cache_behavior, cache_behavior_settings: $cache_behavior_settings, cache_behaviors: $cache_behaviors, is_enabled: $is_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the bundle of your Amazon Lightsail content delivery network (CDN) distribution. A distribution bundle specifies the monthly network transfer quota and monthly cost of your distribution. Update your distribution's bundle if your distribution is going over its monthly network transfer quota and is incurring an overage fee. You can update your distribution's bundle only one time within your monthly Amazon Web Services billing cycle. To determine if you can update your distribution's bundle, use the GetDistributions action. The ableToUpdateBundle parameter in the result will indicate whether you can currently update your distribution's bundle.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateDistributionBundle
export def "update-distribution-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-153 # required
  --distribution-name: string # The name of the distribution for which to update the bundle. Use the GetDistributions action to get a list of distribution names that you can specify.
  --bundle-id: string # The bundle ID of the new bundle to apply to your distribution. Use the GetDistributionBundles action to get a list of distribution bundle IDs that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateDistributionBundle"}]
    body: {content_type: "application/json", kind: json, fields: [{name: distributionName, var: distribution_name}, {name: bundleId, var: bundle_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, distribution_name: $distribution_name, bundle_id: $bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a domain recordset after it is created. The update domain entry operation supports tag-based access control via resource tags applied to the resource identified by domain name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateDomainEntry
export def "update-domain-entry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-154 # required
  domain_name: string # The name of the domain recordset to update.
  domain_entry: record # Describes a domain recordset entry. — shape: {id?: string, name?: string, target?: string, isAlias?: bool, type?: string, options?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateDomainEntry"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: domainEntry, var: domain_entry}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, domain_entry: $domain_entry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the Amazon Lightsail instance metadata parameters on a running or stopped instance. When you modify the parameters on a running instance, the GetInstance or GetInstances API operation initially responds with a state of pending. After the parameter modifications are successfully applied, the state changes to applied in subsequent GetInstance or GetInstances API calls. For more information, see Use IMDSv2 with an Amazon Lightsail instance (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-configuring-instance-metadata-service) in the Amazon Lightsail Developer Guide.
#
# POST /
# Returns: record<operation: record<id: string, resourceName: string, resourceType: string, createdAt: string, location: record<availabilityZone: string, regionName: string>, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateInstanceMetadataOptions
export def "update-instance-metadata-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-155 # required
  instance_name: string # The name of the instance for which to update metadata parameters.
  --http-tokens: string@http-tokens-completer # The state of token usage for your instance metadata requests. If the parameter is not specified in the request, the default state is optional. If the state is optional, you can choose whether to retrieve instance metadata with a signed token header on your request. If you retrieve the IAM role credentials without a token, the version 1.0 role credentials are returned. If you retrieve the IAM role credentials by using a valid signed token, the version 2.0 role credentials are returned. If the state is required, you must send a signed token header with all instance metadata retrieval requests. In this state, retrieving the IAM role credential always returns the version 2.0 credentials. The version 1.0 credentials are not available.
  --http-endpoint: string@http-endpoint-completer # Enables or disables the HTTP metadata endpoint on your instances. If this parameter is not specified, the existing state is maintained. If you specify a value of disabled, you cannot access your instance metadata.
  --http-put-response-hop-limit: int # The desired HTTP PUT response hop limit for instance metadata requests. A larger number means that the instance metadata requests can travel farther. If no parameter is specified, the existing state is maintained.
  --http-protocol-ipv6: string@http-protocol-ipv6-completer # Enables or disables the IPv6 endpoint for the instance metadata service. This setting applies only when the HTTP metadata endpoint is enabled. This parameter is available only for instances in the Europe (Stockholm) Amazon Web Services Region (eu-north-1).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateInstanceMetadataOptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceName, var: instance_name}, {name: httpTokens, var: http_tokens}, {name: httpEndpoint, var: http_endpoint}, {name: httpPutResponseHopLimit, var: http_put_response_hop_limit}, {name: httpProtocolIpv6, var: http_protocol_ipv6}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, instance_name: $instance_name, http_tokens: $http_tokens, http_endpoint: $http_endpoint, http_put_response_hop_limit: $http_put_response_hop_limit, http_protocol_ipv6: $http_protocol_ipv6
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attribute for a load balancer. You can only update one attribute at a time. The update load balancer attribute operation supports tag-based access control via resource tags applied to the resource identified by load balancer name. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateLoadBalancerAttribute
export def "update-load-balancer-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-156 # required
  load_balancer_name: string # The name of the load balancer that you want to modify (e.g., my-load-balancer.
  attribute_name: string@attribute-name-completer # The name of the attribute you want to update.
  attribute_value: string # The value that you want to specify for the attribute name. The following values are supported depending on what you specify for the attributeName request parameter: If you specify HealthCheckPath for the attributeName request parameter, then the attributeValue request parameter must be the path to ping on the target (for example, /weather/us/wa/seattle). If you specify SessionStickinessEnabled for the attributeName request parameter, then the attributeValue request parameter must be true to activate session stickiness or false to deactivate session stickiness. If you specify SessionStickiness_LB_CookieDurationSeconds for the attributeName request parameter, then the attributeValue request parameter must be an interger that represents the cookie duration in seconds. If you specify HttpsRedirectionEnabled for the attributeName request parameter, then the attributeValue request parameter must be true to activate HTTP to HTTPS redirection or false to deactivate HTTP to HTTPS redirection. If you specify TlsPolicyName for the attributeName request parameter, then the attributeValue request parameter must be the name of the TLS policy. Use the GetLoadBalancerTlsPolicies (https://docs.aws.amazon.com/lightsail/2016-11-28/api-reference/API_GetLoadBalancerTlsPolicies.html) action to get a list of TLS policy names that you can specify.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateLoadBalancerAttribute"}]
    body: {content_type: "application/json", kind: json, fields: [{name: loadBalancerName, var: load_balancer_name}, {name: attributeName, var: attribute_name}, {name: attributeValue, var: attribute_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, load_balancer_name: $load_balancer_name, attribute_name: $attribute_name, attribute_value: $attribute_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the update of one or more attributes of a database in Amazon Lightsail. Updates are applied immediately, or in cases where the updates could result in an outage, are applied during the database's predefined maintenance window. The update relational database operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateRelationalDatabase
export def "update-relational-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-157 # required
  relational_database_name: string # The name of your Lightsail database resource to update.
  --master-user-password: string # The password for the master user. The password can include any printable ASCII character except "/", """, or "@". MySQL Constraints: Must contain from 8 to 41 characters. PostgreSQL Constraints: Must contain from 8 to 128 characters. (format: password)
  --rotate-master-user-password: oneof<nothing, bool> # When true, the master user password is changed to a new strong password generated by Lightsail. Use the get relational database master user password operation to get the new password.
  --preferred-backup-window: string # The daily time range during which automated backups are created for your database if automated backups are enabled. Constraints: Must be in the hh24:mi-hh24:mi format. Example: 16:00-16:30 Specified in Coordinated Universal Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur on your database. The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Web Services Region, occurring on a random day of the week. Constraints: Must be in the ddd:hh24:mi-ddd:hh24:mi format. Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun. Must be at least 30 minutes. Specified in Coordinated Universal Time (UTC). Example: Tue:17:00-Tue:17:30
  --enable-backup-retention: oneof<nothing, bool> # When true, enables automated backup retention for your database. Updates are applied during the next maintenance window because this can result in an outage.
  --disable-backup-retention: oneof<nothing, bool> # When true, disables automated backup retention for your database. Disabling backup retention deletes all automated database backups. Before disabling this, you may want to create a snapshot of your database using the create relational database snapshot operation. Updates are applied during the next maintenance window because this can result in an outage.
  --publicly-accessible: oneof<nothing, bool> # Specifies the accessibility options for your database. A value of true specifies a database that is available to resources outside of your Lightsail account. A value of false specifies a database that is available only to your Lightsail resources in the same region as your database.
  --apply-immediately: oneof<nothing, bool> # When true, applies changes immediately. When false, applies changes during the preferred maintenance window. Some changes may cause an outage. Default: false
  --ca-certificate-identifier: string # Indicates the certificate that needs to be associated with the database.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateRelationalDatabase"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: masterUserPassword, var: master_user_password}, {name: rotateMasterUserPassword, var: rotate_master_user_password}, {name: preferredBackupWindow, var: preferred_backup_window}, {name: preferredMaintenanceWindow, var: preferred_maintenance_window}, {name: enableBackupRetention, var: enable_backup_retention}, {name: disableBackupRetention, var: disable_backup_retention}, {name: publiclyAccessible, var: publicly_accessible}, {name: applyImmediately, var: apply_immediately}, {name: caCertificateIdentifier, var: ca_certificate_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, master_user_password: $master_user_password, rotate_master_user_password: $rotate_master_user_password, preferred_backup_window: $preferred_backup_window, preferred_maintenance_window: $preferred_maintenance_window, enable_backup_retention: $enable_backup_retention, disable_backup_retention: $disable_backup_retention, publicly_accessible: $publicly_accessible, apply_immediately: $apply_immediately, ca_certificate_identifier: $ca_certificate_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the update of one or more parameters of a database in Amazon Lightsail. Parameter updates don't cause outages; therefore, their application is not subject to the preferred maintenance window. However, there are two ways in which parameter updates are applied: dynamic or pending-reboot. Parameters marked with a dynamic apply type are applied immediately. Parameters marked with a pending-reboot apply type are applied only after the database is rebooted using the reboot relational database operation. The update relational database parameters operation supports tag-based access control via resource tags applied to the resource identified by relationalDatabaseName. For more information, see the Amazon Lightsail Developer Guide (https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-controlling-access-using-tags).
#
# POST /
# Returns: record<operations: table<id: string, resourceName: string, resourceType: string, createdAt: string, location: record, isTerminal: bool, operationDetails: string, operationType: string, status: string, statusChangedAt: string, errorCode: string, errorDetails: string>>
# operationId: UpdateRelationalDatabaseParameters
export def "update-relational-database-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-158 # required
  relational_database_name: string # The name of your database for which to update parameters.
  parameters: list # The database parameters to update. — item shape: {allowedValues?: string, applyMethod?: string, applyType?: string, dataType?: string, description?: string, isModifiable?: bool, parameterName?: string, parameterValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Lightsail_20161128.UpdateRelationalDatabaseParameters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: relationalDatabaseName, var: relational_database_name}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, relational_database_name: $relational_database_name, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
