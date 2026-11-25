# Auto-generated client for AWS AppSync v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/appsync/2017-07-25/openapi.json
# Auth: --token flag or $env.AWS_APPSYNC_TOKEN

const CLIENT = {
  base_url: "http://appsync.us-east-1.amazonaws.com"
  token_env_var: "AWS_APPSYNC_TOKEN"
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

def base-url-completer [] { ["http://appsync.us-east-1.amazonaws.com" "http://appsync.us-east-2.amazonaws.com" "http://appsync.us-west-1.amazonaws.com" "http://appsync.us-west-2.amazonaws.com" "http://appsync.us-gov-west-1.amazonaws.com" "http://appsync.us-gov-east-1.amazonaws.com" "http://appsync.ca-central-1.amazonaws.com" "http://appsync.eu-north-1.amazonaws.com" "http://appsync.eu-west-1.amazonaws.com" "http://appsync.eu-west-2.amazonaws.com" "http://appsync.eu-west-3.amazonaws.com" "http://appsync.eu-central-1.amazonaws.com" "http://appsync.eu-south-1.amazonaws.com" "http://appsync.af-south-1.amazonaws.com" "http://appsync.ap-northeast-1.amazonaws.com" "http://appsync.ap-northeast-2.amazonaws.com" "http://appsync.ap-northeast-3.amazonaws.com" "http://appsync.ap-southeast-1.amazonaws.com" "http://appsync.ap-southeast-2.amazonaws.com" "http://appsync.ap-east-1.amazonaws.com" "http://appsync.ap-south-1.amazonaws.com" "http://appsync.sa-east-1.amazonaws.com" "http://appsync.me-south-1.amazonaws.com" "https://appsync.us-east-1.amazonaws.com" "https://appsync.us-east-2.amazonaws.com" "https://appsync.us-west-1.amazonaws.com" "https://appsync.us-west-2.amazonaws.com" "https://appsync.us-gov-west-1.amazonaws.com" "https://appsync.us-gov-east-1.amazonaws.com" "https://appsync.ca-central-1.amazonaws.com" "https://appsync.eu-north-1.amazonaws.com" "https://appsync.eu-west-1.amazonaws.com" "https://appsync.eu-west-2.amazonaws.com" "https://appsync.eu-west-3.amazonaws.com" "https://appsync.eu-central-1.amazonaws.com" "https://appsync.eu-south-1.amazonaws.com" "https://appsync.af-south-1.amazonaws.com" "https://appsync.ap-northeast-1.amazonaws.com" "https://appsync.ap-northeast-2.amazonaws.com" "https://appsync.ap-northeast-3.amazonaws.com" "https://appsync.ap-southeast-1.amazonaws.com" "https://appsync.ap-southeast-2.amazonaws.com" "https://appsync.ap-east-1.amazonaws.com" "https://appsync.ap-south-1.amazonaws.com" "https://appsync.sa-east-1.amazonaws.com" "https://appsync.me-south-1.amazonaws.com" "http://appsync.cn-north-1.amazonaws.com.cn" "http://appsync.cn-northwest-1.amazonaws.com.cn" "https://appsync.cn-north-1.amazonaws.com.cn" "https://appsync.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-caching-behavior-completer [] { ["FULL_REQUEST_CACHING" "PER_RESOLVER_CACHING"] }
def type-completer [] { ["LARGE" "LARGE_12X" "LARGE_2X" "LARGE_4X" "LARGE_8X" "MEDIUM" "R4_2XLARGE" "R4_4XLARGE" "R4_8XLARGE" "R4_LARGE" "R4_XLARGE" "SMALL" "T2_MEDIUM" "T2_SMALL" "XLARGE"] }
def type-completer-1 [] { ["AMAZON_DYNAMODB" "AMAZON_ELASTICSEARCH" "AMAZON_EVENTBRIDGE" "AMAZON_OPENSEARCH_SERVICE" "AWS_LAMBDA" "HTTP" "NONE" "RELATIONAL_DATABASE"] }
def authentication-type-completer [] { ["AMAZON_COGNITO_USER_POOLS" "API_KEY" "AWS_IAM" "AWS_LAMBDA" "OPENID_CONNECT"] }
def kind-completer [] { ["PIPELINE" "UNIT"] }
def format-completer [] { ["JSON" "SDL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-api: "record<apiAssociation: record<domainName: string, apiId: string, associationStatus: string, deploymentDetail: string>>"
    disassociate-api: "record"
    get-api-association: "record<apiAssociation: record<domainName: string, apiId: string, associationStatus: string, deploymentDetail: string>>"
    create-api-cache: "record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>"
    delete-api-cache: "record"
    get-api-cache: "record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>"
    create-api-key: "record<apiKey: record<id: string, description: string, expires: int, deletes: int>>"
    list-api-keys: "record<apiKeys: table<id: string, description: string, expires: int, deletes: int>, nextToken: string>"
    create-data-source: "record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>"
    list-data-sources: "record<dataSources: table<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record, lambdaConfig: record, elasticsearchConfig: record, openSearchServiceConfig: record, httpConfig: record, relationalDatabaseConfig: record, eventBridgeConfig: record>, nextToken: string>"
    create-domain-name: "record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>"
    list-domain-names: "record<domainNameConfigs: table<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>, nextToken: string>"
    create-function: "record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    list-functions: "record<functions: table<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>"
    create-graphql-api: "record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>"
    list-graphql-apis: "record<graphqlApis: table<name: string, apiId: string, authenticationType: string, logConfig: record, userPoolConfig: record, openIDConnectConfig: record, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record>, nextToken: string>"
    create-resolver: "record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    list-resolvers: "record<resolvers: table<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record, syncConfig: record, cachingConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>"
    create-type: "record<type: record<name: string, description: string, arn: string, definition: string, format: string>>"
    delete-api-key: "record"
    update-api-key: "record<apiKey: record<id: string, description: string, expires: int, deletes: int>>"
    delete-data-source: "record"
    get-data-source: "record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>"
    update-data-source: "record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>"
    delete-domain-name: "record"
    get-domain-name: "record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>"
    update-domain-name: "record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>"
    delete-function: "record"
    get-function: "record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    update-function: "record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    delete-graphql-api: "record"
    get-graphql-api: "record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>"
    update-graphql-api: "record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>"
    delete-resolver: "record"
    get-resolver: "record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    update-resolver: "record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>"
    delete-type: "record"
    update-type: "record<type: record<name: string, description: string, arn: string, definition: string, format: string>>"
    evaluate-code: "record<evaluationResult: string, error: record<message: string, codeErrors: list<record>>, logs: list<string>>"
    evaluate-mapping-template: "record<evaluationResult: string, error: record<message: string>, logs: list<string>>"
    flush-api-cache: "record"
    get-introspection-schema: "record<schema: string>"
    get-schema-creation-status: "record<status: string, details: string>"
    start-schema-creation: "record<status: string>"
    get-type: "record<type: record<name: string, description: string, arn: string, definition: string, format: string>>"
    list-resolvers-by-function: "record<resolvers: table<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record, syncConfig: record, cachingConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    list-types: "record<types: table<name: string, description: string, arn: string, definition: string, format: string>, nextToken: string>"
    untag-resource: "record"
    update-api-cache: "record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-api" "disassociate-api" "get-api-association" "create-api-cache" "delete-api-cache" "get-api-cache" "create-api-key" "list-api-keys" "create-data-source" "list-data-sources" "create-domain-name" "list-domain-names" "create-function" "list-functions" "create-graphql-api" "list-graphql-apis" "create-resolver" "list-resolvers" "create-type" "delete-api-key" "update-api-key" "delete-data-source" "get-data-source" "update-data-source" "delete-domain-name" "get-domain-name" "update-domain-name" "delete-function" "get-function" "update-function" "delete-graphql-api" "get-graphql-api" "update-graphql-api" "delete-resolver" "get-resolver" "update-resolver" "delete-type" "update-type" "evaluate-code" "evaluate-mapping-template" "flush-api-cache" "get-introspection-schema" "get-schema-creation-status" "start-schema-creation" "get-type" "list-resolvers-by-function" "list-tags-for-resource" "tag-resource" "list-types" "untag-resource" "update-api-cache" "commands"] | sort) } | get name | first)
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

# Maps an endpoint to your custom domain.
#
# POST /v1/domainnames/{domainName}/apiassociation
# Returns: record<apiAssociation: record<domainName: string, apiId: string, associationStatus: string, deploymentDetail: string>>
# operationId: AssociateApi
export def "associate-api" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  api_id: string # The API ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domainnames/{domainName}/apiassociation"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiId, var: api_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, api_id: $api_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an ApiAssociation object from a custom domain.
#
# DELETE /v1/domainnames/{domainName}/apiassociation
# Returns: record
# operationId: DisassociateApi
export def "disassociate-api" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/domainnames/{domainName}/apiassociation"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an ApiAssociation object.
#
# GET /v1/domainnames/{domainName}/apiassociation
# Returns: record<apiAssociation: record<domainName: string, apiId: string, associationStatus: string, deploymentDetail: string>>
# operationId: GetApiAssociation
export def "get-api-association" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/domainnames/{domainName}/apiassociation"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cache for the GraphQL API.
#
# POST /v1/apis/{apiId}/ApiCaches
# Returns: record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>
# operationId: CreateApiCache
export def "create-api-cache" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  ttl: int # TTL in seconds for cache entries. Valid values are 1–3,600 seconds.
  --transit-encryption-enabled: oneof<nothing, bool> # Transit encryption flag when connecting to cache. You cannot update this setting after creation.
  --at-rest-encryption-enabled: oneof<nothing, bool> # At-rest encryption flag for cache. You cannot update this setting after creation.
  api_caching_behavior: string@api-caching-behavior-completer # Caching behavior. FULL_REQUEST_CACHING: All requests are fully cached. PER_RESOLVER_CACHING: Individual resolvers that you specify are cached.
  type: string@type-completer # The cache instance type. Valid values are SMALL MEDIUM LARGE XLARGE LARGE_2X LARGE_4X LARGE_8X (not available in all regions) LARGE_12X Historically, instance types were identified by an EC2-style value. As of July 2020, this is deprecated, and the generic identifiers above should be used. The following legacy instance types are available, but their use is discouraged: T2_SMALL: A t2.small instance type. T2_MEDIUM: A t2.medium instance type. R4_LARGE: A r4.large instance type. R4_XLARGE: A r4.xlarge instance type. R4_2XLARGE: A r4.2xlarge instance type. R4_4XLARGE: A r4.4xlarge instance type. R4_8XLARGE: A r4.8xlarge instance type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/ApiCaches"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ttl, var: ttl}, {name: transitEncryptionEnabled, var: transit_encryption_enabled}, {name: atRestEncryptionEnabled, var: at_rest_encryption_enabled}, {name: apiCachingBehavior, var: api_caching_behavior}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ttl: $ttl, transit_encryption_enabled: $transit_encryption_enabled, at_rest_encryption_enabled: $at_rest_encryption_enabled, api_caching_behavior: $api_caching_behavior, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an ApiCache object.
#
# DELETE /v1/apis/{apiId}/ApiCaches
# Returns: record
# operationId: DeleteApiCache
export def "delete-api-cache" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/ApiCaches"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an ApiCache object.
#
# GET /v1/apis/{apiId}/ApiCaches
# Returns: record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>
# operationId: GetApiCache
export def "get-api-cache" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/ApiCaches"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a unique key that you can distribute to clients who invoke your API.
#
# POST /v1/apis/{apiId}/apikeys
# Returns: record<apiKey: record<id: string, description: string, expires: int, deletes: int>>
# operationId: CreateApiKey
export def "create-api-key" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the purpose of the API key.
  --expires: int # From the creation time, the time after which the API key expires. The date is represented as seconds since the epoch, rounded down to the nearest hour. The default value for this parameter is 7 days from creation time. For more information, see .
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/apikeys"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires, var: expires}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, expires: $expires
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the API keys for a given API. API keys are deleted automatically 60 days after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call DeleteApiKey to manually delete a key before it's automatically deleted.
#
# GET /v1/apis/{apiId}/apikeys
# Returns: record<apiKeys: table<id: string, description: string, expires: int, deletes: int>, nextToken: string>
# operationId: ListApiKeys
export def "list-api-keys" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/apikeys"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a DataSource object.
#
# POST /v1/apis/{apiId}/datasources
# Returns: record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>
# operationId: CreateDataSource
export def "create-data-source" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A user-supplied name for the DataSource.
  --description: string # A description of the DataSource.
  type: string@type-completer-1 # The type of the DataSource.
  --service-role-arn: string # The Identity and Access Management (IAM) service role Amazon Resource Name (ARN) for the data source. The system assumes this role when accessing the data source.
  --dynamodb-config: record # Describes an Amazon DynamoDB data source configuration. — shape: {tableName?: string, awsRegion?: string, useCallerCredentials?: bool, deltaSyncConfig?: record, versioned?: bool}
  --lambda-config: record # Describes an Lambda data source configuration. — shape: {lambdaFunctionArn?: string}
  --elasticsearch-config: record # Describes an OpenSearch data source configuration. As of September 2021, Amazon Elasticsearch service is Amazon OpenSearch Service. This configuration is deprecated. For new data sources, use OpenSearchServiceDataSourceConfig to specify an OpenSearch data source. — shape: {endpoint?: string, awsRegion?: string}
  --open-search-service-config: record # Describes an OpenSearch data source configuration. — shape: {endpoint?: string, awsRegion?: string}
  --http-config: record # Describes an HTTP data source configuration. — shape: {endpoint?: string, authorizationConfig?: record}
  --relational-database-config: record # Describes a relational database data source configuration. — shape: {relationalDatabaseSourceType?: "RDS_HTTP_ENDPOINT", rdsHttpEndpointConfig?: record}
  --event-bridge-config: record # Describes an Amazon EventBridge bus data source configuration. — shape: {eventBusArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/datasources"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: type, var: type}, {name: serviceRoleArn, var: service_role_arn}, {name: dynamodbConfig, var: dynamodb_config}, {name: lambdaConfig, var: lambda_config}, {name: elasticsearchConfig, var: elasticsearch_config}, {name: openSearchServiceConfig, var: open_search_service_config}, {name: httpConfig, var: http_config}, {name: relationalDatabaseConfig, var: relational_database_config}, {name: eventBridgeConfig, var: event_bridge_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, type: $type, service_role_arn: $service_role_arn, dynamodb_config: $dynamodb_config, lambda_config: $lambda_config, elasticsearch_config: $elasticsearch_config, open_search_service_config: $open_search_service_config, http_config: $http_config, relational_database_config: $relational_database_config, event_bridge_config: $event_bridge_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the data sources for a given API.
#
# GET /v1/apis/{apiId}/datasources
# Returns: record<dataSources: table<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record, lambdaConfig: record, elasticsearchConfig: record, openSearchServiceConfig: record, httpConfig: record, relationalDatabaseConfig: record, eventBridgeConfig: record>, nextToken: string>
# operationId: ListDataSources
export def "list-data-sources" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/datasources"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom DomainName object.
#
# POST /v1/domainnames
# Returns: record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>
# operationId: CreateDomainName
export def "create-domain-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The domain name.
  certificate_arn: string # The Amazon Resource Name (ARN) of the certificate. This can be an Certificate Manager (ACM) certificate or an Identity and Access Management (IAM) server certificate.
  --description: string # A description of the DomainName.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domainnames"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: certificateArn, var: certificate_arn}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, certificate_arn: $certificate_arn, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists multiple custom domain names.
#
# GET /v1/domainnames
# Returns: record<domainNameConfigs: table<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>, nextToken: string>
# operationId: ListDomainNames
export def "list-domain-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The API token.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/domainnames"
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

# Creates a Function object. A function is a reusable entity. You can use multiple functions to compose the resolver logic.
#
# POST /v1/apis/{apiId}/functions
# Returns: record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: CreateFunction
export def "create-function" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The Function name. The function name does not have to be unique.
  --description: string # The Function description.
  data_source_name: string # The Function DataSource name.
  --request-mapping-template: string # The Function request mapping template. Functions support only the 2018-05-29 version of the request mapping template.
  --response-mapping-template: string # The Function response mapping template.
  --function-version: string # The version of the request mapping template. Currently, the supported value is 2018-05-29. Note that when using VTL and mapping templates, the functionVersion is required.
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: "OPTIMISTIC_CONCURRENCY"|"LAMBDA"|"AUTOMERGE"|"NONE", conflictDetection?: "VERSION"|"NONE", lambdaConflictHandlerConfig?: record}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: "APPSYNC_JS", runtimeVersion?: string}
  --code: string # The function code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/functions"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: dataSourceName, var: data_source_name}, {name: requestMappingTemplate, var: request_mapping_template}, {name: responseMappingTemplate, var: response_mapping_template}, {name: functionVersion, var: function_version}, {name: syncConfig, var: sync_config}, {name: maxBatchSize, var: max_batch_size}, {name: runtime, var: runtime}, {name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, data_source_name: $data_source_name, request_mapping_template: $request_mapping_template, response_mapping_template: $response_mapping_template, function_version: $function_version, sync_config: $sync_config, max_batch_size: $max_batch_size, runtime: $runtime, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List multiple functions.
