# Auto-generated client for AWS CodeBuild v2016-10-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codebuild/2016-10-06/openapi.json
# Auth: --token flag or $env.AWS_CODEBUILD_TOKEN

const CLIENT = {
  base_url: "http://codebuild.us-east-1.amazonaws.com"
  token_env_var: "AWS_CODEBUILD_TOKEN"
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

def base-url-completer [] { ["http://codebuild.us-east-1.amazonaws.com" "http://codebuild.us-east-2.amazonaws.com" "http://codebuild.us-west-1.amazonaws.com" "http://codebuild.us-west-2.amazonaws.com" "http://codebuild.us-gov-west-1.amazonaws.com" "http://codebuild.us-gov-east-1.amazonaws.com" "http://codebuild.ca-central-1.amazonaws.com" "http://codebuild.eu-north-1.amazonaws.com" "http://codebuild.eu-west-1.amazonaws.com" "http://codebuild.eu-west-2.amazonaws.com" "http://codebuild.eu-west-3.amazonaws.com" "http://codebuild.eu-central-1.amazonaws.com" "http://codebuild.eu-south-1.amazonaws.com" "http://codebuild.af-south-1.amazonaws.com" "http://codebuild.ap-northeast-1.amazonaws.com" "http://codebuild.ap-northeast-2.amazonaws.com" "http://codebuild.ap-northeast-3.amazonaws.com" "http://codebuild.ap-southeast-1.amazonaws.com" "http://codebuild.ap-southeast-2.amazonaws.com" "http://codebuild.ap-east-1.amazonaws.com" "http://codebuild.ap-south-1.amazonaws.com" "http://codebuild.sa-east-1.amazonaws.com" "http://codebuild.me-south-1.amazonaws.com" "https://codebuild.us-east-1.amazonaws.com" "https://codebuild.us-east-2.amazonaws.com" "https://codebuild.us-west-1.amazonaws.com" "https://codebuild.us-west-2.amazonaws.com" "https://codebuild.us-gov-west-1.amazonaws.com" "https://codebuild.us-gov-east-1.amazonaws.com" "https://codebuild.ca-central-1.amazonaws.com" "https://codebuild.eu-north-1.amazonaws.com" "https://codebuild.eu-west-1.amazonaws.com" "https://codebuild.eu-west-2.amazonaws.com" "https://codebuild.eu-west-3.amazonaws.com" "https://codebuild.eu-central-1.amazonaws.com" "https://codebuild.eu-south-1.amazonaws.com" "https://codebuild.af-south-1.amazonaws.com" "https://codebuild.ap-northeast-1.amazonaws.com" "https://codebuild.ap-northeast-2.amazonaws.com" "https://codebuild.ap-northeast-3.amazonaws.com" "https://codebuild.ap-southeast-1.amazonaws.com" "https://codebuild.ap-southeast-2.amazonaws.com" "https://codebuild.ap-east-1.amazonaws.com" "https://codebuild.ap-south-1.amazonaws.com" "https://codebuild.sa-east-1.amazonaws.com" "https://codebuild.me-south-1.amazonaws.com" "http://codebuild.cn-north-1.amazonaws.com.cn" "http://codebuild.cn-northwest-1.amazonaws.com.cn" "https://codebuild.cn-north-1.amazonaws.com.cn" "https://codebuild.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CodeBuild_20161006.BatchDeleteBuilds"] }
def x-amz-target-completer-1 [] { ["CodeBuild_20161006.BatchGetBuildBatches"] }
def x-amz-target-completer-2 [] { ["CodeBuild_20161006.BatchGetBuilds"] }
def x-amz-target-completer-3 [] { ["CodeBuild_20161006.BatchGetProjects"] }
def x-amz-target-completer-4 [] { ["CodeBuild_20161006.BatchGetReportGroups"] }
def x-amz-target-completer-5 [] { ["CodeBuild_20161006.BatchGetReports"] }
def x-amz-target-completer-6 [] { ["CodeBuild_20161006.CreateProject"] }
def type-completer [] { ["CODE_COVERAGE" "TEST"] }
def x-amz-target-completer-7 [] { ["CodeBuild_20161006.CreateReportGroup"] }
def build-type-completer [] { ["BUILD" "BUILD_BATCH"] }
def x-amz-target-completer-8 [] { ["CodeBuild_20161006.CreateWebhook"] }
def x-amz-target-completer-9 [] { ["CodeBuild_20161006.DeleteBuildBatch"] }
def x-amz-target-completer-10 [] { ["CodeBuild_20161006.DeleteProject"] }
def x-amz-target-completer-11 [] { ["CodeBuild_20161006.DeleteReport"] }
def x-amz-target-completer-12 [] { ["CodeBuild_20161006.DeleteReportGroup"] }
def x-amz-target-completer-13 [] { ["CodeBuild_20161006.DeleteResourcePolicy"] }
def x-amz-target-completer-14 [] { ["CodeBuild_20161006.DeleteSourceCredentials"] }
def x-amz-target-completer-15 [] { ["CodeBuild_20161006.DeleteWebhook"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def sort-by-completer [] { ["FILE_PATH" "LINE_COVERAGE_PERCENTAGE"] }
def x-amz-target-completer-16 [] { ["CodeBuild_20161006.DescribeCodeCoverages"] }
def x-amz-target-completer-17 [] { ["CodeBuild_20161006.DescribeTestCases"] }
def trend-field-completer [] { ["BRANCHES_COVERED" "BRANCHES_MISSED" "BRANCH_COVERAGE" "DURATION" "LINES_COVERED" "LINES_MISSED" "LINE_COVERAGE" "PASS_RATE" "TOTAL"] }
def x-amz-target-completer-18 [] { ["CodeBuild_20161006.GetReportGroupTrend"] }
def x-amz-target-completer-19 [] { ["CodeBuild_20161006.GetResourcePolicy"] }
def server-type-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def auth-type-completer [] { ["BASIC_AUTH" "OAUTH" "PERSONAL_ACCESS_TOKEN"] }
def x-amz-target-completer-20 [] { ["CodeBuild_20161006.ImportSourceCredentials"] }
def x-amz-target-completer-21 [] { ["CodeBuild_20161006.InvalidateProjectCache"] }
def x-amz-target-completer-22 [] { ["CodeBuild_20161006.ListBuildBatches"] }
def x-amz-target-completer-23 [] { ["CodeBuild_20161006.ListBuildBatchesForProject"] }
def x-amz-target-completer-24 [] { ["CodeBuild_20161006.ListBuilds"] }
def x-amz-target-completer-25 [] { ["CodeBuild_20161006.ListBuildsForProject"] }
def x-amz-target-completer-26 [] { ["CodeBuild_20161006.ListCuratedEnvironmentImages"] }
def sort-by-completer-1 [] { ["CREATED_TIME" "LAST_MODIFIED_TIME" "NAME"] }
def x-amz-target-completer-27 [] { ["CodeBuild_20161006.ListProjects"] }
def x-amz-target-completer-28 [] { ["CodeBuild_20161006.ListReportGroups"] }
def x-amz-target-completer-29 [] { ["CodeBuild_20161006.ListReports"] }
def x-amz-target-completer-30 [] { ["CodeBuild_20161006.ListReportsForReportGroup"] }
def sort-by-completer-2 [] { ["ARN" "MODIFIED_TIME"] }
def x-amz-target-completer-31 [] { ["CodeBuild_20161006.ListSharedProjects"] }
def x-amz-target-completer-32 [] { ["CodeBuild_20161006.ListSharedReportGroups"] }
def x-amz-target-completer-33 [] { ["CodeBuild_20161006.ListSourceCredentials"] }
def x-amz-target-completer-34 [] { ["CodeBuild_20161006.PutResourcePolicy"] }
def x-amz-target-completer-35 [] { ["CodeBuild_20161006.RetryBuild"] }
def retry-type-completer [] { ["RETRY_ALL_BUILDS" "RETRY_FAILED_BUILDS"] }
def x-amz-target-completer-36 [] { ["CodeBuild_20161006.RetryBuildBatch"] }
def source-type-override-completer [] { ["BITBUCKET" "CODECOMMIT" "CODEPIPELINE" "GITHUB" "GITHUB_ENTERPRISE" "NO_SOURCE" "S3"] }
def environment-type-override-completer [] { ["ARM_CONTAINER" "LINUX_CONTAINER" "LINUX_GPU_CONTAINER" "WINDOWS_CONTAINER" "WINDOWS_SERVER_2019_CONTAINER"] }
def compute-type-override-completer [] { ["BUILD_GENERAL1_2XLARGE" "BUILD_GENERAL1_LARGE" "BUILD_GENERAL1_MEDIUM" "BUILD_GENERAL1_SMALL"] }
def image-pull-credentials-type-override-completer [] { ["CODEBUILD" "SERVICE_ROLE"] }
def x-amz-target-completer-37 [] { ["CodeBuild_20161006.StartBuild"] }
def x-amz-target-completer-38 [] { ["CodeBuild_20161006.StartBuildBatch"] }
def x-amz-target-completer-39 [] { ["CodeBuild_20161006.StopBuild"] }
def x-amz-target-completer-40 [] { ["CodeBuild_20161006.StopBuildBatch"] }
def x-amz-target-completer-41 [] { ["CodeBuild_20161006.UpdateProject"] }
def project-visibility-completer [] { ["PRIVATE" "PUBLIC_READ"] }
def x-amz-target-completer-42 [] { ["CodeBuild_20161006.UpdateProjectVisibility"] }
def x-amz-target-completer-43 [] { ["CodeBuild_20161006.UpdateReportGroup"] }
def x-amz-target-completer-44 [] { ["CodeBuild_20161006.UpdateWebhook"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    batch-delete-builds: "record<buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>"
    batch-get-build-batches: "record<buildBatches: table<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logConfig: record, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list, buildBatchConfig: record, buildGroups: list, debugSessionEnabled: bool>, buildBatchesNotFound: list<string>>"
    batch-get-builds: "record<builds: table<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logs: record, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record, networkInterface: record, encryptionKey: string, exportedEnvironmentVariables: list, reportArns: list, fileSystemLocations: list, debugSession: record, buildBatchArn: string>, buildsNotFound: list<string>>"
    batch-get-projects: "record<projects: table<name: string, arn: string, description: string, source: record, secondarySources: list, sourceVersion: string, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list, created: string, lastModified: string, webhook: record, vpcConfig: record, badge: record, logsConfig: record, fileSystemLocations: list, buildBatchConfig: record, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>, projectsNotFound: list<string>>"
    batch-get-report-groups: "record<reportGroups: table<arn: string, name: string, type: string, exportConfig: record, created: string, lastModified: string, tags: list, status: string>, reportGroupsNotFound: list<string>>"
    batch-get-reports: "record<reports: table<arn: string, type: string, name: string, reportGroupArn: string, executionId: string, status: string, created: string, expired: string, exportConfig: record, truncated: bool, testSummary: record, codeCoverageSummary: record>, reportsNotFound: list<string>>"
    create-project: "record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>"
    create-report-group: "record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>"
    create-webhook: "record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>"
    delete-build-batch: "record<statusCode: string, buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>"
    delete-project: "record"
    delete-report: "record"
    delete-report-group: "record"
    delete-resource-policy: "record"
    delete-source-credentials: "record<arn: string>"
    delete-webhook: "record"
    describe-code-coverages: "record<nextToken: string, codeCoverages: table<id: string, reportARN: string, filePath: string, lineCoveragePercentage: float, linesCovered: int, linesMissed: int, branchCoveragePercentage: float, branchesCovered: int, branchesMissed: int, expired: string>>"
    describe-test-cases: "record<nextToken: string, testCases: table<reportArn: string, testRawDataPath: string, prefix: string, name: string, status: string, durationInNanoSeconds: int, message: string, expired: string>>"
    get-report-group-trend: "record<stats: record<average: string, max: string, min: string>, rawData: table<reportArn: string, data: string>>"
    get-resource-policy: "record<policy: string>"
    import-source-credentials: "record<arn: string>"
    invalidate-project-cache: "record"
    list-build-batches: "record<ids: list<string>, nextToken: string>"
    list-build-batches-for-project: "record<ids: list<string>, nextToken: string>"
    list-builds: "record<ids: list<string>, nextToken: string>"
    list-builds-for-project: "record<ids: list<string>, nextToken: string>"
    list-curated-environment-images: "record<platforms: table<platform: string, languages: list>>"
    list-projects: "record<nextToken: string, projects: list<string>>"
    list-report-groups: "record<nextToken: string, reportGroups: list<string>>"
    list-reports: "record<nextToken: string, reports: list<string>>"
    list-reports-for-report-group: "record<nextToken: string, reports: list<string>>"
    list-shared-projects: "record<nextToken: string, projects: list<string>>"
    list-shared-report-groups: "record<nextToken: string, reportGroups: list<string>>"
    list-source-credentials: "record<sourceCredentialsInfos: table<arn: string, serverType: string, authType: string>>"
    put-resource-policy: "record<resourceArn: string>"
    retry-build: "record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>"
    retry-build-batch: "record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>"
    start-build: "record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>"
    start-build-batch: "record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>"
    stop-build: "record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>"
    stop-build-batch: "record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>"
    update-project: "record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>"
    update-project-visibility: "record<projectArn: string, publicProjectAlias: string, projectVisibility: string>"
    update-report-group: "record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>"
    update-webhook: "record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-delete-builds" "batch-get-build-batches" "batch-get-builds" "batch-get-projects" "batch-get-report-groups" "batch-get-reports" "create-project" "create-report-group" "create-webhook" "delete-build-batch" "delete-project" "delete-report" "delete-report-group" "delete-resource-policy" "delete-source-credentials" "delete-webhook" "describe-code-coverages" "describe-test-cases" "get-report-group-trend" "get-resource-policy" "import-source-credentials" "invalidate-project-cache" "list-build-batches" "list-build-batches-for-project" "list-builds" "list-builds-for-project" "list-curated-environment-images" "list-projects" "list-report-groups" "list-reports" "list-reports-for-report-group" "list-shared-projects" "list-shared-report-groups" "list-source-credentials" "put-resource-policy" "retry-build" "retry-build-batch" "start-build" "start-build-batch" "stop-build" "stop-build-batch" "update-project" "update-project-visibility" "update-report-group" "update-webhook" "commands"] | sort) } | get name | first)
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

# Deletes one or more builds.
#
# POST /
# Returns: record<buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>
# operationId: BatchDeleteBuilds
export def "batch-delete-builds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ids: list<string> # The IDs of the builds to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchDeleteBuilds"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about one or more batch builds.
#
# POST /
# Returns: record<buildBatches: table<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logConfig: record, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list, buildBatchConfig: record, buildGroups: list, debugSessionEnabled: bool>, buildBatchesNotFound: list<string>>
# operationId: BatchGetBuildBatches
export def "batch-get-build-batches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ids: list<string> # An array that contains the batch build identifiers to retrieve.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchGetBuildBatches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more builds.
#
# POST /
# Returns: record<builds: table<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logs: record, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record, networkInterface: record, encryptionKey: string, exportedEnvironmentVariables: list, reportArns: list, fileSystemLocations: list, debugSession: record, buildBatchArn: string>, buildsNotFound: list<string>>
# operationId: BatchGetBuilds
export def "batch-get-builds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ids: list<string> # The IDs of the builds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchGetBuilds"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more build projects.
#
# POST /
# Returns: record<projects: table<name: string, arn: string, description: string, source: record, secondarySources: list, sourceVersion: string, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list, created: string, lastModified: string, webhook: record, vpcConfig: record, badge: record, logsConfig: record, fileSystemLocations: list, buildBatchConfig: record, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>, projectsNotFound: list<string>>
# operationId: BatchGetProjects
export def "batch-get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  names: list<string> # The names or ARNs of the build projects. To get information about a project shared with your Amazon Web Services account, its ARN must be specified. You cannot specify a shared project using its name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchGetProjects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: names, var: names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, names: $names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of report groups.
#
# POST /
# Returns: record<reportGroups: table<arn: string, name: string, type: string, exportConfig: record, created: string, lastModified: string, tags: list, status: string>, reportGroupsNotFound: list<string>>
# operationId: BatchGetReportGroups
export def "batch-get-report-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  report_group_arns: list<string> # An array of report group ARNs that identify the report groups to return.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchGetReportGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportGroupArns, var: report_group_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_group_arns: $report_group_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of reports.
#
# POST /
# Returns: record<reports: table<arn: string, type: string, name: string, reportGroupArn: string, executionId: string, status: string, created: string, expired: string, exportConfig: record, truncated: bool, testSummary: record, codeCoverageSummary: record>, reportsNotFound: list<string>>
# operationId: BatchGetReports
export def "batch-get-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  report_arns: list<string> # An array of ARNs that identify the Report objects to return.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.BatchGetReports"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportArns, var: report_arns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_arns: $report_arns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a build project.
#
# POST /
# Returns: record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>
# operationId: CreateProject
export def "create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the build project.
  --description: string # A description that makes the build project easy to identify.
  source: record # Information about the build input source code for the build project. — shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --source-version: string # A version of the build input to be built for this project. If not specified, the latest version is used. If specified, it must be one of: For CodeCommit: the commit ID, branch, or Git tag to use. For GitHub: the commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Bitbucket: the commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Amazon S3: the version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the build level, then that version takes precedence over this sourceVersion (at the project level). For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --secondary-source-versions: list # An array of ProjectSourceVersion objects. If secondarySourceVersions is specified at the build level, then they take precedence over these secondarySourceVersions (at the project level). — item shape: {sourceIdentifier: string, sourceVersion: string}
  artifacts: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts: list # An array of ProjectArtifacts objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --cache: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  environment: record # Information about the build environment of the build project. — shape: {type: "WINDOWS_CONTAINER"|"LINUX_CONTAINER"|"LINUX_GPU_CONTAINER"|"ARM_CONTAINER"|"WINDOWS_SERVER_2019_CONTAINER", image: string, computeType: "BUILD_GENERAL1_SMALL"|"BUILD_GENERAL1_MEDIUM"|"BUILD_GENERAL1_LARGE"|"BUILD_GENERAL1_2XLARGE", environmentVariables?: list, privilegedMode?: bool, certificate?: string, registryCredential?: record, imagePullCredentialsType?: "CODEBUILD"|"SERVICE_ROLE"}
  service_role: string # The ARN of the IAM role that enables CodeBuild to interact with dependent Amazon Web Services services on behalf of the Amazon Web Services account.
  --timeout-in-minutes: int # How long, in minutes, from 5 to 480 (8 hours), for CodeBuild to wait before it times out any build that has not been marked as completed. The default is 60 minutes.
  --queued-timeout-in-minutes: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key: string # The Key Management Service customer master key (CMK) to be used for encrypting the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --tags: list # A list of tag key and value pairs associated with this build project. These tags are available for use by Amazon Web Services services that support CodeBuild build project tags. — item shape: {key?: string, value?: string}
  --vpc-config: record # Information about the VPC configuration that CodeBuild accesses. — shape: {vpcId?: string, subnets?: list<string>, securityGroupIds?: list<string>}
  --badge-enabled: oneof<nothing, bool> # Set this to true to generate a publicly accessible URL for your project's build badge.
  --logs-config: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --file-system-locations: list # An array of ProjectFileSystemLocation objects for a CodeBuild build project. A ProjectFileSystemLocation object specifies the identifier, location, mountOptions, mountPoint, and type of a file system created using Amazon Elastic File System. — item shape: {type?: "EFS", location?: string, mountPoint?: string, identifier?: string, mountOptions?: string}
  --build-batch-config: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --concurrent-build-limit: int # The maximum number of concurrent builds that are allowed for this project. New builds are only started if the current number of builds is less than or equal to this limit. If the current build count meets this limit, new builds are throttled and are not run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.CreateProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: source, var: source}, {name: secondarySources, var: secondary_sources}, {name: sourceVersion, var: source_version}, {name: secondarySourceVersions, var: secondary_source_versions}, {name: artifacts, var: artifacts}, {name: secondaryArtifacts, var: secondary_artifacts}, {name: cache, var: cache}, {name: environment, var: environment}, {name: serviceRole, var: service_role}, {name: timeoutInMinutes, var: timeout_in_minutes}, {name: queuedTimeoutInMinutes, var: queued_timeout_in_minutes}, {name: encryptionKey, var: encryption_key}, {name: tags, var: tags}, {name: vpcConfig, var: vpc_config}, {name: badgeEnabled, var: badge_enabled}, {name: logsConfig, var: logs_config}, {name: fileSystemLocations, var: file_system_locations}, {name: buildBatchConfig, var: build_batch_config}, {name: concurrentBuildLimit, var: concurrent_build_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, source: $source, secondary_sources: $secondary_sources, source_version: $source_version, secondary_source_versions: $secondary_source_versions, artifacts: $artifacts, secondary_artifacts: $secondary_artifacts, cache: $cache, environment: $environment, service_role: $service_role, timeout_in_minutes: $timeout_in_minutes, queued_timeout_in_minutes: $queued_timeout_in_minutes, encryption_key: $encryption_key, tags: $tags, vpc_config: $vpc_config, badge_enabled: $badge_enabled, logs_config: $logs_config, file_system_locations: $file_system_locations, build_batch_config: $build_batch_config, concurrent_build_limit: $concurrent_build_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a report group. A report group contains a collection of reports.
#
# POST /
# Returns: record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>
# operationId: CreateReportGroup
export def "create-report-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the report group.
  type: string@type-completer # The type of report group.
  export_config: record # Information about the location where the run of a report is exported. — shape: {exportConfigType?: "S3"|"NO_EXPORT", s3Destination?: record}
  --tags: list # A list of tag key and value pairs associated with this report group. These tags are available for use by Amazon Web Services services that support CodeBuild report group tags. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.CreateReportGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}, {name: exportConfig, var: export_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, type: $type, export_config: $export_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables CodeBuild to start rebuilding the source code every time a code change is pushed to the repository. If you enable webhooks for an CodeBuild project, and the project is used as a build step in CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using CodePipeline, we recommend that you disable webhooks in CodeBuild. In the CodeBuild console, clear the Webhook box. For more information, see step 5 in Change a Build Project's Settings (https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console).
#
# POST /
# Returns: record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>
# operationId: CreateWebhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the CodeBuild project.
  --branch-filter: string # A regular expression used to determine which repository branches are built when a webhook is triggered. If the name of a branch matches the regular expression, then it is built. If branchFilter is empty, then all branches are built. It is recommended that you use filterGroups instead of branchFilter.
  --filter-groups: list # An array of arrays of WebhookFilter objects used to determine which webhooks are triggered. At least one WebhookFilter in the array must specify EVENT as its type. For a build to be triggered, at least one filter group in the filterGroups array must pass. For a filter group to pass, each of its filters must pass.
  --build-type: string@build-type-completer # Specifies the type of build this webhook will trigger.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.CreateWebhook"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: branchFilter, var: branch_filter}, {name: filterGroups, var: filter_groups}, {name: buildType, var: build_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, branch_filter: $branch_filter, filter_groups: $filter_groups, build_type: $build_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a batch build.
#
# POST /
# Returns: record<statusCode: string, buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>
# operationId: DeleteBuildBatch
export def "delete-build-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the batch build to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteBuildBatch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a build project. When you delete a project, its builds are not deleted.
#
# POST /
# Returns: record
# operationId: DeleteProject
export def "delete-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the build project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a report.
#
# POST /
# Returns: record
# operationId: DeleteReport
export def "delete-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The ARN of the report to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteReport"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a report group. Before you delete a report group, you must delete its reports.
#
# POST /
# Returns: record
# operationId: DeleteReportGroup
export def "delete-report-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The ARN of the report group to delete.
  --delete-reports: oneof<nothing, bool> # If true, deletes any reports that belong to a report group before deleting the report group. If false, you must delete any reports in the report group. Use ListReportsForReportGroup (https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html) to get the reports in a report group. Use DeleteReport (https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html) to delete the reports. If you call DeleteReportGroup for a report group that contains one or more reports, an exception is thrown.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteReportGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: deleteReports, var: delete_reports}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, delete_reports: $delete_reports
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource policy that is identified by its resource ARN.
#
# POST /
# Returns: record
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The ARN of the resource that is associated with the resource policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.
#
# POST /
# Returns: record<arn: string>
# operationId: DeleteSourceCredentials
export def "delete-source-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The Amazon Resource Name (ARN) of the token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteSourceCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
#
# POST /
# Returns: record
# operationId: DeleteWebhook
export def "delete-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the CodeBuild project.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DeleteWebhook"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves one or more code coverage reports.
#
# POST /
# Returns: record<nextToken: string, codeCoverages: table<id: string, reportARN: string, filePath: string, lineCoveragePercentage: float, linesCovered: int, linesMissed: int, branchCoveragePercentage: float, branchesCovered: int, branchesMissed: int, expired: string>>
# operationId: DescribeCodeCoverages
export def "describe-code-coverages" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  report_arn: string # The ARN of the report for which test cases are returned.
  --body-next-token: string # The nextToken value returned from a previous call to DescribeCodeCoverages. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (spec name: nextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: maxResults)
  --sort-order: string@sort-order-completer # Specifies if the results are sorted in ascending or descending order.
  --sort-by: string@sort-by-completer # Specifies how the results are sorted. Possible values are: FILE_PATH The results are sorted by file path. LINE_COVERAGE_PERCENTAGE The results are sorted by the percentage of lines that are covered.
  --min-line-coverage-percentage: float # The minimum line coverage percentage to report. (format: double)
  --max-line-coverage-percentage: float # The maximum line coverage percentage to report. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DescribeCodeCoverages"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportArn, var: report_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: sortOrder, var: sort_order}, {name: sortBy, var: sort_by}, {name: minLineCoveragePercentage, var: min_line_coverage_percentage}, {name: maxLineCoveragePercentage, var: max_line_coverage_percentage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_arn: $report_arn, body_next_token: $body_next_token, body_max_results: $body_max_results, sort_order: $sort_order, sort_by: $sort_by, min_line_coverage_percentage: $min_line_coverage_percentage, max_line_coverage_percentage: $max_line_coverage_percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of details about test cases for a report.
#
# POST /
# Returns: record<nextToken: string, testCases: table<reportArn: string, testRawDataPath: string, prefix: string, name: string, status: string, durationInNanoSeconds: int, message: string, expired: string>>
# operationId: DescribeTestCases
export def "describe-test-cases" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  report_arn: string # The ARN of the report for which test cases are returned.
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
  --body-max-results: int # The maximum number of paginated test cases returned per response. Use nextToken to iterate pages in the list of returned TestCase objects. The default value is 100. (spec name: maxResults)
  --filter: record # A filter used to return specific types of test cases. In order to pass the filter, the report must meet all of the filter properties. — shape: {status?: string, keyword?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.DescribeTestCases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportArn, var: report_arn}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_arn: $report_arn, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyzes and accumulates test report values for the specified test reports.
#
# POST /
# Returns: record<stats: record<average: string, max: string, min: string>, rawData: table<reportArn: string, data: string>>
# operationId: GetReportGroupTrend
export def "get-report-group-trend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  report_group_arn: string # The ARN of the report group that contains the reports to analyze.
  --num-of-reports: int # The number of reports to analyze. This operation always retrieves the most recent reports. If this parameter is omitted, the most recent 100 reports are analyzed.
  trend_field: string@trend-field-completer # The test report value to accumulate. This must be one of the following values: Test reports: DURATION Accumulate the test run times for the specified reports. PASS_RATE Accumulate the percentage of tests that passed for the specified test reports. TOTAL Accumulate the total number of tests for the specified test reports. Code coverage reports: BRANCH_COVERAGE Accumulate the branch coverage percentages for the specified test reports. BRANCHES_COVERED Accumulate the branches covered values for the specified test reports. BRANCHES_MISSED Accumulate the branches missed values for the specified test reports. LINE_COVERAGE Accumulate the line coverage percentages for the specified test reports. LINES_COVERED Accumulate the lines covered values for the specified test reports. LINES_MISSED Accumulate the lines not covered values for the specified test reports.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.GetReportGroupTrend"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportGroupArn, var: report_group_arn}, {name: numOfReports, var: num_of_reports}, {name: trendField, var: trend_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_group_arn: $report_group_arn, num_of_reports: $num_of_reports, trend_field: $trend_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a resource policy that is identified by its resource ARN.
#
# POST /
# Returns: record<policy: string>
# operationId: GetResourcePolicy
export def "get-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: string # The ARN of the resource that is associated with the resource policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.GetResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports the source repository credentials for an CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.
#
# POST /
# Returns: record<arn: string>
# operationId: ImportSourceCredentials
export def "import-source-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --username: string # The Bitbucket username when the authType is BASIC_AUTH. This parameter is not valid for other types of source providers or connections.
  --body-token: string # For GitHub or GitHub Enterprise, this is the personal access token. For Bitbucket, this is the app password. (format: password) (spec name: token)
  server_type: string@server-type-completer # The source provider used for this project.
  auth_type: string@auth-type-completer # The type of authentication used to connect to a GitHub, GitHub Enterprise, or Bitbucket repository. An OAUTH connection is not supported by the API and must be created using the CodeBuild console.
  --should-overwrite: oneof<nothing, bool> # Set to false to prevent overwriting the repository source credentials. Set to true to overwrite the repository source credentials. The default value is true.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ImportSourceCredentials"}]
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}, {name: token, var: body_token, required: true}, {name: serverType, var: server_type}, {name: authType, var: auth_type}, {name: shouldOverwrite, var: should_overwrite}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, username: $username, body_token: $body_token, server_type: $server_type, auth_type: $auth_type, should_overwrite: $should_overwrite
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the cache for a project.
#
# POST /
# Returns: record
# operationId: InvalidateProjectCache
export def "invalidate-project-cache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the CodeBuild build project that the cache is reset for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.InvalidateProjectCache"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the identifiers of your build batches in the current region.
#
# POST /
# Returns: record<ids: list<string>, nextToken: string>
# operationId: ListBuildBatches
export def "list-build-batches" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  --filter: record # Specifies filters when retrieving batch builds. — shape: {status?: "SUCCEEDED"|"FAILED"|"FAULT"|"TIMED_OUT"|"IN_PROGRESS"|"STOPPED"}
  --body-max-results: int # The maximum number of results to return. (spec name: maxResults)
  --sort-order: string@sort-order-completer # Specifies the sort order of the returned items. Valid values include: ASCENDING: List the batch build identifiers in ascending order by identifier. DESCENDING: List the batch build identifiers in descending order by identifier.
  --body-next-token: string # The nextToken value returned from a previous call to ListBuildBatches. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListBuildBatches"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}, {name: maxResults, var: body_max_results}, {name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_max_results: $body_max_results, sort_order: $sort_order, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the identifiers of the build batches for a specific project.
