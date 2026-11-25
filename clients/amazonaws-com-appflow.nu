# Auto-generated client for Amazon Appflow v2020-08-23
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appflow/2020-08-23/openapi.json
# Auth: --token flag or $env.AMAZON_APPFLOW_TOKEN

const CLIENT = {
  base_url: "http://appflow.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_APPFLOW_TOKEN"
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

def base-url-completer [] { ["http://appflow.us-east-1.amazonaws.com" "http://appflow.us-east-2.amazonaws.com" "http://appflow.us-west-1.amazonaws.com" "http://appflow.us-west-2.amazonaws.com" "http://appflow.us-gov-west-1.amazonaws.com" "http://appflow.us-gov-east-1.amazonaws.com" "http://appflow.ca-central-1.amazonaws.com" "http://appflow.eu-north-1.amazonaws.com" "http://appflow.eu-west-1.amazonaws.com" "http://appflow.eu-west-2.amazonaws.com" "http://appflow.eu-west-3.amazonaws.com" "http://appflow.eu-central-1.amazonaws.com" "http://appflow.eu-south-1.amazonaws.com" "http://appflow.af-south-1.amazonaws.com" "http://appflow.ap-northeast-1.amazonaws.com" "http://appflow.ap-northeast-2.amazonaws.com" "http://appflow.ap-northeast-3.amazonaws.com" "http://appflow.ap-southeast-1.amazonaws.com" "http://appflow.ap-southeast-2.amazonaws.com" "http://appflow.ap-east-1.amazonaws.com" "http://appflow.ap-south-1.amazonaws.com" "http://appflow.sa-east-1.amazonaws.com" "http://appflow.me-south-1.amazonaws.com" "https://appflow.us-east-1.amazonaws.com" "https://appflow.us-east-2.amazonaws.com" "https://appflow.us-west-1.amazonaws.com" "https://appflow.us-west-2.amazonaws.com" "https://appflow.us-gov-west-1.amazonaws.com" "https://appflow.us-gov-east-1.amazonaws.com" "https://appflow.ca-central-1.amazonaws.com" "https://appflow.eu-north-1.amazonaws.com" "https://appflow.eu-west-1.amazonaws.com" "https://appflow.eu-west-2.amazonaws.com" "https://appflow.eu-west-3.amazonaws.com" "https://appflow.eu-central-1.amazonaws.com" "https://appflow.eu-south-1.amazonaws.com" "https://appflow.af-south-1.amazonaws.com" "https://appflow.ap-northeast-1.amazonaws.com" "https://appflow.ap-northeast-2.amazonaws.com" "https://appflow.ap-northeast-3.amazonaws.com" "https://appflow.ap-southeast-1.amazonaws.com" "https://appflow.ap-southeast-2.amazonaws.com" "https://appflow.ap-east-1.amazonaws.com" "https://appflow.ap-south-1.amazonaws.com" "https://appflow.sa-east-1.amazonaws.com" "https://appflow.me-south-1.amazonaws.com" "http://appflow.cn-north-1.amazonaws.com.cn" "http://appflow.cn-northwest-1.amazonaws.com.cn" "https://appflow.cn-north-1.amazonaws.com.cn" "https://appflow.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def connector-type-completer [] { ["Amplitude" "CustomConnector" "CustomerProfiles" "Datadog" "Dynatrace" "EventBridge" "Googleanalytics" "Honeycode" "Infornexus" "LookoutMetrics" "Marketo" "Pardot" "Redshift" "S3" "SAPOData" "Salesforce" "Servicenow" "Singular" "Slack" "Snowflake" "Trendmicro" "Upsolver" "Veeva" "Zendesk"] }
def connection-mode-completer [] { ["Private" "Public"] }
def connector-provisioning-type-completer [] { ["LAMBDA"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-connector-profile: "record<connectorProfileArn: string>"
    create-flow: "record<flowArn: string, flowStatus: string>"
    delete-connector-profile: "record"
    delete-flow: "record"
    describe-connector: "record<connectorConfiguration: record<canUseAsSource: bool, canUseAsDestination: bool, supportedDestinationConnectors: list<string>, supportedSchedulingFrequencies: list<string>, isPrivateLinkEnabled: bool, isPrivateLinkEndpointUrlRequired: bool, supportedTriggerTypes: list<string>, connectorMetadata: record<Amplitude: record, Datadog: record, Dynatrace: record, GoogleAnalytics: record, InforNexus: record, Marketo: record, Redshift: record, S3: record, Salesforce: record, ServiceNow: record, Singular: record, Slack: record, Snowflake: record, Trendmicro: record, Veeva: record, Zendesk: record, EventBridge: record, Upsolver: record, CustomerProfiles: record, Honeycode: record, SAPOData: record, Pardot: record>, connectorType: string, connectorLabel: string, connectorDescription: string, connectorOwner: string, connectorName: string, connectorVersion: string, connectorArn: string, connectorModes: list<string>, authenticationConfig: record<isBasicAuthSupported: bool, isApiKeyAuthSupported: bool, isOAuth2Supported: bool, isCustomAuthSupported: bool, oAuth2Defaults: record, customAuthConfigs: list>, connectorRuntimeSettings: list<record>, supportedApiVersions: list<string>, supportedOperators: list<string>, supportedWriteOperations: list<string>, connectorProvisioningType: string, connectorProvisioningConfig: record<lambda: record>, logoURL: string, registeredAt: string, registeredBy: string>>"
    describe-connector-entity: "record<connectorEntityFields: table<identifier: string, parentIdentifier: string, label: string, isPrimaryKey: bool, defaultValue: string, isDeprecated: bool, supportedFieldTypeDetails: record, description: string, sourceProperties: record, destinationProperties: record, customProperties: record>>"
    describe-connector-profiles: "record<connectorProfileDetails: table<connectorProfileArn: string, connectorProfileName: string, connectorType: string, connectorLabel: string, connectionMode: string, credentialsArn: string, connectorProfileProperties: record, createdAt: string, lastUpdatedAt: string, privateConnectionProvisioningState: record>, nextToken: string>"
    describe-connectors: "record<connectorConfigurations: record, connectors: table<connectorDescription: string, connectorName: string, connectorOwner: string, connectorVersion: string, applicationType: string, connectorType: string, connectorLabel: string, registeredAt: string, registeredBy: string, connectorProvisioningType: string, connectorModes: list>, nextToken: string>"
    describe-flow: "record<flowArn: string, description: string, flowName: string, kmsArn: string, flowStatus: string, flowStatusMessage: string, sourceFlowConfig: record<connectorType: string, apiVersion: string, connectorProfileName: string, sourceConnectorProperties: record<Amplitude: record, Datadog: record, Dynatrace: record, GoogleAnalytics: record, InforNexus: record, Marketo: record, S3: record, Salesforce: record, ServiceNow: record, Singular: record, Slack: record, Trendmicro: record, Veeva: record, Zendesk: record, SAPOData: record, CustomConnector: record, Pardot: record>, incrementalPullConfig: record<datetimeTypeFieldName: string>>, destinationFlowConfigList: table<connectorType: string, apiVersion: string, connectorProfileName: string, destinationConnectorProperties: record>, lastRunExecutionDetails: record<mostRecentExecutionMessage: string, mostRecentExecutionTime: string, mostRecentExecutionStatus: string>, triggerConfig: record<triggerType: string, triggerProperties: record<Scheduled: record>>, tasks: table<sourceFields: list, connectorOperator: record, destinationField: string, taskType: string, taskProperties: record>, createdAt: string, lastUpdatedAt: string, createdBy: string, lastUpdatedBy: string, tags: record, metadataCatalogConfig: record<glueDataCatalog: record<roleArn: string, databaseName: string, tablePrefix: string>>, lastRunMetadataCatalogDetails: table<catalogType: string, tableName: string, tableRegistrationOutput: record, partitionRegistrationOutput: record>, schemaVersion: int>"
    describe-flow-execution-records: "record<flowExecutions: table<executionId: string, executionStatus: string, executionResult: record, startedAt: string, lastUpdatedAt: string, dataPullStartTime: string, dataPullEndTime: string, metadataCatalogDetails: list>, nextToken: string>"
    list-connector-entities: "record<connectorEntityMap: record, nextToken: string>"
    list-connectors: "record<connectors: table<connectorDescription: string, connectorName: string, connectorOwner: string, connectorVersion: string, applicationType: string, connectorType: string, connectorLabel: string, registeredAt: string, registeredBy: string, connectorProvisioningType: string, connectorModes: list>, nextToken: string>"
    list-flows: "record<flows: table<flowArn: string, description: string, flowName: string, flowStatus: string, sourceConnectorType: string, sourceConnectorLabel: string, destinationConnectorType: string, destinationConnectorLabel: string, triggerType: string, createdAt: string, lastUpdatedAt: string, createdBy: string, lastUpdatedBy: string, tags: record, lastRunExecutionDetails: record>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    register-connector: "record<connectorArn: string>"
    start-flow: "record<flowArn: string, flowStatus: string, executionId: string>"
    stop-flow: "record<flowArn: string, flowStatus: string>"
    unregister-connector: "record"
    untag-resource: "record"
    update-connector-profile: "record<connectorProfileArn: string>"
    update-connector-registration: "record<connectorArn: string>"
    update-flow: "record<flowStatus: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-connector-profile" "create-flow" "delete-connector-profile" "delete-flow" "describe-connector" "describe-connector-entity" "describe-connector-profiles" "describe-connectors" "describe-flow" "describe-flow-execution-records" "list-connector-entities" "list-connectors" "list-flows" "list-tags-for-resource" "tag-resource" "register-connector" "start-flow" "stop-flow" "unregister-connector" "untag-resource" "update-connector-profile" "update-connector-registration" "update-flow" "commands"] | sort) } | get name | first)
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

# Creates a new connector profile associated with your Amazon Web Services account. There is a soft quota of 100 connector profiles per Amazon Web Services account. If you need more connector profiles than this quota allows, you can submit a request to the Amazon AppFlow team through the Amazon AppFlow support channel. In each connector profile that you create, you can provide the credentials and properties for only one connector.
#
# POST /create-connector-profile
# Returns: record<connectorProfileArn: string>
# operationId: CreateConnectorProfile
export def "create-connector-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_profile_name: string # The name of the connector profile. The name is unique for each ConnectorProfile in your Amazon Web Services account.
  --kms-arn: string # The ARN (Amazon Resource Name) of the Key Management Service (KMS) key you provide for encryption. This is required if you do not want to use the Amazon AppFlow-managed KMS key. If you don't provide anything here, Amazon AppFlow uses the Amazon AppFlow-managed KMS key.
  connector_type: string@connector-type-completer # The type of connector, such as Salesforce, Amplitude, and so on.
  --connector-label: string # The label of the connector. The label is unique for each ConnectorRegistration in your Amazon Web Services account. Only needed if calling for CUSTOMCONNECTOR connector type/.
  connection_mode: string@connection-mode-completer # Indicates the connection mode and specifies whether it is public or private. Private flows use Amazon Web Services PrivateLink to route data over Amazon Web Services infrastructure without exposing it to the public internet.
  connector_profile_config: record # Defines the connector-specific configuration and credentials for the connector profile. — shape: {connectorProfileProperties?: record, connectorProfileCredentials?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your CreateConnectorProfile request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to CreateConnectorProfile. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/create-connector-profile"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorProfileName, var: connector_profile_name}, {name: kmsArn, var: kms_arn}, {name: connectorType, var: connector_type}, {name: connectorLabel, var: connector_label}, {name: connectionMode, var: connection_mode}, {name: connectorProfileConfig, var: connector_profile_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_profile_name: $connector_profile_name, kms_arn: $kms_arn, connector_type: $connector_type, connector_label: $connector_label, connection_mode: $connection_mode, connector_profile_config: $connector_profile_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables your application to create a new flow using Amazon AppFlow. You must create a connector profile before calling this API. Please note that the Request Syntax below shows syntax for multiple destinations, however, you can only transfer data to one item in this list at a time. Amazon AppFlow does not currently support flows to multiple destinations at once.
#
# POST /create-flow
# Returns: record<flowArn: string, flowStatus: string>
# operationId: CreateFlow
export def "create-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
  --description: string # A description of the flow you want to create.
  --kms-arn: string # The ARN (Amazon Resource Name) of the Key Management Service (KMS) key you provide for encryption. This is required if you do not want to use the Amazon AppFlow-managed KMS key. If you don't provide anything here, Amazon AppFlow uses the Amazon AppFlow-managed KMS key.
  trigger_config: record # The trigger settings that determine how and when Amazon AppFlow runs the specified flow. — shape: {triggerType?: "Scheduled"|"Event"|"OnDemand", triggerProperties?: record}
  source_flow_config: record # Contains information about the configuration of the source connector used in the flow. — shape: {connectorType?: "Salesforce"|"Singular"|"Slack"|"Redshift"|"S3"|"Marketo"|"Googleanalytics"|"Zendesk"|"Servicenow"|"Datadog"|"Trendmicro"|"Snowflake"|"Dynatrace"|"Infornexus"|"Amplitude"|"Veeva"|"EventBridge"|"LookoutMetrics"|"Upsolver"|"Honeycode"|"CustomerProfiles"|"SAPOData"|"CustomConnector"|"Pardot", apiVersion?: string, connectorProfileName?: string, sourceConnectorProperties?: record, incrementalPullConfig?: record}
  destination_flow_config_list: list # The configuration that controls how Amazon AppFlow places data in the destination connector. — item shape: {connectorType: "Salesforce"|"Singular"|"Slack"|"Redshift"|"S3"|"Marketo"|"Googleanalytics"|"Zendesk"|"Servicenow"|"Datadog"|"Trendmicro"|"Snowflake"|"Dynatrace"|"Infornexus"|"Amplitude"|"Veeva"|"EventBridge"|"LookoutMetrics"|"Upsolver"|"Honeycode"|"CustomerProfiles"|"SAPOData"|"CustomConnector"|"Pardot", apiVersion?: string, connectorProfileName?: string, destinationConnectorProperties: record}
  tasks: list # A list of tasks that Amazon AppFlow performs while transferring the data in the flow run. — item shape: {sourceFields: list<string>, connectorOperator?: record, destinationField?: string, taskType: "Arithmetic"|"Filter"|"Map"|"Map_all"|"Mask"|"Merge"|"Passthrough"|"Truncate"|"Validate"|"Partition", taskProperties?: record}
  --tags: record # The tags used to organize, track, or control access for your flow.
  --metadata-catalog-config: record # Specifies the configuration that Amazon AppFlow uses when it catalogs your data. When Amazon AppFlow catalogs your data, it stores metadata in a data catalog. — shape: {glueDataCatalog?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your CreateFlow request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to CreateFlow. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/create-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}, {name: description, var: description}, {name: kmsArn, var: kms_arn}, {name: triggerConfig, var: trigger_config}, {name: sourceFlowConfig, var: source_flow_config}, {name: destinationFlowConfigList, var: destination_flow_config_list}, {name: tasks, var: tasks}, {name: tags, var: tags}, {name: metadataCatalogConfig, var: metadata_catalog_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name, description: $description, kms_arn: $kms_arn, trigger_config: $trigger_config, source_flow_config: $source_flow_config, destination_flow_config_list: $destination_flow_config_list, tasks: $tasks, tags: $tags, metadata_catalog_config: $metadata_catalog_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables you to delete an existing connector profile.
#
# POST /delete-connector-profile
# Returns: record
# operationId: DeleteConnectorProfile
export def "delete-connector-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_profile_name: string # The name of the connector profile. The name is unique for each ConnectorProfile in your account.
  --force-delete: oneof<nothing, bool> # Indicates whether Amazon AppFlow should delete the profile, even if it is currently in use in one or more flows.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/delete-connector-profile"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorProfileName, var: connector_profile_name}, {name: forceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_profile_name: $connector_profile_name, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables your application to delete an existing flow. Before deleting the flow, Amazon AppFlow validates the request by checking the flow configuration and status. You can delete flows one at a time.
#
# POST /delete-flow
# Returns: record
# operationId: DeleteFlow
export def "delete-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
  --force-delete: oneof<nothing, bool> # Indicates whether Amazon AppFlow should delete the flow, even if it is currently in use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/delete-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}, {name: forceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the given custom connector registered in your Amazon Web Services account. This API can be used for custom connectors that are registered in your account and also for Amazon authored connectors.
#
# POST /describe-connector
# Returns: record<connectorConfiguration: record<canUseAsSource: bool, canUseAsDestination: bool, supportedDestinationConnectors: list<string>, supportedSchedulingFrequencies: list<string>, isPrivateLinkEnabled: bool, isPrivateLinkEndpointUrlRequired: bool, supportedTriggerTypes: list<string>, connectorMetadata: record<Amplitude: record, Datadog: record, Dynatrace: record, GoogleAnalytics: record, InforNexus: record, Marketo: record, Redshift: record, S3: record, Salesforce: record, ServiceNow: record, Singular: record, Slack: record, Snowflake: record, Trendmicro: record, Veeva: record, Zendesk: record, EventBridge: record, Upsolver: record, CustomerProfiles: record, Honeycode: record, SAPOData: record, Pardot: record>, connectorType: string, connectorLabel: string, connectorDescription: string, connectorOwner: string, connectorName: string, connectorVersion: string, connectorArn: string, connectorModes: list<string>, authenticationConfig: record<isBasicAuthSupported: bool, isApiKeyAuthSupported: bool, isOAuth2Supported: bool, isCustomAuthSupported: bool, oAuth2Defaults: record, customAuthConfigs: list>, connectorRuntimeSettings: list<record>, supportedApiVersions: list<string>, supportedOperators: list<string>, supportedWriteOperations: list<string>, connectorProvisioningType: string, connectorProvisioningConfig: record<lambda: record>, logoURL: string, registeredAt: string, registeredBy: string>>
# operationId: DescribeConnector
export def "describe-connector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_type: string@connector-type-completer # The connector type, such as CUSTOMCONNECTOR, Saleforce, Marketo. Please choose CUSTOMCONNECTOR for Lambda based custom connectors.
  --connector-label: string # The label of the connector. The label is unique for each ConnectorRegistration in your Amazon Web Services account. Only needed if calling for CUSTOMCONNECTOR connector type/.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-connector"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorType, var: connector_type}, {name: connectorLabel, var: connector_label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_type: $connector_type, connector_label: $connector_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details regarding the entity used with the connector, with a description of the data model for each field in that entity.
#
# POST /describe-connector-entity
# Returns: record<connectorEntityFields: table<identifier: string, parentIdentifier: string, label: string, isPrimaryKey: bool, defaultValue: string, isDeprecated: bool, supportedFieldTypeDetails: record, description: string, sourceProperties: record, destinationProperties: record, customProperties: record>>
# operationId: DescribeConnectorEntity
export def "describe-connector-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_entity_name: string # The entity name for that connector.
  --connector-type: string@connector-type-completer # The type of connector application, such as Salesforce, Amplitude, and so on.
  --connector-profile-name: string # The name of the connector profile. The name is unique for each ConnectorProfile in the Amazon Web Services account.
  --api-version: string # The version of the API that's used by the connector.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-connector-entity"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorEntityName, var: connector_entity_name}, {name: connectorType, var: connector_type}, {name: connectorProfileName, var: connector_profile_name}, {name: apiVersion, var: api_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_entity_name: $connector_entity_name, connector_type: $connector_type, connector_profile_name: $connector_profile_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of connector-profile details matching the provided connector-profile names and connector-types. Both input lists are optional, and you can use them to filter the result. If no names or connector-types are provided, returns all connector profiles in a paginated form. If there is no match, this operation returns an empty list.
#
# POST /describe-connector-profiles
# Returns: record<connectorProfileDetails: table<connectorProfileArn: string, connectorProfileName: string, connectorType: string, connectorLabel: string, connectionMode: string, credentialsArn: string, connectorProfileProperties: record, createdAt: string, lastUpdatedAt: string, privateConnectionProvisioningState: record>, nextToken: string>
# operationId: DescribeConnectorProfiles
export def "describe-connector-profiles" [
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
  --connector-profile-names: list<string> # The name of the connector profile. The name is unique for each ConnectorProfile in the Amazon Web Services account.
  --connector-type: string@connector-type-completer # The type of connector, such as Salesforce, Amplitude, and so on.
  --connector-label: string # The name of the connector. The name is unique for each ConnectorRegistration in your Amazon Web Services account. Only needed if calling for CUSTOMCONNECTOR connector type/.
  --body-max-results: int # Specifies the maximum number of items that should be returned in the result set. The default for maxResults is 20 (for all paginated API operations). (spec name: maxResults)
  --body-next-token: string # The pagination token for the next page of data. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-connector-profiles"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorProfileNames, var: connector_profile_names}, {name: connectorType, var: connector_type}, {name: connectorLabel, var: connector_label}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_profile_names: $connector_profile_names, connector_type: $connector_type, connector_label: $connector_label, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the connectors vended by Amazon AppFlow for specified connector types. If you don't specify a connector type, this operation describes all connectors vended by Amazon AppFlow. If there are more connectors than can be returned in one page, the response contains a nextToken object, which can be be passed in to the next call to the DescribeConnectors API operation to retrieve the next page.
#
# POST /describe-connectors
# Returns: record<connectorConfigurations: record, connectors: table<connectorDescription: string, connectorName: string, connectorOwner: string, connectorVersion: string, applicationType: string, connectorType: string, connectorLabel: string, registeredAt: string, registeredBy: string, connectorProvisioningType: string, connectorModes: list>, nextToken: string>
# operationId: DescribeConnectors
export def "describe-connectors" [
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
  --connector-types: list<string> # The type of connector, such as Salesforce, Amplitude, and so on.
  --body-max-results: int # The maximum number of items that should be returned in the result set. The default is 20. (spec name: maxResults)
  --body-next-token: string # The pagination token for the next page of data. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-connectors"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorTypes, var: connector_types}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_types: $connector_types, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a description of the specified flow.
#
# POST /describe-flow
# Returns: record<flowArn: string, description: string, flowName: string, kmsArn: string, flowStatus: string, flowStatusMessage: string, sourceFlowConfig: record<connectorType: string, apiVersion: string, connectorProfileName: string, sourceConnectorProperties: record<Amplitude: record, Datadog: record, Dynatrace: record, GoogleAnalytics: record, InforNexus: record, Marketo: record, S3: record, Salesforce: record, ServiceNow: record, Singular: record, Slack: record, Trendmicro: record, Veeva: record, Zendesk: record, SAPOData: record, CustomConnector: record, Pardot: record>, incrementalPullConfig: record<datetimeTypeFieldName: string>>, destinationFlowConfigList: table<connectorType: string, apiVersion: string, connectorProfileName: string, destinationConnectorProperties: record>, lastRunExecutionDetails: record<mostRecentExecutionMessage: string, mostRecentExecutionTime: string, mostRecentExecutionStatus: string>, triggerConfig: record<triggerType: string, triggerProperties: record<Scheduled: record>>, tasks: table<sourceFields: list, connectorOperator: record, destinationField: string, taskType: string, taskProperties: record>, createdAt: string, lastUpdatedAt: string, createdBy: string, lastUpdatedBy: string, tags: record, metadataCatalogConfig: record<glueDataCatalog: record<roleArn: string, databaseName: string, tablePrefix: string>>, lastRunMetadataCatalogDetails: table<catalogType: string, tableName: string, tableRegistrationOutput: record, partitionRegistrationOutput: record>, schemaVersion: int>
# operationId: DescribeFlow
export def "describe-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches the execution history of the flow.
#
# POST /describe-flow-execution-records
# Returns: record<flowExecutions: table<executionId: string, executionStatus: string, executionResult: record, startedAt: string, lastUpdatedAt: string, dataPullStartTime: string, dataPullEndTime: string, metadataCatalogDetails: list>, nextToken: string>
# operationId: DescribeFlowExecutionRecords
export def "describe-flow-execution-records" [
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
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
  --body-max-results: int # Specifies the maximum number of items that should be returned in the result set. The default for maxResults is 20 (for all paginated API operations). (spec name: maxResults)
  --body-next-token: string # The pagination token for the next page of data. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/describe-flow-execution-records"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of available connector entities supported by Amazon AppFlow. For example, you can query Salesforce for Account and Opportunity entities, or query ServiceNow for the Incident entity.
#
# POST /list-connector-entities
# Returns: record<connectorEntityMap: record, nextToken: string>
# operationId: ListConnectorEntities
export def "list-connector-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connector-profile-name: string # The name of the connector profile. The name is unique for each ConnectorProfile in the Amazon Web Services account, and is used to query the downstream connector.
  --connector-type: string@connector-type-completer # The type of connector, such as Salesforce, Amplitude, and so on.
  --entities-path: string # This optional parameter is specific to connector implementation. Some connectors support multiple levels or categories of entities. You can find out the list of roots for such providers by sending a request without the entitiesPath parameter. If the connector supports entities at different roots, this initial request returns the list of roots. Otherwise, this request returns all entities supported by the provider.
  --api-version: string # The version of the API that's used by the connector.
  --max-results: int # The maximum number of items that the operation returns in the response.
  --next-token: string # A token that was provided by your prior ListConnectorEntities operation if the response was too big for the page size. You specify this token to get the next page of results in paginated response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/list-connector-entities"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorProfileName, var: connector_profile_name}, {name: connectorType, var: connector_type}, {name: entitiesPath, var: entities_path}, {name: apiVersion, var: api_version}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_profile_name: $connector_profile_name, connector_type: $connector_type, entities_path: $entities_path, api_version: $api_version, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of all registered custom connectors in your Amazon Web Services account. This API lists only custom connectors registered in this account, not the Amazon Web Services authored connectors.
#
# POST /list-connectors
# Returns: record<connectors: table<connectorDescription: string, connectorName: string, connectorOwner: string, connectorVersion: string, applicationType: string, connectorType: string, connectorLabel: string, registeredAt: string, registeredBy: string, connectorProvisioningType: string, connectorModes: list>, nextToken: string>
# operationId: ListConnectors
export def "list-connectors" [
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
  --body-max-results: int # Specifies the maximum number of items that should be returned in the result set. The default for maxResults is 20 (for all paginated API operations). (spec name: maxResults)
  --body-next-token: string # The pagination token for the next page of data. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/list-connectors"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the flows associated with your account.
#
# POST /list-flows
# Returns: record<flows: table<flowArn: string, description: string, flowName: string, flowStatus: string, sourceConnectorType: string, sourceConnectorLabel: string, destinationConnectorType: string, destinationConnectorLabel: string, triggerType: string, createdAt: string, lastUpdatedAt: string, createdBy: string, lastUpdatedBy: string, tags: record, lastRunExecutionDetails: record>, nextToken: string>
# operationId: ListFlows
export def "list-flows" [
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
  --body-max-results: int # Specifies the maximum number of items that should be returned in the result set. (spec name: maxResults)
  --body-next-token: string # The pagination token for next page of data. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/list-flows"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the tags that are associated with a specified flow.
#
# GET /tags/{resourceArn}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a tag to the specified flow.
#
# POST /tags/{resourceArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # The tags used to organize, track, or control access for your flow.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a new custom connector with your Amazon Web Services account. Before you can register the connector, you must deploy the associated AWS lambda function in your account.
#
# POST /register-connector
# Returns: record<connectorArn: string>
# operationId: RegisterConnector
export def "register-connector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --connector-label: string # The name of the connector. The name is unique for each ConnectorRegistration in your Amazon Web Services account.
  --description: string # A description about the connector that's being registered.
  --connector-provisioning-type: string@connector-provisioning-type-completer # The type of provisioning that the connector supports, such as Lambda.
  --connector-provisioning-config: record # Contains information about the configuration of the connector being registered. — shape: {lambda?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your RegisterConnector request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to RegisterConnector. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/register-connector"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorLabel, var: connector_label}, {name: description, var: description}, {name: connectorProvisioningType, var: connector_provisioning_type}, {name: connectorProvisioningConfig, var: connector_provisioning_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_label: $connector_label, description: $description, connector_provisioning_type: $connector_provisioning_type, connector_provisioning_config: $connector_provisioning_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates an existing flow. For on-demand flows, this operation runs the flow immediately. For schedule and event-triggered flows, this operation activates the flow.
#
# POST /start-flow
# Returns: record<flowArn: string, flowStatus: string, executionId: string>
# operationId: StartFlow
export def "start-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your StartFlow request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs for flows that run on a schedule or based on an event. However, the error doesn't occur for flows that run on demand. You set the conditions that initiate your flow for the triggerConfig parameter. If you use a different value for clientToken, Amazon AppFlow considers it a new call to StartFlow. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/start-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates the existing flow. For on-demand flows, this operation returns an unsupportedOperationException error message. For schedule and event-triggered flows, this operation deactivates the flow.
#
# POST /stop-flow
# Returns: record<flowArn: string, flowStatus: string>
# operationId: StopFlow
export def "stop-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stop-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregisters the custom connector registered in your account that matches the connector label provided in the request.
#
# POST /unregister-connector
# Returns: record
# operationId: UnregisterConnector
export def "unregister-connector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_label: string # The label of the connector. The label is unique for each ConnectorRegistration in your Amazon Web Services account.
  --force-delete: oneof<nothing, bool> # Indicates whether Amazon AppFlow should unregister the connector, even if it is currently in use in one or more connector profiles. The default value is false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/unregister-connector"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorLabel, var: connector_label}, {name: forceDelete, var: force_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_label: $connector_label, force_delete: $force_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag from the specified flow.
#
# DELETE /tags/{resourceArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The tag keys associated with the tag that you want to remove from your flow. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a given connector profile associated with your account.
#
# POST /update-connector-profile
# Returns: record<connectorProfileArn: string>
# operationId: UpdateConnectorProfile
export def "update-connector-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_profile_name: string # The name of the connector profile and is unique for each ConnectorProfile in the Amazon Web Services account.
  connection_mode: string@connection-mode-completer # Indicates the connection mode and if it is public or private.
  connector_profile_config: record # Defines the connector-specific configuration and credentials for the connector profile. — shape: {connectorProfileProperties?: record, connectorProfileCredentials?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your UpdateConnectorProfile request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to UpdateConnectorProfile. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/update-connector-profile"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorProfileName, var: connector_profile_name}, {name: connectionMode, var: connection_mode}, {name: connectorProfileConfig, var: connector_profile_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_profile_name: $connector_profile_name, connection_mode: $connection_mode, connector_profile_config: $connector_profile_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a custom connector that you've previously registered. This operation updates the connector with one of the following: The latest version of the AWS Lambda function that's assigned to the connector A new AWS Lambda function that you specify
#
# POST /update-connector-registration
# Returns: record<connectorArn: string>
# operationId: UpdateConnectorRegistration
export def "update-connector-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  connector_label: string # The name of the connector. The name is unique for each connector registration in your AWS account.
  --description: string # A description about the update that you're applying to the connector.
  --connector-provisioning-config: record # Contains information about the configuration of the connector being registered. — shape: {lambda?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your UpdateConnectorRegistration request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to UpdateConnectorRegistration. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/update-connector-registration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectorLabel, var: connector_label}, {name: description, var: description}, {name: connectorProvisioningConfig, var: connector_provisioning_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connector_label: $connector_label, description: $description, connector_provisioning_config: $connector_provisioning_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing flow.
#
# POST /update-flow
# Returns: record<flowStatus: string>
# operationId: UpdateFlow
export def "update-flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  flow_name: string # The specified name of the flow. Spaces are not allowed. Use underscores (_) or hyphens (-) only.
  --description: string # A description of the flow.
  trigger_config: record # The trigger settings that determine how and when Amazon AppFlow runs the specified flow. — shape: {triggerType?: "Scheduled"|"Event"|"OnDemand", triggerProperties?: record}
  source_flow_config: record # Contains information about the configuration of the source connector used in the flow. — shape: {connectorType?: "Salesforce"|"Singular"|"Slack"|"Redshift"|"S3"|"Marketo"|"Googleanalytics"|"Zendesk"|"Servicenow"|"Datadog"|"Trendmicro"|"Snowflake"|"Dynatrace"|"Infornexus"|"Amplitude"|"Veeva"|"EventBridge"|"LookoutMetrics"|"Upsolver"|"Honeycode"|"CustomerProfiles"|"SAPOData"|"CustomConnector"|"Pardot", apiVersion?: string, connectorProfileName?: string, sourceConnectorProperties?: record, incrementalPullConfig?: record}
  destination_flow_config_list: list # The configuration that controls how Amazon AppFlow transfers data to the destination connector. — item shape: {connectorType: "Salesforce"|"Singular"|"Slack"|"Redshift"|"S3"|"Marketo"|"Googleanalytics"|"Zendesk"|"Servicenow"|"Datadog"|"Trendmicro"|"Snowflake"|"Dynatrace"|"Infornexus"|"Amplitude"|"Veeva"|"EventBridge"|"LookoutMetrics"|"Upsolver"|"Honeycode"|"CustomerProfiles"|"SAPOData"|"CustomConnector"|"Pardot", apiVersion?: string, connectorProfileName?: string, destinationConnectorProperties: record}
  tasks: list # A list of tasks that Amazon AppFlow performs while transferring the data in the flow run. — item shape: {sourceFields: list<string>, connectorOperator?: record, destinationField?: string, taskType: "Arithmetic"|"Filter"|"Map"|"Map_all"|"Mask"|"Merge"|"Passthrough"|"Truncate"|"Validate"|"Partition", taskProperties?: record}
  --metadata-catalog-config: record # Specifies the configuration that Amazon AppFlow uses when it catalogs your data. When Amazon AppFlow catalogs your data, it stores metadata in a data catalog. — shape: {glueDataCatalog?: record}
  --client-token: string # The clientToken parameter is an idempotency token. It ensures that your UpdateFlow request completes only once. You choose the value to pass. For example, if you don't receive a response from your request, you can safely retry the request with the same clientToken parameter value. If you omit a clientToken value, the Amazon Web Services SDK that you are using inserts a value for you. This way, the SDK can safely retry requests multiple times after a network error. You must provide your own value for other use cases. If you specify input parameters that differ from your first request, an error occurs. If you use a different value for clientToken, Amazon AppFlow considers it a new call to UpdateFlow. The token is active for 8 hours.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/update-flow"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: flowName, var: flow_name}, {name: description, var: description}, {name: triggerConfig, var: trigger_config}, {name: sourceFlowConfig, var: source_flow_config}, {name: destinationFlowConfigList, var: destination_flow_config_list}, {name: tasks, var: tasks}, {name: metadataCatalogConfig, var: metadata_catalog_config}, {name: clientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, flow_name: $flow_name, description: $description, trigger_config: $trigger_config, source_flow_config: $source_flow_config, destination_flow_config_list: $destination_flow_config_list, tasks: $tasks, metadata_catalog_config: $metadata_catalog_config, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