#
# GET /v1/apis/{apiId}/functions
# Returns: record<functions: table<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>
# operationId: ListFunctions
export def "list-functions" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/functions"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GraphqlApi object.
#
# POST /v1/apis
# Returns: record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>
# operationId: CreateGraphqlApi
export def "create-graphql-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A user-supplied name for the GraphqlApi.
  --log-config: record # The Amazon CloudWatch Logs configuration. — shape: {fieldLogLevel?: "NONE"|"ERROR"|"ALL", cloudWatchLogsRoleArn?: string, excludeVerboseContent?: bool}
  authentication_type: string@authentication-type-completer # The authentication type: API key, Identity and Access Management (IAM), OpenID Connect (OIDC), Amazon Cognito user pools, or Lambda.
  --user-pool-config: record # Describes an Amazon Cognito user pool configuration. — shape: {userPoolId?: string, awsRegion?: string, defaultAction?: "ALLOW"|"DENY", appIdClientRegex?: string}
  --open-id-connect-config: record # Describes an OpenID Connect (OIDC) configuration. — shape: {issuer?: string, clientId?: string, iatTTL?: int, authTTL?: int}
  --tags: record # A map with keys of TagKey objects and values of TagValue objects.
  --additional-authentication-providers: list # A list of additional authentication providers for the GraphqlApi API. — item shape: {authenticationType?: "API_KEY"|"AWS_IAM"|"AMAZON_COGNITO_USER_POOLS"|"OPENID_CONNECT"|"AWS_LAMBDA", openIDConnectConfig?: record, userPoolConfig?: record, lambdaAuthorizerConfig?: record}
  --xray-enabled: oneof<nothing, bool> # A flag indicating whether to use X-Ray tracing for the GraphqlApi.
  --lambda-authorizer-config: record # A LambdaAuthorizerConfig specifies how to authorize AppSync API access when using the AWS_LAMBDA authorizer mode. Be aware that an AppSync API can have only one Lambda authorizer configured at a time. — shape: {authorizerResultTtlInSeconds?: int, authorizerUri?: string, identityValidationExpression?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: logConfig, var: log_config}, {name: authenticationType, var: authentication_type}, {name: userPoolConfig, var: user_pool_config}, {name: openIDConnectConfig, var: open_id_connect_config}, {name: tags, var: tags}, {name: additionalAuthenticationProviders, var: additional_authentication_providers}, {name: xrayEnabled, var: xray_enabled}, {name: lambdaAuthorizerConfig, var: lambda_authorizer_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, log_config: $log_config, authentication_type: $authentication_type, user_pool_config: $user_pool_config, open_id_connect_config: $open_id_connect_config, tags: $tags, additional_authentication_providers: $additional_authentication_providers, xray_enabled: $xray_enabled, lambda_authorizer_config: $lambda_authorizer_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists your GraphQL APIs.