#
# POST /
# Returns: record<ids: list<string>, nextToken: string>
# operationId: ListBuildBatchesForProject
export def "list-build-batches-for-project" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  --project-name: string # The name of the project.
  --filter: record # Specifies filters when retrieving batch builds. — shape: {status?: "SUCCEEDED"|"FAILED"|"FAULT"|"TIMED_OUT"|"IN_PROGRESS"|"STOPPED"}
  --body-max-results: int # The maximum number of results to return. (spec name: maxResults)
  --sort-order: string@sort-order-completer # Specifies the sort order of the returned items. Valid values include: ASCENDING: List the batch build identifiers in ascending order by identifier. DESCENDING: List the batch build identifiers in descending order by identifier.
  --body-next-token: string # The nextToken value returned from a previous call to ListBuildBatchesForProject. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListBuildBatchesForProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: filter, var: filter}, {name: maxResults, var: body_max_results}, {name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, filter: $filter, body_max_results: $body_max_results, sort_order: $sort_order, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of build IDs, with each build ID representing a single build.
#
# POST /
# Returns: record<ids: list<string>, nextToken: string>
# operationId: ListBuilds
export def "list-builds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --sort-order: string@sort-order-completer # The order to list build IDs. Valid values include: ASCENDING: List the build IDs in ascending order by build ID. DESCENDING: List the build IDs in descending order by build ID.
  --body-next-token: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListBuilds"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_order: $sort_order, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of build identifiers for the specified build project, with each build identifier representing a single build.
#
# POST /
# Returns: record<ids: list<string>, nextToken: string>
# operationId: ListBuildsForProject
export def "list-builds-for-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  project_name: string # The name of the CodeBuild project.
  --sort-order: string@sort-order-completer # The order to sort the results in. The results are sorted by build number, not the build identifier. If this is not specified, the results are sorted in descending order. Valid values include: ASCENDING: List the build identifiers in ascending order, by build number. DESCENDING: List the build identifiers in descending order, by build number. If the project has more than 100 builds, setting the sort order will result in an error.
  --body-next-token: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListBuildsForProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, sort_order: $sort_order, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about Docker images that are managed by CodeBuild.
#
# POST /
# Returns: record<platforms: table<platform: string, languages: list>>
# operationId: ListCuratedEnvironmentImages
export def "list-curated-environment-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListCuratedEnvironmentImages"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of build project names, with each build project name representing a single build project.
#
# POST /
# Returns: record<nextToken: string, projects: list<string>>
# operationId: ListProjects
export def "list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --sort-by: string@sort-by-completer-1 # The criterion to be used to list build project names. Valid values include: CREATED_TIME: List based on when each build project was created. LAST_MODIFIED_TIME: List based on when information about each build project was last changed. NAME: List based on each build project's name. Use sortOrder to specify in what order to list the build project names based on the preceding criteria.
  --sort-order: string@sort-order-completer # The order in which to list build projects. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order. Use sortBy to specify the criterion to be used to list build project names.
  --body-next-token: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListProjects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_by: $sort_by, sort_order: $sort_order, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list ARNs for the report groups in the current Amazon Web Services account.