#
# GET /v1/apis
# Returns: record<graphqlApis: table<name: string, apiId: string, authenticationType: string, logConfig: record, userPoolConfig: record, openIDConnectConfig: record, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record>, nextToken: string>
# operationId: ListGraphqlApis
export def "list-graphql-apis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis"
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

# Creates a Resolver object. A resolver converts incoming requests into a format that a data source can understand, and converts the data source's responses into GraphQL.
#
# POST /v1/apis/{apiId}/types/{typeName}/resolvers
# Returns: record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: CreateResolver
export def "create-resolver" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  field_name: string # The name of the field to attach the resolver to.
  --data-source-name: string # The name of the data source for which the resolver is being created.
  --request-mapping-template: string # The mapping template to use for requests. A resolver uses a request mapping template to convert a GraphQL expression into a format that a data source can understand. Mapping templates are written in Apache Velocity Template Language (VTL). VTL request mapping templates are optional when using an Lambda data source. For all other data sources, VTL request and response mapping templates are required.
  --response-mapping-template: string # The mapping template to use for responses from the data source.
  --kind: string@kind-completer # The resolver type. UNIT: A UNIT resolver type. A UNIT resolver is the default resolver type. You can use a UNIT resolver to run a GraphQL query against a single data source. PIPELINE: A PIPELINE resolver type. You can use a PIPELINE resolver to invoke a series of Function objects in a serial manner. You can use a pipeline resolver to run a GraphQL query against multiple data sources.
  --pipeline-config: record # The pipeline configuration for a resolver of kind PIPELINE. — shape: {functions?: list<string>}
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: "OPTIMISTIC_CONCURRENCY"|"LAMBDA"|"AUTOMERGE"|"NONE", conflictDetection?: "VERSION"|"NONE", lambdaConflictHandlerConfig?: record}
  --caching-config: record # The caching configuration for a resolver that has caching activated. — shape: {ttl?: int, cachingKeys?: list<string>}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: "APPSYNC_JS", runtimeVersion?: string}
  --code: string # The resolver code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/types/{typeName}/resolvers"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: fieldName, var: field_name}, {name: dataSourceName, var: data_source_name}, {name: requestMappingTemplate, var: request_mapping_template}, {name: responseMappingTemplate, var: response_mapping_template}, {name: kind, var: kind}, {name: pipelineConfig, var: pipeline_config}, {name: syncConfig, var: sync_config}, {name: cachingConfig, var: caching_config}, {name: maxBatchSize, var: max_batch_size}, {name: runtime, var: runtime}, {name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, field_name: $field_name, data_source_name: $data_source_name, request_mapping_template: $request_mapping_template, response_mapping_template: $response_mapping_template, kind: $kind, pipeline_config: $pipeline_config, sync_config: $sync_config, caching_config: $caching_config, max_batch_size: $max_batch_size, runtime: $runtime, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the resolvers for a given API and type.