#
# POST /
# Returns: record<nextToken: string, reportGroups: list<string>>
# operationId: ListReportGroups
export def "list-report-groups" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --sort-order: string@sort-order-completer # Used to specify the order to sort the list of returned report groups. Valid values are ASCENDING and DESCENDING.
  --sort-by: string@sort-by-completer-1 # The criterion to be used to list build report groups. Valid values include: CREATED_TIME: List based on when each report group was created. LAST_MODIFIED_TIME: List based on when each report group was last changed. NAME: List based on each report group's name.
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
  --body-max-results: int # The maximum number of paginated report groups returned per response. Use nextToken to iterate pages in the list of returned ReportGroup objects. The default value is 100. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListReportGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortOrder, var: sort_order}, {name: sortBy, var: sort_by}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_order: $sort_order, sort_by: $sort_by, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of ARNs for the reports in the current Amazon Web Services account.
#
# POST /
# Returns: record<nextToken: string, reports: list<string>>
# operationId: ListReports
export def "list-reports" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  --sort-order: string@sort-order-completer # Specifies the sort order for the list of returned reports. Valid values are: ASCENDING: return reports in chronological order based on their creation date. DESCENDING: return reports in the reverse chronological order based on their creation date.
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
  --body-max-results: int # The maximum number of paginated reports returned per response. Use nextToken to iterate pages in the list of returned Report objects. The default value is 100. (spec name: maxResults)
  --filter: record # A filter used to return reports with the status specified by the input status parameter. — shape: {status?: "GENERATING"|"SUCCEEDED"|"FAILED"|"INCOMPLETE"|"DELETING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListReports"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortOrder, var: sort_order}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}, {name: filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_order: $sort_order, body_next_token: $body_next_token, body_max_results: $body_max_results, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of ARNs for the reports that belong to a ReportGroup.
#
# POST /
# Returns: record<nextToken: string, reports: list<string>>
# operationId: ListReportsForReportGroup
export def "list-reports-for-report-group" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  report_group_arn: string # The ARN of the report group for which you want to return report ARNs.
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
  --sort-order: string@sort-order-completer # Use to specify whether the results are returned in ascending or descending order.
  --body-max-results: int # The maximum number of paginated reports in this report group returned per response. Use nextToken to iterate pages in the list of returned Report objects. The default value is 100. (spec name: maxResults)
  --filter: record # A filter used to return reports with the status specified by the input status parameter. — shape: {status?: "GENERATING"|"SUCCEEDED"|"FAILED"|"INCOMPLETE"|"DELETING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListReportsForReportGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: reportGroupArn, var: report_group_arn}, {name: nextToken, var: body_next_token}, {name: sortOrder, var: sort_order}, {name: maxResults, var: body_max_results}, {name: filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, report_group_arn: $report_group_arn, body_next_token: $body_next_token, sort_order: $sort_order, body_max_results: $body_max_results, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of projects that are shared with other Amazon Web Services accounts or users.
#
# POST /
# Returns: record<nextToken: string, projects: list<string>>
# operationId: ListSharedProjects
export def "list-shared-projects" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  --sort-by: string@sort-by-completer-2 # The criterion to be used to list build projects shared with the current Amazon Web Services account or user. Valid values include: ARN: List based on the ARN. MODIFIED_TIME: List based on when information about the shared project was last changed.
  --sort-order: string@sort-order-completer # The order in which to list shared build projects. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order.
  --body-max-results: int # The maximum number of paginated shared build projects returned per response. Use nextToken to iterate pages in the list of returned Project objects. The default value is 100. (spec name: maxResults)
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListSharedProjects"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_by: $sort_by, sort_order: $sort_order, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of report groups that are shared with other Amazon Web Services accounts or users.
#
# POST /
# Returns: record<nextToken: string, reportGroups: list<string>>
# operationId: ListSharedReportGroups
export def "list-shared-report-groups" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  --sort-order: string@sort-order-completer # The order in which to list shared report groups. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order.
  --sort-by: string@sort-by-completer-2 # The criterion to be used to list report groups shared with the current Amazon Web Services account or user. Valid values include: ARN: List based on the ARN. MODIFIED_TIME: List based on when information about the shared report group was last changed.
  --body-next-token: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (spec name: nextToken)
  --body-max-results: int # The maximum number of paginated shared report groups per response. Use nextToken to iterate pages in the list of returned ReportGroup objects. The default value is 100. (spec name: maxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListSharedReportGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: sortOrder, var: sort_order}, {name: sortBy, var: sort_by}, {name: nextToken, var: body_next_token}, {name: maxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, sort_order: $sort_order, sort_by: $sort_by, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of SourceCredentialsInfo objects.
#
# POST /
# Returns: record<sourceCredentialsInfos: table<arn: string, serverType: string, authType: string>>
# operationId: ListSourceCredentials
export def "list-source-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.ListSourceCredentials"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stores a resource policy for the ARN of a Project or ReportGroup object.
#
# POST /
# Returns: record<resourceArn: string>
# operationId: PutResourcePolicy
export def "put-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  policy: string # A JSON-formatted resource policy. For more information, see Sharing a Project (https://docs.aws.amazon.com/codebuild/latest/userguide/project-sharing.html#project-sharing-share) and Sharing a Report Group (https://docs.aws.amazon.com/codebuild/latest/userguide/report-groups-sharing.html#report-groups-sharing-share) in the CodeBuild User Guide.
  resource_arn: string # The ARN of the Project or ReportGroup resource you want to associate with a resource policy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy: $policy, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a build.
#
# POST /
# Returns: record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>
# operationId: RetryBuild
export def "retry-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --id: string # Specifies the identifier of the build to restart.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.RetryBuild"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts a failed batch build. Only batch builds that have failed can be retried.
#
# POST /
# Returns: record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>
# operationId: RetryBuildBatch
export def "retry-build-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --id: string # Specifies the identifier of the batch build to restart.
  --retry-type: string@retry-type-completer # Specifies the type of retry to perform.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.RetryBuildBatch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: retryType, var: retry_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, retry_type: $retry_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts running a build.