#
# GET /v1/apis/{apiId}/types/{typeName}/resolvers
# Returns: record<resolvers: table<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record, syncConfig: record, cachingConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>
# operationId: ListResolvers
export def "list-resolvers" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/types/{typeName}/resolvers"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Type object.
#
# POST /v1/apis/{apiId}/types
# Returns: record<type: record<name: string, description: string, arn: string, definition: string, format: string>>
# operationId: CreateType
export def "create-type" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  definition: string # The type definition, in GraphQL Schema Definition Language (SDL) format. For more information, see the GraphQL SDL documentation (http://graphql.org/learn/schema/).
  format: string@format-completer # The type format: SDL or JSON.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/types"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: definition, var: definition}, {name: format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, definition: $definition, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an API key.
#
# DELETE /v1/apis/{apiId}/apikeys/{id}
# Returns: record
# operationId: DeleteApiKey
export def "delete-api-key" [
  api_id: string
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
    path: "/v1/apis/{apiId}/apikeys/{id}"
    path_params: [{name: apiId, var: api_id}, {name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an API key. You can update the key as long as it's not deleted.
#
# POST /v1/apis/{apiId}/apikeys/{id}
# Returns: record<apiKey: record<id: string, description: string, expires: int, deletes: int>>
# operationId: UpdateApiKey
export def "update-api-key" [
  api_id: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the purpose of the API key.
  --expires: int # From the update time, the time after which the API key expires. The date is represented as seconds since the epoch. For more information, see .
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/apikeys/{id}"
    path_params: [{name: apiId, var: api_id}, {name: id, var: id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires, var: expires}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, id: $id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, expires: $expires
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a DataSource object.
#
# DELETE /v1/apis/{apiId}/datasources/{name}
# Returns: record
# operationId: DeleteDataSource
export def "delete-data-source" [
  api_id: string
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
    path: "/v1/apis/{apiId}/datasources/{name}"
    path_params: [{name: apiId, var: api_id}, {name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a DataSource object.
#
# GET /v1/apis/{apiId}/datasources/{name}
# Returns: record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>
# operationId: GetDataSource
export def "get-data-source" [
  api_id: string
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
    path: "/v1/apis/{apiId}/datasources/{name}"
    path_params: [{name: apiId, var: api_id}, {name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a DataSource object.
#
# POST /v1/apis/{apiId}/datasources/{name}
# Returns: record<dataSource: record<dataSourceArn: string, name: string, description: string, type: string, serviceRoleArn: string, dynamodbConfig: record<tableName: string, awsRegion: string, useCallerCredentials: bool, deltaSyncConfig: record, versioned: bool>, lambdaConfig: record<lambdaFunctionArn: string>, elasticsearchConfig: record<endpoint: string, awsRegion: string>, openSearchServiceConfig: record<endpoint: string, awsRegion: string>, httpConfig: record<endpoint: string, authorizationConfig: record>, relationalDatabaseConfig: record<relationalDatabaseSourceType: string, rdsHttpEndpointConfig: record>, eventBridgeConfig: record<eventBusArn: string>>>
# operationId: UpdateDataSource
export def "update-data-source" [
  api_id: string
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
  --description: string # The new description for the data source.
  type: string@type-completer-1 # The new data source type.
  --service-role-arn: string # The new service role Amazon Resource Name (ARN) for the data source.
  --dynamodb-config: record # Describes an Amazon DynamoDB data source configuration. — shape: {tableName?: string, awsRegion?: string, useCallerCredentials?: bool, deltaSyncConfig?: record, versioned?: bool}
  --lambda-config: record # Describes an Lambda data source configuration. — shape: {lambdaFunctionArn?: string}
  --elasticsearch-config: record # Describes an OpenSearch data source configuration. As of September 2021, Amazon Elasticsearch service is Amazon OpenSearch Service. This configuration is deprecated. For new data sources, use OpenSearchServiceDataSourceConfig to specify an OpenSearch data source. — shape: {endpoint?: string, awsRegion?: string}
  --open-search-service-config: record # Describes an OpenSearch data source configuration. — shape: {endpoint?: string, awsRegion?: string}
  --http-config: record # Describes an HTTP data source configuration. — shape: {endpoint?: string, authorizationConfig?: record}
  --relational-database-config: record # Describes a relational database data source configuration. — shape: {relationalDatabaseSourceType?: "RDS_HTTP_ENDPOINT", rdsHttpEndpointConfig?: record}
  --event-bridge-config: record # Describes an Amazon EventBridge bus data source configuration. — shape: {eventBusArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/datasources/{name}"
    path_params: [{name: apiId, var: api_id}, {name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: type, var: type}, {name: serviceRoleArn, var: service_role_arn}, {name: dynamodbConfig, var: dynamodb_config}, {name: lambdaConfig, var: lambda_config}, {name: elasticsearchConfig, var: elasticsearch_config}, {name: openSearchServiceConfig, var: open_search_service_config}, {name: httpConfig, var: http_config}, {name: relationalDatabaseConfig, var: relational_database_config}, {name: eventBridgeConfig, var: event_bridge_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, type: $type, service_role_arn: $service_role_arn, dynamodb_config: $dynamodb_config, lambda_config: $lambda_config, elasticsearch_config: $elasticsearch_config, open_search_service_config: $open_search_service_config, http_config: $http_config, relational_database_config: $relational_database_config, event_bridge_config: $event_bridge_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a custom DomainName object.
#
# DELETE /v1/domainnames/{domainName}
# Returns: record
# operationId: DeleteDomainName
export def "delete-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a custom DomainName object.
#
# GET /v1/domainnames/{domainName}
# Returns: record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>
# operationId: GetDomainName
export def "get-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a custom DomainName object.
#
# POST /v1/domainnames/{domainName}
# Returns: record<domainNameConfig: record<domainName: string, description: string, certificateArn: string, appsyncDomainName: string, hostedZoneId: string>>
# operationId: UpdateDomainName
export def "update-domain-name" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # A description of the DomainName.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domainnames/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Function.
#
# DELETE /v1/apis/{apiId}/functions/{functionId}
# Returns: record
# operationId: DeleteFunction
export def "delete-function" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/functions/{functionId}"
    path_params: [{name: apiId, var: api_id}, {name: functionId, var: function_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, function_id: $function_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Function.
#
# GET /v1/apis/{apiId}/functions/{functionId}
# Returns: record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: GetFunction
export def "get-function" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/functions/{functionId}"
    path_params: [{name: apiId, var: api_id}, {name: functionId, var: function_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, function_id: $function_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Function object.
#
# POST /v1/apis/{apiId}/functions/{functionId}
# Returns: record<functionConfiguration: record<functionId: string, functionArn: string, name: string, description: string, dataSourceName: string, requestMappingTemplate: string, responseMappingTemplate: string, functionVersion: string, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: UpdateFunction
export def "update-function" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The Function name.
  --description: string # The Function description.
  data_source_name: string # The Function DataSource name.
  --request-mapping-template: string # The Function request mapping template. Functions support only the 2018-05-29 version of the request mapping template.
  --response-mapping-template: string # The Function request mapping template.
  --function-version: string # The version of the request mapping template. Currently, the supported value is 2018-05-29. Note that when using VTL and mapping templates, the functionVersion is required.
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: "OPTIMISTIC_CONCURRENCY"|"LAMBDA"|"AUTOMERGE"|"NONE", conflictDetection?: "VERSION"|"NONE", lambdaConflictHandlerConfig?: record}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: "APPSYNC_JS", runtimeVersion?: string}
  --code: string # The function code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/functions/{functionId}"
    path_params: [{name: apiId, var: api_id}, {name: functionId, var: function_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: dataSourceName, var: data_source_name}, {name: requestMappingTemplate, var: request_mapping_template}, {name: responseMappingTemplate, var: response_mapping_template}, {name: functionVersion, var: function_version}, {name: syncConfig, var: sync_config}, {name: maxBatchSize, var: max_batch_size}, {name: runtime, var: runtime}, {name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, function_id: $function_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, data_source_name: $data_source_name, request_mapping_template: $request_mapping_template, response_mapping_template: $response_mapping_template, function_version: $function_version, sync_config: $sync_config, max_batch_size: $max_batch_size, runtime: $runtime, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a GraphqlApi object.
#
# DELETE /v1/apis/{apiId}
# Returns: record
# operationId: DeleteGraphqlApi
export def "delete-graphql-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a GraphqlApi object.
#
# GET /v1/apis/{apiId}
# Returns: record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>
# operationId: GetGraphqlApi
export def "get-graphql-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a GraphqlApi object.
#
# POST /v1/apis/{apiId}
# Returns: record<graphqlApi: record<name: string, apiId: string, authenticationType: string, logConfig: record<fieldLogLevel: string, cloudWatchLogsRoleArn: string, excludeVerboseContent: bool>, userPoolConfig: record<userPoolId: string, awsRegion: string, defaultAction: string, appIdClientRegex: string>, openIDConnectConfig: record<issuer: string, clientId: string, iatTTL: int, authTTL: int>, arn: string, uris: record, tags: record, additionalAuthenticationProviders: list<record>, xrayEnabled: bool, wafWebAclArn: string, lambdaAuthorizerConfig: record<authorizerResultTtlInSeconds: int, authorizerUri: string, identityValidationExpression: string>>>
# operationId: UpdateGraphqlApi
export def "update-graphql-api" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The new name for the GraphqlApi object.
  --log-config: record # The Amazon CloudWatch Logs configuration. — shape: {fieldLogLevel?: "NONE"|"ERROR"|"ALL", cloudWatchLogsRoleArn?: string, excludeVerboseContent?: bool}
  --authentication-type: string@authentication-type-completer # The new authentication type for the GraphqlApi object.
  --user-pool-config: record # Describes an Amazon Cognito user pool configuration. — shape: {userPoolId?: string, awsRegion?: string, defaultAction?: "ALLOW"|"DENY", appIdClientRegex?: string}
  --open-id-connect-config: record # Describes an OpenID Connect (OIDC) configuration. — shape: {issuer?: string, clientId?: string, iatTTL?: int, authTTL?: int}
  --additional-authentication-providers: list # A list of additional authentication providers for the GraphqlApi API. — item shape: {authenticationType?: "API_KEY"|"AWS_IAM"|"AMAZON_COGNITO_USER_POOLS"|"OPENID_CONNECT"|"AWS_LAMBDA", openIDConnectConfig?: record, userPoolConfig?: record, lambdaAuthorizerConfig?: record}
  --xray-enabled: oneof<nothing, bool> # A flag indicating whether to use X-Ray tracing for the GraphqlApi.
  --lambda-authorizer-config: record # A LambdaAuthorizerConfig specifies how to authorize AppSync API access when using the AWS_LAMBDA authorizer mode. Be aware that an AppSync API can have only one Lambda authorizer configured at a time. — shape: {authorizerResultTtlInSeconds?: int, authorizerUri?: string, identityValidationExpression?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: logConfig, var: log_config}, {name: authenticationType, var: authentication_type}, {name: userPoolConfig, var: user_pool_config}, {name: openIDConnectConfig, var: open_id_connect_config}, {name: additionalAuthenticationProviders, var: additional_authentication_providers}, {name: xrayEnabled, var: xray_enabled}, {name: lambdaAuthorizerConfig, var: lambda_authorizer_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, log_config: $log_config, authentication_type: $authentication_type, user_pool_config: $user_pool_config, open_id_connect_config: $open_id_connect_config, additional_authentication_providers: $additional_authentication_providers, xray_enabled: $xray_enabled, lambda_authorizer_config: $lambda_authorizer_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Resolver object.
#
# DELETE /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# Returns: record
# operationId: DeleteResolver
export def "delete-resolver" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}, {name: fieldName, var: field_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, field_name: $field_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Resolver object.
#
# GET /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# Returns: record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: GetResolver
export def "get-resolver" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}, {name: fieldName, var: field_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, field_name: $field_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Resolver object.
#
# POST /v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}
# Returns: record<resolver: record<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record<functions: list>, syncConfig: record<conflictHandler: string, conflictDetection: string, lambdaConflictHandlerConfig: record>, cachingConfig: record<ttl: int, cachingKeys: list>, maxBatchSize: int, runtime: record<name: string, runtimeVersion: string>, code: string>>
# operationId: UpdateResolver
export def "update-resolver" [
  api_id: string
  type_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --data-source-name: string # The new data source name.
  --request-mapping-template: string # The new request mapping template. A resolver uses a request mapping template to convert a GraphQL expression into a format that a data source can understand. Mapping templates are written in Apache Velocity Template Language (VTL). VTL request mapping templates are optional when using an Lambda data source. For all other data sources, VTL request and response mapping templates are required.
  --response-mapping-template: string # The new response mapping template.
  --kind: string@kind-completer # The resolver type. UNIT: A UNIT resolver type. A UNIT resolver is the default resolver type. You can use a UNIT resolver to run a GraphQL query against a single data source. PIPELINE: A PIPELINE resolver type. You can use a PIPELINE resolver to invoke a series of Function objects in a serial manner. You can use a pipeline resolver to run a GraphQL query against multiple data sources.
  --pipeline-config: record # The pipeline configuration for a resolver of kind PIPELINE. — shape: {functions?: list<string>}
  --sync-config: record # Describes a Sync configuration for a resolver. Specifies which Conflict Detection strategy and Resolution strategy to use when the resolver is invoked. — shape: {conflictHandler?: "OPTIMISTIC_CONCURRENCY"|"LAMBDA"|"AUTOMERGE"|"NONE", conflictDetection?: "VERSION"|"NONE", lambdaConflictHandlerConfig?: record}
  --caching-config: record # The caching configuration for a resolver that has caching activated. — shape: {ttl?: int, cachingKeys?: list<string>}
  --max-batch-size: int # The maximum batching size for a resolver.
  --runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: "APPSYNC_JS", runtimeVersion?: string}
  --code: string # The resolver code that contains the request and response functions. When code is used, the runtime is required. The runtime value must be APPSYNC_JS.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}, {name: fieldName, var: field_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataSourceName, var: data_source_name}, {name: requestMappingTemplate, var: request_mapping_template}, {name: responseMappingTemplate, var: response_mapping_template}, {name: kind, var: kind}, {name: pipelineConfig, var: pipeline_config}, {name: syncConfig, var: sync_config}, {name: cachingConfig, var: caching_config}, {name: maxBatchSize, var: max_batch_size}, {name: runtime, var: runtime}, {name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, field_name: $field_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_source_name: $data_source_name, request_mapping_template: $request_mapping_template, response_mapping_template: $response_mapping_template, kind: $kind, pipeline_config: $pipeline_config, sync_config: $sync_config, caching_config: $caching_config, max_batch_size: $max_batch_size, runtime: $runtime, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Type object.
#
# DELETE /v1/apis/{apiId}/types/{typeName}
# Returns: record
# operationId: DeleteType
export def "delete-type" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/types/{typeName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a Type object.
#
# POST /v1/apis/{apiId}/types/{typeName}
# Returns: record<type: record<name: string, description: string, arn: string, definition: string, format: string>>
# operationId: UpdateType
export def "update-type" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --definition: string # The new definition.
  format: string@format-completer # The new type format: SDL or JSON.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/types/{typeName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: definition, var: definition}, {name: format, var: format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, definition: $definition, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates the given code and returns the response. The code definition requirements depend on the specified runtime. For APPSYNC_JS runtimes, the code defines the request and response functions. The request function takes the incoming request after a GraphQL operation is parsed and converts it into a request configuration for the selected data source operation. The response function interprets responses from the data source and maps it to the shape of the GraphQL field output type.
#
# POST /v1/dataplane-evaluatecode
# Returns: record<evaluationResult: string, error: record<message: string, codeErrors: list<record>>, logs: list<string>>
# operationId: EvaluateCode
export def "evaluate-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  runtime: record # Describes a runtime used by an Amazon Web Services AppSync pipeline resolver or Amazon Web Services AppSync function. Specifies the name and version of the runtime to use. Note that if a runtime is specified, code must also be specified. — shape: {name?: "APPSYNC_JS", runtimeVersion?: string}
  code: string # The code definition to be evaluated. Note that code and runtime are both required for this action. The runtime value must be APPSYNC_JS.
  context: string # The map that holds all of the contextual information for your resolver invocation. A context is required for this action.
  --function: string # The function within the code to be evaluated. If provided, the valid values are request and response.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/dataplane-evaluatecode"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: runtime, var: runtime}, {name: code, var: code}, {name: context, var: context}, {name: function, var: function}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, runtime: $runtime, code: $code, context: $context, function: $function
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluates a given template and returns the response. The mapping template can be a request or response template. Request templates take the incoming request after a GraphQL operation is parsed and convert it into a request configuration for the selected data source operation. Response templates interpret responses from the data source and map it to the shape of the GraphQL field output type. Mapping templates are written in the Apache Velocity Template Language (VTL).
#
# POST /v1/dataplane-evaluatetemplate
# Returns: record<evaluationResult: string, error: record<message: string>, logs: list<string>>
# operationId: EvaluateMappingTemplate
export def "evaluate-mapping-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template: string # The mapping template; this can be a request or response template. A template is required for this action.
  context: string # The map that holds all of the contextual information for your resolver invocation. A context is required for this action.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/dataplane-evaluatetemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: template, var: template}, {name: context, var: context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template: $template, context: $context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Flushes an ApiCache object.
#
# DELETE /v1/apis/{apiId}/FlushCache
# Returns: record
# operationId: FlushApiCache
export def "flush-api-cache" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/FlushCache"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the introspection schema for a GraphQL API.
#
# GET /v1/apis/{apiId}/schema
# Returns: record<schema: string>
# operationId: GetIntrospectionSchema
export def "get-introspection-schema" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The schema format: SDL or JSON. (required)
  --include-directives: oneof<nothing, bool> # A flag that specifies whether the schema introspection should contain directives.
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
    path: "/v1/apis/{apiId}/schema"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: format, var: format, required: true}, {name: includeDirectives, var: include_directives}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, format: $format, include_directives: $include_directives, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current status of a schema creation operation.
#
# GET /v1/apis/{apiId}/schemacreation
# Returns: record<status: string, details: string>
# operationId: GetSchemaCreationStatus
export def "get-schema-creation-status" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/v1/apis/{apiId}/schemacreation"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new schema to your GraphQL API. This operation is asynchronous. Use to determine when it has completed.
#
# POST /v1/apis/{apiId}/schemacreation
# Returns: record<status: string>
# operationId: StartSchemaCreation
export def "start-schema-creation" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  definition: string # The schema definition, in GraphQL schema language format.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/schemacreation"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Type object.
#
# GET /v1/apis/{apiId}/types/{typeName}
# Returns: record<type: record<name: string, description: string, arn: string, definition: string, format: string>>
# operationId: GetType
export def "get-type" [
  api_id: string
  type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The type format: SDL or JSON. (required)
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
    path: "/v1/apis/{apiId}/types/{typeName}"
    path_params: [{name: apiId, var: api_id}, {name: typeName, var: type_name}]
    query: [{name: format, var: format, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, type_name: $type_name, format: $format, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the resolvers that are associated with a specific function.
#
# GET /v1/apis/{apiId}/functions/{functionId}/resolvers
# Returns: record<resolvers: table<typeName: string, fieldName: string, dataSourceName: string, resolverArn: string, requestMappingTemplate: string, responseMappingTemplate: string, kind: string, pipelineConfig: record, syncConfig: record, cachingConfig: record, maxBatchSize: int, runtime: record, code: string>, nextToken: string>
# operationId: ListResolversByFunction
export def "list-resolvers-by-function" [
  api_id: string
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/functions/{functionId}/resolvers"
    path_params: [{name: apiId, var: api_id}, {name: functionId, var: function_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, function_id: $function_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for a resource.
#
# GET /v1/tags/{resourceArn}
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
    path: "/v1/tags/{resourceArn}"
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

# Tags a resource with user-supplied tags.
#
# POST /v1/tags/{resourceArn}
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
  tags: record # A map with keys of TagKey objects and values of TagValue objects.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/tags/{resourceArn}"
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

# Lists the types for a given API.
#
# GET /v1/apis/{apiId}/types
# Returns: record<types: table<name: string, description: string, arn: string, definition: string, format: string>, nextToken: string>
# operationId: ListTypes
export def "list-types" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The type format: SDL or JSON. (required)
  --next-token: string # An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  --max-results: int # The maximum number of results that you want the request to return.
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
    path: "/v1/apis/{apiId}/types"
    path_params: [{name: apiId, var: api_id}]
    query: [{name: format, var: format, required: true}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, format: $format, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untags a resource.
#
# DELETE /v1/tags/{resourceArn}
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
  --tag-keys: list<string> # A list of TagKey objects. (required)
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
    path: "/v1/tags/{resourceArn}"
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

# Updates the cache for the GraphQL API.
#
# POST /v1/apis/{apiId}/ApiCaches/update
# Returns: record<apiCache: record<ttl: int, apiCachingBehavior: string, transitEncryptionEnabled: bool, atRestEncryptionEnabled: bool, type: string, status: string>>
# operationId: UpdateApiCache
export def "update-api-cache" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  ttl: int # TTL in seconds for cache entries. Valid values are 1–3,600 seconds.
  api_caching_behavior: string@api-caching-behavior-completer # Caching behavior. FULL_REQUEST_CACHING: All requests are fully cached. PER_RESOLVER_CACHING: Individual resolvers that you specify are cached.
  type: string@type-completer # The cache instance type. Valid values are SMALL MEDIUM LARGE XLARGE LARGE_2X LARGE_4X LARGE_8X (not available in all regions) LARGE_12X Historically, instance types were identified by an EC2-style value. As of July 2020, this is deprecated, and the generic identifiers above should be used. The following legacy instance types are available, but their use is discouraged: T2_SMALL: A t2.small instance type. T2_MEDIUM: A t2.medium instance type. R4_LARGE: A r4.large instance type. R4_XLARGE: A r4.xlarge instance type. R4_2XLARGE: A r4.2xlarge instance type. R4_4XLARGE: A r4.4xlarge instance type. R4_8XLARGE: A r4.8xlarge instance type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apis/{apiId}/ApiCaches/update"
    path_params: [{name: apiId, var: api_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ttl, var: ttl}, {name: apiCachingBehavior, var: api_caching_behavior}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_id: $api_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ttl: $ttl, api_caching_behavior: $api_caching_behavior, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