#
# POST /
# Returns: record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>
# operationId: StartBuild
export def "start-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the CodeBuild build project to start running a build.
  --secondary-sources-override: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources-version-override: list # An array of ProjectSourceVersion objects that specify one or more versions of the project's secondary sources to be used for this build only. — item shape: {sourceIdentifier: string, sourceVersion: string}
  --source-version: string # The version of the build input to be built, for this build only. If not specified, the latest version is used. If specified, the contents depends on the source provider: CodeCommit The commit ID, branch, or Git tag to use. GitHub The commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Bitbucket The commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Amazon S3 The version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the project level, then this sourceVersion (at the build level) takes precedence. For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --artifacts-override: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts-override: list # An array of ProjectArtifacts objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --environment-variables-override: list # A set of environment variables that overrides, for this build only, the latest ones already defined in the build project. — item shape: {name: string, value: string, type?: "PLAINTEXT"|"PARAMETER_STORE"|"SECRETS_MANAGER"}
  --source-type-override: string@source-type-override-completer # A source input type, for this build, that overrides the source input defined in the build project.
  --source-location-override: string # A location that overrides, for this build, the source location for the one defined in the build project.
  --source-auth-override: record # Information about the authorization settings for CodeBuild to access the source code to be built. This information is for the CodeBuild console's use only. Your code should not get or set this information directly. — shape: {type: "OAUTH", resource?: string}
  --git-clone-depth-override: int # The user-defined depth of history, with a minimum value of 0, that overrides, for this build only, any previous depth of history defined in the build project.
  --git-submodules-config-override: record # Information about the Git submodules configuration for an CodeBuild build project. — shape: {fetchSubmodules: bool}
  --buildspec-override: string # A buildspec file declaration that overrides, for this build only, the latest one already defined in the build project. If this value is set, it can be either an inline buildspec definition, the path to an alternate buildspec file relative to the value of the built-in CODEBUILD_SRC_DIR environment variable, or the path to an S3 bucket. The bucket must be in the same Amazon Web Services Region as the build project. Specify the buildspec file using its ARN (for example, arn:aws:s3:::my-codebuild-sample2/buildspec.yml). If this value is not provided or is set to an empty string, the source code must contain a buildspec file in its root directory. For more information, see Buildspec File Name and Storage Location (https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-name-storage).
  --insecure-ssl-override: oneof<nothing, bool> # Enable this flag to override the insecure SSL setting that is specified in the build project. The insecure SSL setting determines whether to ignore SSL warnings while connecting to the project source code. This override applies only if the build's source is GitHub Enterprise.
  --report-build-status-override: oneof<nothing, bool> # Set to true to report to your source provider the status of a build's start and completion. If you use this option with a source provider other than GitHub, GitHub Enterprise, or Bitbucket, an invalidInputException is thrown. To be able to report the build status to the source provider, the user associated with the source provider must have write access to the repo. If the user does not have write access, the build status cannot be updated. For more information, see Source provider access (https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens.html) in the CodeBuild User Guide. The status of a build triggered by a webhook is always reported to your source provider.
  --build-status-config-override: record # Contains information that defines how the CodeBuild build project reports the build status to the source provider. — shape: {context?: string, targetUrl?: string}
  --environment-type-override: string@environment-type-override-completer # A container type for this build that overrides the one specified in the build project.
  --image-override: string # The name of an image for this build that overrides the one specified in the build project.
  --compute-type-override: string@compute-type-override-completer # The name of a compute type for this build that overrides the one specified in the build project.
  --certificate-override: string # The name of a certificate for this build that overrides the one specified in the build project.
  --cache-override: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --service-role-override: string # The name of a service role for this build that overrides the one specified in the build project.
  --privileged-mode-override: oneof<nothing, bool> # Enable this flag to override privileged mode in the build project.
  --timeout-in-minutes-override: int # The number of build timeout minutes, from 5 to 480 (8 hours), that overrides, for this build only, the latest setting already defined in the build project.
  --queued-timeout-in-minutes-override: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key-override: string # The Key Management Service customer master key (CMK) that overrides the one specified in the build project. The CMK key encrypts the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --logs-config-override: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --registry-credential-override: record # Information about credentials that provide access to a private Docker registry. When this is set: imagePullCredentialsType must be set to SERVICE_ROLE. images cannot be curated or an Amazon ECR image. For more information, see Private Registry with Secrets Manager Sample for CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-private-registry.html). — shape: {credential: string, credentialProvider: "SECRETS_MANAGER"}
  --image-pull-credentials-type-override: string@image-pull-credentials-type-override-completer # The type of credentials CodeBuild uses to pull images in your build. There are two valid values: CODEBUILD Specifies that CodeBuild uses its own credentials. This requires that you modify your ECR repository policy to trust CodeBuild's service principal. SERVICE_ROLE Specifies that CodeBuild uses your build project's service role. When using a cross-account or private registry image, you must use SERVICE_ROLE credentials. When using an CodeBuild curated image, you must use CODEBUILD credentials.
  --debug-session-enabled: oneof<nothing, bool> # Specifies if session debugging is enabled for this build. For more information, see Viewing a running build in Session Manager (https://docs.aws.amazon.com/codebuild/latest/userguide/session-manager.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.StartBuild"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: secondarySourcesOverride, var: secondary_sources_override}, {name: secondarySourcesVersionOverride, var: secondary_sources_version_override}, {name: sourceVersion, var: source_version}, {name: artifactsOverride, var: artifacts_override}, {name: secondaryArtifactsOverride, var: secondary_artifacts_override}, {name: environmentVariablesOverride, var: environment_variables_override}, {name: sourceTypeOverride, var: source_type_override}, {name: sourceLocationOverride, var: source_location_override}, {name: sourceAuthOverride, var: source_auth_override}, {name: gitCloneDepthOverride, var: git_clone_depth_override}, {name: gitSubmodulesConfigOverride, var: git_submodules_config_override}, {name: buildspecOverride, var: buildspec_override}, {name: insecureSslOverride, var: insecure_ssl_override}, {name: reportBuildStatusOverride, var: report_build_status_override}, {name: buildStatusConfigOverride, var: build_status_config_override}, {name: environmentTypeOverride, var: environment_type_override}, {name: imageOverride, var: image_override}, {name: computeTypeOverride, var: compute_type_override}, {name: certificateOverride, var: certificate_override}, {name: cacheOverride, var: cache_override}, {name: serviceRoleOverride, var: service_role_override}, {name: privilegedModeOverride, var: privileged_mode_override}, {name: timeoutInMinutesOverride, var: timeout_in_minutes_override}, {name: queuedTimeoutInMinutesOverride, var: queued_timeout_in_minutes_override}, {name: encryptionKeyOverride, var: encryption_key_override}, {name: logsConfigOverride, var: logs_config_override}, {name: registryCredentialOverride, var: registry_credential_override}, {name: imagePullCredentialsTypeOverride, var: image_pull_credentials_type_override}, {name: debugSessionEnabled, var: debug_session_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, secondary_sources_override: $secondary_sources_override, secondary_sources_version_override: $secondary_sources_version_override, source_version: $source_version, artifacts_override: $artifacts_override, secondary_artifacts_override: $secondary_artifacts_override, environment_variables_override: $environment_variables_override, source_type_override: $source_type_override, source_location_override: $source_location_override, source_auth_override: $source_auth_override, git_clone_depth_override: $git_clone_depth_override, git_submodules_config_override: $git_submodules_config_override, buildspec_override: $buildspec_override, insecure_ssl_override: $insecure_ssl_override, report_build_status_override: $report_build_status_override, build_status_config_override: $build_status_config_override, environment_type_override: $environment_type_override, image_override: $image_override, compute_type_override: $compute_type_override, certificate_override: $certificate_override, cache_override: $cache_override, service_role_override: $service_role_override, privileged_mode_override: $privileged_mode_override, timeout_in_minutes_override: $timeout_in_minutes_override, queued_timeout_in_minutes_override: $queued_timeout_in_minutes_override, encryption_key_override: $encryption_key_override, logs_config_override: $logs_config_override, registry_credential_override: $registry_credential_override, image_pull_credentials_type_override: $image_pull_credentials_type_override, debug_session_enabled: $debug_session_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a batch build for a project.
#
# POST /
# Returns: record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>
# operationId: StartBuildBatch
export def "start-build-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the project.
  --secondary-sources-override: list # An array of ProjectSource objects that override the secondary sources defined in the batch build project. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources-version-override: list # An array of ProjectSourceVersion objects that override the secondary source versions in the batch build project. — item shape: {sourceIdentifier: string, sourceVersion: string}
  --source-version: string # The version of the batch build input to be built, for this build only. If not specified, the latest version is used. If specified, the contents depends on the source provider: CodeCommit The commit ID, branch, or Git tag to use. GitHub The commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Bitbucket The commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Amazon S3 The version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the project level, then this sourceVersion (at the build level) takes precedence. For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --artifacts-override: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts-override: list # An array of ProjectArtifacts objects that override the secondary artifacts defined in the batch build project. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --environment-variables-override: list # An array of EnvironmentVariable objects that override, or add to, the environment variables defined in the batch build project. — item shape: {name: string, value: string, type?: "PLAINTEXT"|"PARAMETER_STORE"|"SECRETS_MANAGER"}
  --source-type-override: string@source-type-override-completer # The source input type that overrides the source input defined in the batch build project.
  --source-location-override: string # A location that overrides, for this batch build, the source location defined in the batch build project.
  --source-auth-override: record # Information about the authorization settings for CodeBuild to access the source code to be built. This information is for the CodeBuild console's use only. Your code should not get or set this information directly. — shape: {type: "OAUTH", resource?: string}
  --git-clone-depth-override: int # The user-defined depth of history, with a minimum value of 0, that overrides, for this batch build only, any previous depth of history defined in the batch build project.
  --git-submodules-config-override: record # Information about the Git submodules configuration for an CodeBuild build project. — shape: {fetchSubmodules: bool}
  --buildspec-override: string # A buildspec file declaration that overrides, for this build only, the latest one already defined in the build project. If this value is set, it can be either an inline buildspec definition, the path to an alternate buildspec file relative to the value of the built-in CODEBUILD_SRC_DIR environment variable, or the path to an S3 bucket. The bucket must be in the same Amazon Web Services Region as the build project. Specify the buildspec file using its ARN (for example, arn:aws:s3:::my-codebuild-sample2/buildspec.yml). If this value is not provided or is set to an empty string, the source code must contain a buildspec file in its root directory. For more information, see Buildspec File Name and Storage Location (https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-name-storage).
  --insecure-ssl-override: oneof<nothing, bool> # Enable this flag to override the insecure SSL setting that is specified in the batch build project. The insecure SSL setting determines whether to ignore SSL warnings while connecting to the project source code. This override applies only if the build's source is GitHub Enterprise.
  --report-build-batch-status-override: oneof<nothing, bool> # Set to true to report to your source provider the status of a batch build's start and completion. If you use this option with a source provider other than GitHub, GitHub Enterprise, or Bitbucket, an invalidInputException is thrown. The status of a build triggered by a webhook is always reported to your source provider.
  --environment-type-override: string@environment-type-override-completer # A container type for this batch build that overrides the one specified in the batch build project.
  --image-override: string # The name of an image for this batch build that overrides the one specified in the batch build project.
  --compute-type-override: string@compute-type-override-completer # The name of a compute type for this batch build that overrides the one specified in the batch build project.
  --certificate-override: string # The name of a certificate for this batch build that overrides the one specified in the batch build project.
  --cache-override: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --service-role-override: string # The name of a service role for this batch build that overrides the one specified in the batch build project.
  --privileged-mode-override: oneof<nothing, bool> # Enable this flag to override privileged mode in the batch build project.
  --build-timeout-in-minutes-override: int # Overrides the build timeout specified in the batch build project.
  --queued-timeout-in-minutes-override: int # The number of minutes a batch build is allowed to be queued before it times out.
  --encryption-key-override: string # The Key Management Service customer master key (CMK) that overrides the one specified in the batch build project. The CMK key encrypts the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --logs-config-override: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --registry-credential-override: record # Information about credentials that provide access to a private Docker registry. When this is set: imagePullCredentialsType must be set to SERVICE_ROLE. images cannot be curated or an Amazon ECR image. For more information, see Private Registry with Secrets Manager Sample for CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-private-registry.html). — shape: {credential: string, credentialProvider: "SECRETS_MANAGER"}
  --image-pull-credentials-type-override: string@image-pull-credentials-type-override-completer # The type of credentials CodeBuild uses to pull images in your batch build. There are two valid values: CODEBUILD Specifies that CodeBuild uses its own credentials. This requires that you modify your ECR repository policy to trust CodeBuild's service principal. SERVICE_ROLE Specifies that CodeBuild uses your build project's service role. When using a cross-account or private registry image, you must use SERVICE_ROLE credentials. When using an CodeBuild curated image, you must use CODEBUILD credentials.
  --build-batch-config-override: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --debug-session-enabled: oneof<nothing, bool> # Specifies if session debugging is enabled for this batch build. For more information, see Viewing a running build in Session Manager (https://docs.aws.amazon.com/codebuild/latest/userguide/session-manager.html). Batch session debugging is not supported for matrix batch builds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.StartBuildBatch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: secondarySourcesOverride, var: secondary_sources_override}, {name: secondarySourcesVersionOverride, var: secondary_sources_version_override}, {name: sourceVersion, var: source_version}, {name: artifactsOverride, var: artifacts_override}, {name: secondaryArtifactsOverride, var: secondary_artifacts_override}, {name: environmentVariablesOverride, var: environment_variables_override}, {name: sourceTypeOverride, var: source_type_override}, {name: sourceLocationOverride, var: source_location_override}, {name: sourceAuthOverride, var: source_auth_override}, {name: gitCloneDepthOverride, var: git_clone_depth_override}, {name: gitSubmodulesConfigOverride, var: git_submodules_config_override}, {name: buildspecOverride, var: buildspec_override}, {name: insecureSslOverride, var: insecure_ssl_override}, {name: reportBuildBatchStatusOverride, var: report_build_batch_status_override}, {name: environmentTypeOverride, var: environment_type_override}, {name: imageOverride, var: image_override}, {name: computeTypeOverride, var: compute_type_override}, {name: certificateOverride, var: certificate_override}, {name: cacheOverride, var: cache_override}, {name: serviceRoleOverride, var: service_role_override}, {name: privilegedModeOverride, var: privileged_mode_override}, {name: buildTimeoutInMinutesOverride, var: build_timeout_in_minutes_override}, {name: queuedTimeoutInMinutesOverride, var: queued_timeout_in_minutes_override}, {name: encryptionKeyOverride, var: encryption_key_override}, {name: logsConfigOverride, var: logs_config_override}, {name: registryCredentialOverride, var: registry_credential_override}, {name: imagePullCredentialsTypeOverride, var: image_pull_credentials_type_override}, {name: buildBatchConfigOverride, var: build_batch_config_override}, {name: debugSessionEnabled, var: debug_session_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, secondary_sources_override: $secondary_sources_override, secondary_sources_version_override: $secondary_sources_version_override, source_version: $source_version, artifacts_override: $artifacts_override, secondary_artifacts_override: $secondary_artifacts_override, environment_variables_override: $environment_variables_override, source_type_override: $source_type_override, source_location_override: $source_location_override, source_auth_override: $source_auth_override, git_clone_depth_override: $git_clone_depth_override, git_submodules_config_override: $git_submodules_config_override, buildspec_override: $buildspec_override, insecure_ssl_override: $insecure_ssl_override, report_build_batch_status_override: $report_build_batch_status_override, environment_type_override: $environment_type_override, image_override: $image_override, compute_type_override: $compute_type_override, certificate_override: $certificate_override, cache_override: $cache_override, service_role_override: $service_role_override, privileged_mode_override: $privileged_mode_override, build_timeout_in_minutes_override: $build_timeout_in_minutes_override, queued_timeout_in_minutes_override: $queued_timeout_in_minutes_override, encryption_key_override: $encryption_key_override, logs_config_override: $logs_config_override, registry_credential_override: $registry_credential_override, image_pull_credentials_type_override: $image_pull_credentials_type_override, build_batch_config_override: $build_batch_config_override, debug_session_enabled: $debug_session_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to stop running a build.
#
# POST /
# Returns: record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>
# operationId: StopBuild
export def "stop-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The ID of the build.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.StopBuild"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a running batch build.
#
# POST /
# Returns: record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>
# operationId: StopBuildBatch
export def "stop-build-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  id: string # The identifier of the batch build to stop.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.StopBuildBatch"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the settings of a build project.
#
# POST /
# Returns: record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>
# operationId: UpdateProject
export def "update-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: string # The name of the build project. You cannot change a build project's name.
  --description: string # A new or replacement description of the build project.
  --source: record # Information about the build input source code for the build project. — shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --source-version: string # A version of the build input to be built for this project. If not specified, the latest version is used. If specified, it must be one of: For CodeCommit: the commit ID, branch, or Git tag to use. For GitHub: the commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Bitbucket: the commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Amazon S3: the version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the build level, then that version takes precedence over this sourceVersion (at the project level). For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --secondary-source-versions: list # An array of ProjectSourceVersion objects. If secondarySourceVersions is specified at the build level, then they take over these secondarySourceVersions (at the project level). — item shape: {sourceIdentifier: string, sourceVersion: string}
  --artifacts: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts: list # An array of ProjectArtifact objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --cache: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --environment: record # Information about the build environment of the build project. — shape: {type: "WINDOWS_CONTAINER"|"LINUX_CONTAINER"|"LINUX_GPU_CONTAINER"|"ARM_CONTAINER"|"WINDOWS_SERVER_2019_CONTAINER", image: string, computeType: "BUILD_GENERAL1_SMALL"|"BUILD_GENERAL1_MEDIUM"|"BUILD_GENERAL1_LARGE"|"BUILD_GENERAL1_2XLARGE", environmentVariables?: list, privilegedMode?: bool, certificate?: string, registryCredential?: record, imagePullCredentialsType?: "CODEBUILD"|"SERVICE_ROLE"}
  --service-role: string # The replacement ARN of the IAM role that enables CodeBuild to interact with dependent Amazon Web Services services on behalf of the Amazon Web Services account.
  --timeout-in-minutes: int # The replacement value in minutes, from 5 to 480 (8 hours), for CodeBuild to wait before timing out any related build that did not get marked as completed.
  --queued-timeout-in-minutes: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key: string # The Key Management Service customer master key (CMK) to be used for encrypting the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --tags: list # An updated list of tag key and value pairs associated with this build project. These tags are available for use by Amazon Web Services services that support CodeBuild build project tags. — item shape: {key?: string, value?: string}
  --vpc-config: record # Information about the VPC configuration that CodeBuild accesses. — shape: {vpcId?: string, subnets?: list<string>, securityGroupIds?: list<string>}
  --badge-enabled: oneof<nothing, bool> # Set this to true to generate a publicly accessible URL for your project's build badge.
  --logs-config: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --file-system-locations: list # An array of ProjectFileSystemLocation objects for a CodeBuild build project. A ProjectFileSystemLocation object specifies the identifier, location, mountOptions, mountPoint, and type of a file system created using Amazon Elastic File System. — item shape: {type?: "EFS", location?: string, mountPoint?: string, identifier?: string, mountOptions?: string}
  --build-batch-config: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --concurrent-build-limit: int # The maximum number of concurrent builds that are allowed for this project. New builds are only started if the current number of builds is less than or equal to this limit. If the current build count meets this limit, new builds are throttled and are not run. To remove this limit, set this value to -1.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.UpdateProject"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: source, var: source}, {name: secondarySources, var: secondary_sources}, {name: sourceVersion, var: source_version}, {name: secondarySourceVersions, var: secondary_source_versions}, {name: artifacts, var: artifacts}, {name: secondaryArtifacts, var: secondary_artifacts}, {name: cache, var: cache}, {name: environment, var: environment}, {name: serviceRole, var: service_role}, {name: timeoutInMinutes, var: timeout_in_minutes}, {name: queuedTimeoutInMinutes, var: queued_timeout_in_minutes}, {name: encryptionKey, var: encryption_key}, {name: tags, var: tags}, {name: vpcConfig, var: vpc_config}, {name: badgeEnabled, var: badge_enabled}, {name: logsConfig, var: logs_config}, {name: fileSystemLocations, var: file_system_locations}, {name: buildBatchConfig, var: build_batch_config}, {name: concurrentBuildLimit, var: concurrent_build_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, description: $description, source: $source, secondary_sources: $secondary_sources, source_version: $source_version, secondary_source_versions: $secondary_source_versions, artifacts: $artifacts, secondary_artifacts: $secondary_artifacts, cache: $cache, environment: $environment, service_role: $service_role, timeout_in_minutes: $timeout_in_minutes, queued_timeout_in_minutes: $queued_timeout_in_minutes, encryption_key: $encryption_key, tags: $tags, vpc_config: $vpc_config, badge_enabled: $badge_enabled, logs_config: $logs_config, file_system_locations: $file_system_locations, build_batch_config: $build_batch_config, concurrent_build_limit: $concurrent_build_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the public visibility for a project. The project's build results, logs, and artifacts are available to the general public. For more information, see Public build projects (https://docs.aws.amazon.com/codebuild/latest/userguide/public-builds.html) in the CodeBuild User Guide. The following should be kept in mind when making your projects public: All of a project's build results, logs, and artifacts, including builds that were run when the project was private, are available to the general public. All build logs and artifacts are available to the public. Environment variables, source code, and other sensitive information may have been output to the build logs and artifacts. You must be careful about what information is output to the build logs. Some best practice are: Do not store sensitive values, especially Amazon Web Services access key IDs and secret access keys, in environment variables. We recommend that you use an Amazon EC2 Systems Manager Parameter Store or Secrets Manager to store sensitive values. Follow Best practices for using webhooks (https://docs.aws.amazon.com/codebuild/latest/userguide/webhooks.html#webhook-best-practices) in the CodeBuild User Guide to limit which entities can trigger a build, and do not store the buildspec in the project itself, to ensure that your webhooks are as secure as possible. A malicious user can use public builds to distribute malicious artifacts. We recommend that you review all pull requests to verify that the pull request is a legitimate change. We also recommend that you validate any artifacts with their checksums to make sure that the correct artifacts are being downloaded.
#
# POST /
# Returns: record<projectArn: string, publicProjectAlias: string, projectVisibility: string>
# operationId: UpdateProjectVisibility
export def "update-project-visibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_arn: string # The Amazon Resource Name (ARN) of the build project.
  project_visibility: string@project-visibility-completer # Specifies the visibility of the project's builds. Possible values are: PUBLIC_READ The project builds are visible to the public. PRIVATE The project builds are not visible to the public.
  --resource-access-role: string # The ARN of the IAM role that enables CodeBuild to access the CloudWatch Logs and Amazon S3 artifacts for the project's builds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.UpdateProjectVisibility"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectArn, var: project_arn}, {name: projectVisibility, var: project_visibility}, {name: resourceAccessRole, var: resource_access_role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_arn: $project_arn, project_visibility: $project_visibility, resource_access_role: $resource_access_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a report group.
#
# POST /
# Returns: record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>
# operationId: UpdateReportGroup
export def "update-report-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  arn: string # The ARN of the report group to update.
  --export-config: record # Information about the location where the run of a report is exported. — shape: {exportConfigType?: "S3"|"NO_EXPORT", s3Destination?: record}
  --tags: list # An updated list of tag key and value pairs associated with this report group. These tags are available for use by Amazon Web Services services that support CodeBuild report group tags. — item shape: {key?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.UpdateReportGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: exportConfig, var: export_config}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, export_config: $export_config, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the webhook associated with an CodeBuild build project. If you use Bitbucket for your repository, rotateSecret is ignored.
#
# POST /
# Returns: record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>
# operationId: UpdateWebhook
export def "update-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  project_name: string # The name of the CodeBuild project.
  --branch-filter: string # A regular expression used to determine which repository branches are built when a webhook is triggered. If the name of a branch matches the regular expression, then it is built. If branchFilter is empty, then all branches are built. It is recommended that you use filterGroups instead of branchFilter.
  --rotate-secret: oneof<nothing, bool> # A boolean value that specifies whether the associated GitHub repository's secret token should be updated. If you use Bitbucket for your repository, rotateSecret is ignored.
  --filter-groups: list # An array of arrays of WebhookFilter objects used to determine if a webhook event can trigger a build. A filter group must contain at least one EVENT WebhookFilter.
  --build-type: string@build-type-completer # Specifies the type of build this webhook will trigger.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "CodeBuild_20161006.UpdateWebhook"}]
    body: {content_type: "application/json", kind: json, fields: [{name: projectName, var: project_name}, {name: branchFilter, var: branch_filter}, {name: rotateSecret, var: rotate_secret}, {name: filterGroups, var: filter_groups}, {name: buildType, var: build_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, project_name: $project_name, branch_filter: $branch_filter, rotate_secret: $rotate_secret, filter_groups: $filter_groups, build_type: $build_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
