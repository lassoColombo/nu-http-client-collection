# Auto-generated client for AWS Amplify v2017-07-25
# Source: https://api.apis.guru/v2/specs/amazonaws.com/amplify/2017-07-25/openapi.json
# Auth: --token flag or $env.AWS_AMPLIFY_TOKEN

const CLIENT = {
  base_url: "http://amplify.us-east-1.amazonaws.com"
  token_env_var: "AWS_AMPLIFY_TOKEN"
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

def base-url-completer [] { ["http://amplify.us-east-1.amazonaws.com" "http://amplify.us-east-2.amazonaws.com" "http://amplify.us-west-1.amazonaws.com" "http://amplify.us-west-2.amazonaws.com" "http://amplify.us-gov-west-1.amazonaws.com" "http://amplify.us-gov-east-1.amazonaws.com" "http://amplify.ca-central-1.amazonaws.com" "http://amplify.eu-north-1.amazonaws.com" "http://amplify.eu-west-1.amazonaws.com" "http://amplify.eu-west-2.amazonaws.com" "http://amplify.eu-west-3.amazonaws.com" "http://amplify.eu-central-1.amazonaws.com" "http://amplify.eu-south-1.amazonaws.com" "http://amplify.af-south-1.amazonaws.com" "http://amplify.ap-northeast-1.amazonaws.com" "http://amplify.ap-northeast-2.amazonaws.com" "http://amplify.ap-northeast-3.amazonaws.com" "http://amplify.ap-southeast-1.amazonaws.com" "http://amplify.ap-southeast-2.amazonaws.com" "http://amplify.ap-east-1.amazonaws.com" "http://amplify.ap-south-1.amazonaws.com" "http://amplify.sa-east-1.amazonaws.com" "http://amplify.me-south-1.amazonaws.com" "https://amplify.us-east-1.amazonaws.com" "https://amplify.us-east-2.amazonaws.com" "https://amplify.us-west-1.amazonaws.com" "https://amplify.us-west-2.amazonaws.com" "https://amplify.us-gov-west-1.amazonaws.com" "https://amplify.us-gov-east-1.amazonaws.com" "https://amplify.ca-central-1.amazonaws.com" "https://amplify.eu-north-1.amazonaws.com" "https://amplify.eu-west-1.amazonaws.com" "https://amplify.eu-west-2.amazonaws.com" "https://amplify.eu-west-3.amazonaws.com" "https://amplify.eu-central-1.amazonaws.com" "https://amplify.eu-south-1.amazonaws.com" "https://amplify.af-south-1.amazonaws.com" "https://amplify.ap-northeast-1.amazonaws.com" "https://amplify.ap-northeast-2.amazonaws.com" "https://amplify.ap-northeast-3.amazonaws.com" "https://amplify.ap-southeast-1.amazonaws.com" "https://amplify.ap-southeast-2.amazonaws.com" "https://amplify.ap-east-1.amazonaws.com" "https://amplify.ap-south-1.amazonaws.com" "https://amplify.sa-east-1.amazonaws.com" "https://amplify.me-south-1.amazonaws.com" "http://amplify.cn-north-1.amazonaws.com.cn" "http://amplify.cn-northwest-1.amazonaws.com.cn" "https://amplify.cn-north-1.amazonaws.com.cn" "https://amplify.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def platform-completer [] { ["WEB" "WEB_COMPUTE" "WEB_DYNAMIC"] }
def stage-completer [] { ["BETA" "DEVELOPMENT" "EXPERIMENTAL" "PRODUCTION" "PULL_REQUEST"] }
def job-type-completer [] { ["MANUAL" "RELEASE" "RETRY" "WEB_HOOK"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-app: "record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>"
    list-apps: "record<apps: table<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list, productionBranch: record, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list, autoBranchCreationConfig: record, repositoryCloneMethod: string>, nextToken: string>"
    create-backend-environment: "record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>"
    list-backend-environments: "record<backendEnvironments: table<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>, nextToken: string>"
    create-branch: "record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>"
    list-branches: "record<branches: table<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>, nextToken: string>"
    create-deployment: "record<jobId: string, fileUploadUrls: record, zipUploadUrl: string>"
    create-domain-association: "record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>"
    list-domain-associations: "record<domainAssociations: table<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list>, nextToken: string>"
    create-webhook: "record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>"
    list-webhooks: "record<webhooks: table<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>, nextToken: string>"
    delete-app: "record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>"
    get-app: "record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>"
    update-app: "record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>"
    delete-backend-environment: "record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>"
    get-backend-environment: "record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>"
    delete-branch: "record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>"
    get-branch: "record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>"
    update-branch: "record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>"
    delete-domain-association: "record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>"
    get-domain-association: "record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>"
    update-domain-association: "record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>"
    delete-job: "record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>"
    get-job: "record<job: record<summary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>, steps: list<record>>>"
    delete-webhook: "record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>"
    get-webhook: "record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>"
    update-webhook: "record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>"
    generate-access-logs: "record<logUrl: string>"
    get-artifact-url: "record<artifactId: string, artifactUrl: string>"
    list-artifacts: "record<artifacts: table<artifactFileName: string, artifactId: string>, nextToken: string>"
    list-jobs: "record<jobSummaries: table<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>, nextToken: string>"
    start-job: "record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    start-deployment: "record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>"
    stop-job: "record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-app" "list-apps" "create-backend-environment" "list-backend-environments" "create-branch" "list-branches" "create-deployment" "create-domain-association" "list-domain-associations" "create-webhook" "list-webhooks" "delete-app" "get-app" "update-app" "delete-backend-environment" "get-backend-environment" "delete-branch" "get-branch" "update-branch" "delete-domain-association" "get-domain-association" "update-domain-association" "delete-job" "get-job" "delete-webhook" "get-webhook" "update-webhook" "generate-access-logs" "get-artifact-url" "list-artifacts" "list-jobs" "start-job" "list-tags-for-resource" "tag-resource" "start-deployment" "stop-job" "untag-resource" "commands"] | sort) } | get name | first)
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

# Creates a new Amplify app.
#
# POST /apps
# Returns: record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>
# operationId: CreateApp
export def "create-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name for an Amplify app.
  --description: string # The description for an Amplify app.
  --repository: string # The repository for an Amplify app.
  --platform: string@platform-completer # The platform for the Amplify app. For a static app, set the platform type to WEB. For a dynamic server-side rendered (SSR) app, set the platform type to WEB_COMPUTE. For an app requiring Amplify Hosting's original SSR support only, set the platform type to WEB_DYNAMIC.
  --iam-service-role-arn: string # The AWS Identity and Access Management (IAM) service role for an Amplify app.
  --oauth-token: string # The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored. Use oauthToken for repository providers other than GitHub, such as Bitbucket or CodeCommit. To authorize access to GitHub as your repository provider, use accessToken. You must specify either oauthToken or accessToken when you create a new app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --access-token: string # The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored. Use accessToken for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use oauthToken. You must specify either accessToken or oauthToken when you create a new app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --environment-variables: record # The environment variables map for an Amplify app.
  --enable-branch-auto-build: oneof<nothing, bool> # Enables the auto building of branches for an Amplify app.
  --enable-branch-auto-deletion: oneof<nothing, bool> # Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository.
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for an Amplify app. This will apply to all branches that are part of this app.
  --basic-auth-credentials: string # The credentials for basic authorization for an Amplify app. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --custom-rules: list # The custom rewrite and redirect rules for an Amplify app. — item shape: {source: string, target: string, status?: string, condition?: string}
  --tags: record # The tag for an Amplify app.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --custom-headers: string # The custom HTTP headers for an Amplify app.
  --enable-auto-branch-creation: oneof<nothing, bool> # Enables automated branch creation for an Amplify app.
  --auto-branch-creation-patterns: list<string> # The automated branch creation glob patterns for an Amplify app.
  --auto-branch-creation-config: record # Describes the automated branch creation configuration. — shape: {stage?: "PRODUCTION"|"BETA"|"DEVELOPMENT"|"EXPERIMENTAL"|"PULL_REQUEST", framework?: string, enableAutoBuild?: bool, environmentVariables?: record, basicAuthCredentials?: string, enableBasicAuth?: bool, enablePerformanceMode?: bool, buildSpec?: string, enablePullRequestPreview?: bool, pullRequestEnvironmentName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: repository, var: repository}, {name: platform, var: platform}, {name: iamServiceRoleArn, var: iam_service_role_arn}, {name: oauthToken, var: oauth_token}, {name: accessToken, var: access_token}, {name: environmentVariables, var: environment_variables}, {name: enableBranchAutoBuild, var: enable_branch_auto_build}, {name: enableBranchAutoDeletion, var: enable_branch_auto_deletion}, {name: enableBasicAuth, var: enable_basic_auth}, {name: basicAuthCredentials, var: basic_auth_credentials}, {name: customRules, var: custom_rules}, {name: tags, var: tags}, {name: buildSpec, var: build_spec}, {name: customHeaders, var: custom_headers}, {name: enableAutoBranchCreation, var: enable_auto_branch_creation}, {name: autoBranchCreationPatterns, var: auto_branch_creation_patterns}, {name: autoBranchCreationConfig, var: auto_branch_creation_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, repository: $repository, platform: $platform, iam_service_role_arn: $iam_service_role_arn, oauth_token: $oauth_token, access_token: $access_token, environment_variables: $environment_variables, enable_branch_auto_build: $enable_branch_auto_build, enable_branch_auto_deletion: $enable_branch_auto_deletion, enable_basic_auth: $enable_basic_auth, basic_auth_credentials: $basic_auth_credentials, custom_rules: $custom_rules, tags: $tags, build_spec: $build_spec, custom_headers: $custom_headers, enable_auto_branch_creation: $enable_auto_branch_creation, auto_branch_creation_patterns: $auto_branch_creation_patterns, auto_branch_creation_config: $auto_branch_creation_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the existing Amplify apps.
#
# GET /apps
# Returns: record<apps: table<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list, productionBranch: record, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list, autoBranchCreationConfig: record, repositoryCloneMethod: string>, nextToken: string>
# operationId: ListApps
export def "list-apps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. If non-null, the pagination token is returned in a result. Pass its value in another request to retrieve more entries.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps"
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

# Creates a new backend environment for an Amplify app.
#
# POST /apps/{appId}/backendenvironments
# Returns: record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>
# operationId: CreateBackendEnvironment
export def "create-backend-environment" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  environment_name: string # The name for the backend environment.
  --stack-name: string # The AWS CloudFormation stack name of a backend environment.
  --deployment-artifacts: string # The name of deployment artifacts.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/backendenvironments"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}, {name: stackName, var: stack_name}, {name: deploymentArtifacts, var: deployment_artifacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, environment_name: $environment_name, stack_name: $stack_name, deployment_artifacts: $deployment_artifacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the backend environments for an Amplify app.
#
# GET /apps/{appId}/backendenvironments
# Returns: record<backendEnvironments: table<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>, nextToken: string>
# operationId: ListBackendEnvironments
export def "list-backend-environments" [
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
  --environment-name: string # The name of the backend environment
  --next-token: string # A pagination token. Set to null to start listing backend environments from the start. If a non-null pagination token is returned in a result, pass its value in here to list more backend environments.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/backendenvironments"
    path_params: [{name: appId, var: app_id}]
    query: [{name: environmentName, var: environment_name}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, environment_name: $environment_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new branch for an Amplify app.
#
# POST /apps/{appId}/branches
# Returns: record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>
# operationId: CreateBranch
export def "create-branch" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  branch_name: string # The name for the branch.
  --description: string # The description for the branch.
  --stage: string@stage-completer # Describes the current stage for the branch.
  --framework: string # The framework for the branch.
  --enable-notification: oneof<nothing, bool> # Enables notifications for the branch.
  --enable-auto-build: oneof<nothing, bool> # Enables auto building for the branch.
  --environment-variables: record # The environment variables for the branch.
  --basic-auth-credentials: string # The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for the branch.
  --enable-performance-mode: oneof<nothing, bool> # Enables performance mode for the branch. Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out.
  --tags: record # The tag for the branch.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --ttl: string # The content Time to Live (TTL) for the website in seconds.
  --display-name: string # The display name for a branch. This is used as the default domain prefix.
  --enable-pull-request-preview: oneof<nothing, bool> # Enables pull request previews for this branch.
  --pull-request-environment-name: string # The Amplify environment name for the pull request.
  --backend-environment-arn: string # The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/branches"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: description, var: description}, {name: stage, var: stage}, {name: framework, var: framework}, {name: enableNotification, var: enable_notification}, {name: enableAutoBuild, var: enable_auto_build}, {name: environmentVariables, var: environment_variables}, {name: basicAuthCredentials, var: basic_auth_credentials}, {name: enableBasicAuth, var: enable_basic_auth}, {name: enablePerformanceMode, var: enable_performance_mode}, {name: tags, var: tags}, {name: buildSpec, var: build_spec}, {name: ttl, var: ttl}, {name: displayName, var: display_name}, {name: enablePullRequestPreview, var: enable_pull_request_preview}, {name: pullRequestEnvironmentName, var: pull_request_environment_name}, {name: backendEnvironmentArn, var: backend_environment_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, branch_name: $branch_name, description: $description, stage: $stage, framework: $framework, enable_notification: $enable_notification, enable_auto_build: $enable_auto_build, environment_variables: $environment_variables, basic_auth_credentials: $basic_auth_credentials, enable_basic_auth: $enable_basic_auth, enable_performance_mode: $enable_performance_mode, tags: $tags, build_spec: $build_spec, ttl: $ttl, display_name: $display_name, enable_pull_request_preview: $enable_pull_request_preview, pull_request_environment_name: $pull_request_environment_name, backend_environment_arn: $backend_environment_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the branches of an Amplify app.
#
# GET /apps/{appId}/branches
# Returns: record<branches: table<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>, nextToken: string>
# operationId: ListBranches
export def "list-branches" [
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
  --next-token: string # A pagination token. Set to null to start listing branches from the start. If a non-null pagination token is returned in a result, pass its value in here to list more branches.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/branches"
    path_params: [{name: appId, var: app_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a deployment for a manually deployed Amplify app. Manually deployed apps are not connected to a repository.
#
# POST /apps/{appId}/branches/{branchName}/deployments
# Returns: record<jobId: string, fileUploadUrls: record, zipUploadUrl: string>
# operationId: CreateDeployment
export def "create-deployment" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --file-map: record # An optional file map that contains the file name as the key and the file content md5 hash as the value. If this argument is provided, the service will generate a unique upload URL per file. Otherwise, the service will only generate a single upload URL for the zipped files.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/branches/{branchName}/deployments"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileMap, var: file_map}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, file_map: $file_map
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new domain association for an Amplify app. This action associates a custom domain with the Amplify app
#
# POST /apps/{appId}/domains
# Returns: record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>
# operationId: CreateDomainAssociation
export def "create-domain-association" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  domain_name: string # The domain name for the domain association.
  --enable-auto-sub-domain: oneof<nothing, bool> # Enables the automated creation of subdomains for branches.
  sub_domain_settings: list # The setting for the subdomain. — item shape: {prefix: string, branchName: string}
  --auto-sub-domain-creation-patterns: list<string> # Sets the branch patterns for automatic subdomain creation.
  --auto-sub-domain-iam-role: string # The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/domains"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}, {name: enableAutoSubDomain, var: enable_auto_sub_domain}, {name: subDomainSettings, var: sub_domain_settings}, {name: autoSubDomainCreationPatterns, var: auto_sub_domain_creation_patterns}, {name: autoSubDomainIAMRole, var: auto_sub_domain_iam_role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, domain_name: $domain_name, enable_auto_sub_domain: $enable_auto_sub_domain, sub_domain_settings: $sub_domain_settings, auto_sub_domain_creation_patterns: $auto_sub_domain_creation_patterns, auto_sub_domain_iam_role: $auto_sub_domain_iam_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the domain associations for an Amplify app.
#
# GET /apps/{appId}/domains
# Returns: record<domainAssociations: table<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list>, nextToken: string>
# operationId: ListDomainAssociations
export def "list-domain-associations" [
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
  --next-token: string # A pagination token. Set to null to start listing apps from the start. If non-null, a pagination token is returned in a result. Pass its value in here to list more projects.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/domains"
    path_params: [{name: appId, var: app_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new webhook on an Amplify app.
#
# POST /apps/{appId}/webhooks
# Returns: record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>
# operationId: CreateWebhook
export def "create-webhook" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  branch_name: string # The name for a branch that is part of an Amplify app.
  --description: string # The description for a webhook.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/webhooks"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, branch_name: $branch_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of webhooks for an Amplify app.
#
# GET /apps/{appId}/webhooks
# Returns: record<webhooks: table<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>, nextToken: string>
# operationId: ListWebhooks
export def "list-webhooks" [
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
  --next-token: string # A pagination token. Set to null to start listing webhooks from the start. If non-null,the pagination token is returned in a result. Pass its value in here to list more webhooks.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/webhooks"
    path_params: [{name: appId, var: app_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing Amplify app specified by an app ID.
#
# DELETE /apps/{appId}
# Returns: record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>
# operationId: DeleteApp
export def "delete-app" [
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
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an existing Amplify app by appID.
#
# GET /apps/{appId}
# Returns: record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>
# operationId: GetApp
export def "get-app" [
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
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Amplify app.
#
# POST /apps/{appId}
# Returns: record<app: record<appId: string, appArn: string, name: string, tags: record, description: string, repository: string, platform: string, createTime: string, updateTime: string, iamServiceRoleArn: string, environmentVariables: record, defaultDomain: string, enableBranchAutoBuild: bool, enableBranchAutoDeletion: bool, enableBasicAuth: bool, basicAuthCredentials: string, customRules: list<record>, productionBranch: record<lastDeployTime: string, status: string, thumbnailUrl: string, branchName: string>, buildSpec: string, customHeaders: string, enableAutoBranchCreation: bool, autoBranchCreationPatterns: list<string>, autoBranchCreationConfig: record<stage: string, framework: string, enableAutoBuild: bool, environmentVariables: record, basicAuthCredentials: string, enableBasicAuth: bool, enablePerformanceMode: bool, buildSpec: string, enablePullRequestPreview: bool, pullRequestEnvironmentName: string>, repositoryCloneMethod: string>>
# operationId: UpdateApp
export def "update-app" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # The name for an Amplify app.
  --description: string # The description for an Amplify app.
  --platform: string@platform-completer # The platform for the Amplify app. For a static app, set the platform type to WEB. For a dynamic server-side rendered (SSR) app, set the platform type to WEB_COMPUTE. For an app requiring Amplify Hosting's original SSR support only, set the platform type to WEB_DYNAMIC.
  --iam-service-role-arn: string # The AWS Identity and Access Management (IAM) service role for an Amplify app.
  --environment-variables: record # The environment variables for an Amplify app.
  --enable-branch-auto-build: oneof<nothing, bool> # Enables branch auto-building for an Amplify app.
  --enable-branch-auto-deletion: oneof<nothing, bool> # Automatically disconnects a branch in the Amplify Console when you delete a branch from your Git repository.
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for an Amplify app.
  --basic-auth-credentials: string # The basic authorization credentials for an Amplify app. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --custom-rules: list # The custom redirect and rewrite rules for an Amplify app. — item shape: {source: string, target: string, status?: string, condition?: string}
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --custom-headers: string # The custom HTTP headers for an Amplify app.
  --enable-auto-branch-creation: oneof<nothing, bool> # Enables automated branch creation for an Amplify app.
  --auto-branch-creation-patterns: list<string> # Describes the automated branch creation glob patterns for an Amplify app.
  --auto-branch-creation-config: record # Describes the automated branch creation configuration. — shape: {stage?: "PRODUCTION"|"BETA"|"DEVELOPMENT"|"EXPERIMENTAL"|"PULL_REQUEST", framework?: string, enableAutoBuild?: bool, environmentVariables?: record, basicAuthCredentials?: string, enableBasicAuth?: bool, enablePerformanceMode?: bool, buildSpec?: string, enablePullRequestPreview?: bool, pullRequestEnvironmentName?: string}
  --repository: string # The name of the repository for an Amplify app
  --oauth-token: string # The OAuth token for a third-party source control system for an Amplify app. The OAuth token is used to create a webhook and a read-only deploy key using SSH cloning. The OAuth token is not stored. Use oauthToken for repository providers other than GitHub, such as Bitbucket or CodeCommit. To authorize access to GitHub as your repository provider, use accessToken. You must specify either oauthToken or accessToken when you update an app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
  --access-token: string # The personal access token for a GitHub repository for an Amplify app. The personal access token is used to authorize access to a GitHub repository using the Amplify GitHub App. The token is not stored. Use accessToken for GitHub repositories only. To authorize access to a repository provider such as Bitbucket or CodeCommit, use oauthToken. You must specify either accessToken or oauthToken when you update an app. Existing Amplify apps deployed from a GitHub repository using OAuth continue to work with CI/CD. However, we strongly recommend that you migrate these apps to use the GitHub App. For more information, see Migrating an existing OAuth app to the Amplify GitHub App (https://docs.aws.amazon.com/amplify/latest/UserGuide/setting-up-GitHub-access.html#migrating-to-github-app-auth) in the Amplify User Guide . (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: description, var: description}, {name: platform, var: platform}, {name: iamServiceRoleArn, var: iam_service_role_arn}, {name: environmentVariables, var: environment_variables}, {name: enableBranchAutoBuild, var: enable_branch_auto_build}, {name: enableBranchAutoDeletion, var: enable_branch_auto_deletion}, {name: enableBasicAuth, var: enable_basic_auth}, {name: basicAuthCredentials, var: basic_auth_credentials}, {name: customRules, var: custom_rules}, {name: buildSpec, var: build_spec}, {name: customHeaders, var: custom_headers}, {name: enableAutoBranchCreation, var: enable_auto_branch_creation}, {name: autoBranchCreationPatterns, var: auto_branch_creation_patterns}, {name: autoBranchCreationConfig, var: auto_branch_creation_config}, {name: repository, var: repository}, {name: oauthToken, var: oauth_token}, {name: accessToken, var: access_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, description: $description, platform: $platform, iam_service_role_arn: $iam_service_role_arn, environment_variables: $environment_variables, enable_branch_auto_build: $enable_branch_auto_build, enable_branch_auto_deletion: $enable_branch_auto_deletion, enable_basic_auth: $enable_basic_auth, basic_auth_credentials: $basic_auth_credentials, custom_rules: $custom_rules, build_spec: $build_spec, custom_headers: $custom_headers, enable_auto_branch_creation: $enable_auto_branch_creation, auto_branch_creation_patterns: $auto_branch_creation_patterns, auto_branch_creation_config: $auto_branch_creation_config, repository: $repository, oauth_token: $oauth_token, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a backend environment for an Amplify app.
#
# DELETE /apps/{appId}/backendenvironments/{environmentName}
# Returns: record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>
# operationId: DeleteBackendEnvironment
export def "delete-backend-environment" [
  app_id: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/apps/{appId}/backendenvironments/{environmentName}"
    path_params: [{name: appId, var: app_id}, {name: environmentName, var: environment_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, environment_name: $environment_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a backend environment for an Amplify app.
#
# GET /apps/{appId}/backendenvironments/{environmentName}
# Returns: record<backendEnvironment: record<backendEnvironmentArn: string, environmentName: string, stackName: string, deploymentArtifacts: string, createTime: string, updateTime: string>>
# operationId: GetBackendEnvironment
export def "get-backend-environment" [
  app_id: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/apps/{appId}/backendenvironments/{environmentName}"
    path_params: [{name: appId, var: app_id}, {name: environmentName, var: environment_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, environment_name: $environment_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a branch for an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}
# Returns: record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>
# operationId: DeleteBranch
export def "delete-branch" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/apps/{appId}/branches/{branchName}"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a branch for an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}
# Returns: record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>
# operationId: GetBranch
export def "get-branch" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/apps/{appId}/branches/{branchName}"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a branch for an Amplify app.
#
# POST /apps/{appId}/branches/{branchName}
# Returns: record<branch: record<branchArn: string, branchName: string, description: string, tags: record, stage: string, displayName: string, enableNotification: bool, createTime: string, updateTime: string, environmentVariables: record, enableAutoBuild: bool, customDomains: list<string>, framework: string, activeJobId: string, totalNumberOfJobs: string, enableBasicAuth: bool, enablePerformanceMode: bool, thumbnailUrl: string, basicAuthCredentials: string, buildSpec: string, ttl: string, associatedResources: list<string>, enablePullRequestPreview: bool, pullRequestEnvironmentName: string, destinationBranch: string, sourceBranch: string, backendEnvironmentArn: string>>
# operationId: UpdateBranch
export def "update-branch" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # The description for the branch.
  --framework: string # The framework for the branch.
  --stage: string@stage-completer # Describes the current stage for the branch.
  --enable-notification: oneof<nothing, bool> # Enables notifications for the branch.
  --enable-auto-build: oneof<nothing, bool> # Enables auto building for the branch.
  --environment-variables: record # The environment variables for the branch.
  --basic-auth-credentials: string # The basic authorization credentials for the branch. You must base64-encode the authorization credentials and provide them in the format user:password. (format: password)
  --enable-basic-auth: oneof<nothing, bool> # Enables basic authorization for the branch.
  --enable-performance-mode: oneof<nothing, bool> # Enables performance mode for the branch. Performance mode optimizes for faster hosting performance by keeping content cached at the edge for a longer interval. When performance mode is enabled, hosting configuration or code changes can take up to 10 minutes to roll out.
  --build-spec: string # The build specification (build spec) file for an Amplify app build. (format: password)
  --ttl: string # The content Time to Live (TTL) for the website in seconds.
  --display-name: string # The display name for a branch. This is used as the default domain prefix.
  --enable-pull-request-preview: oneof<nothing, bool> # Enables pull request previews for this branch.
  --pull-request-environment-name: string # The Amplify environment name for the pull request.
  --backend-environment-arn: string # The Amazon Resource Name (ARN) for a backend environment that is part of an Amplify app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/branches/{branchName}"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: framework, var: framework}, {name: stage, var: stage}, {name: enableNotification, var: enable_notification}, {name: enableAutoBuild, var: enable_auto_build}, {name: environmentVariables, var: environment_variables}, {name: basicAuthCredentials, var: basic_auth_credentials}, {name: enableBasicAuth, var: enable_basic_auth}, {name: enablePerformanceMode, var: enable_performance_mode}, {name: buildSpec, var: build_spec}, {name: ttl, var: ttl}, {name: displayName, var: display_name}, {name: enablePullRequestPreview, var: enable_pull_request_preview}, {name: pullRequestEnvironmentName, var: pull_request_environment_name}, {name: backendEnvironmentArn, var: backend_environment_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, framework: $framework, stage: $stage, enable_notification: $enable_notification, enable_auto_build: $enable_auto_build, environment_variables: $environment_variables, basic_auth_credentials: $basic_auth_credentials, enable_basic_auth: $enable_basic_auth, enable_performance_mode: $enable_performance_mode, build_spec: $build_spec, ttl: $ttl, display_name: $display_name, enable_pull_request_preview: $enable_pull_request_preview, pull_request_environment_name: $pull_request_environment_name, backend_environment_arn: $backend_environment_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a domain association for an Amplify app.
#
# DELETE /apps/{appId}/domains/{domainName}
# Returns: record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>
# operationId: DeleteDomainAssociation
export def "delete-domain-association" [
  app_id: string
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
    path: "/apps/{appId}/domains/{domainName}"
    path_params: [{name: appId, var: app_id}, {name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the domain information for an Amplify app.
#
# GET /apps/{appId}/domains/{domainName}
# Returns: record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>
# operationId: GetDomainAssociation
export def "get-domain-association" [
  app_id: string
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
    path: "/apps/{appId}/domains/{domainName}"
    path_params: [{name: appId, var: app_id}, {name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new domain association for an Amplify app.
#
# POST /apps/{appId}/domains/{domainName}
# Returns: record<domainAssociation: record<domainAssociationArn: string, domainName: string, enableAutoSubDomain: bool, autoSubDomainCreationPatterns: list<string>, autoSubDomainIAMRole: string, domainStatus: string, statusReason: string, certificateVerificationDNSRecord: string, subDomains: list<record>>>
# operationId: UpdateDomainAssociation
export def "update-domain-association" [
  app_id: string
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
  --enable-auto-sub-domain: oneof<nothing, bool> # Enables the automated creation of subdomains for branches.
  --sub-domain-settings: list # Describes the settings for the subdomain. — item shape: {prefix: string, branchName: string}
  --auto-sub-domain-creation-patterns: list<string> # Sets the branch patterns for automatic subdomain creation.
  --auto-sub-domain-iam-role: string # The required AWS Identity and Access Management (IAM) service role for the Amazon Resource Name (ARN) for automatically creating subdomains.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/domains/{domainName}"
    path_params: [{name: appId, var: app_id}, {name: domainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: enableAutoSubDomain, var: enable_auto_sub_domain}, {name: subDomainSettings, var: sub_domain_settings}, {name: autoSubDomainCreationPatterns, var: auto_sub_domain_creation_patterns}, {name: autoSubDomainIAMRole, var: auto_sub_domain_iam_role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, enable_auto_sub_domain: $enable_auto_sub_domain, sub_domain_settings: $sub_domain_settings, auto_sub_domain_creation_patterns: $auto_sub_domain_creation_patterns, auto_sub_domain_iam_role: $auto_sub_domain_iam_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a job for a branch of an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}
# Returns: record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>
# operationId: DeleteJob
export def "delete-job" [
  app_id: string
  branch_name: string
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
    method: delete
    path: "/apps/{appId}/branches/{branchName}/jobs/{jobId}"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}, {name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a job for a branch of an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}
# Returns: record<job: record<summary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>, steps: list<record>>>
# operationId: GetJob
export def "get-job" [
  app_id: string
  branch_name: string
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
    path: "/apps/{appId}/branches/{branchName}/jobs/{jobId}"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}, {name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a webhook.
#
# DELETE /webhooks/{webhookId}
# Returns: record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>
# operationId: DeleteWebhook
export def "delete-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the webhook information that corresponds to a specified webhook ID.
#
# GET /webhooks/{webhookId}
# Returns: record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>
# operationId: GetWebhook
export def "get-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a webhook.
#
# POST /webhooks/{webhookId}
# Returns: record<webhook: record<webhookArn: string, webhookId: string, webhookUrl: string, branchName: string, description: string, createTime: string, updateTime: string>>
# operationId: UpdateWebhook
export def "update-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --branch-name: string # The name for a branch that is part of an Amplify app.
  --description: string # The description for a webhook.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, branch_name: $branch_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the website access logs for a specific time range using a presigned URL.
#
# POST /apps/{appId}/accesslogs
# Returns: record<logUrl: string>
# operationId: GenerateAccessLogs
export def "generate-access-logs" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --start-time: string # The time at which the logs should start. The time range specified is inclusive of the start time. (format: date-time)
  --end-time: string # The time at which the logs should end. The time range specified is inclusive of the end time. (format: date-time)
  domain_name: string # The name of the domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/accesslogs"
    path_params: [{name: appId, var: app_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, start_time: $start_time, end_time: $end_time, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the artifact info that corresponds to an artifact id.
#
# GET /artifacts/{artifactId}
# Returns: record<artifactId: string, artifactUrl: string>
# operationId: GetArtifactUrl
export def "get-artifact-url" [
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
    path: "/artifacts/{artifactId}"
    path_params: [{name: artifactId, var: artifact_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    artifact_id: $artifact_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of artifacts for a specified app, branch, and job.
#
# GET /apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts
# Returns: record<artifacts: table<artifactFileName: string, artifactId: string>, nextToken: string>
# operationId: ListArtifacts
export def "list-artifacts" [
  app_id: string
  branch_name: string
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
  --next-token: string # A pagination token. Set to null to start listing artifacts from start. If a non-null pagination token is returned in a result, pass its value in here to list more artifacts.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}, {name: jobId, var: job_id}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, job_id: $job_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the jobs for a branch of an Amplify app.
#
# GET /apps/{appId}/branches/{branchName}/jobs
# Returns: record<jobSummaries: table<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>, nextToken: string>
# operationId: ListJobs
export def "list-jobs" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token. Set to null to start listing steps from the start. If a non-null pagination token is returned in a result, pass its value in here to list more steps.
  --max-results: int # The maximum number of records to list in a single response.
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
    path: "/apps/{appId}/branches/{branchName}/jobs"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a new job for a branch of an Amplify app.
#
# POST /apps/{appId}/branches/{branchName}/jobs
# Returns: record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>
# operationId: StartJob
export def "start-job" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-id: string # The unique ID for an existing job. This is required if the value of jobType is RETRY.
  job_type: string@job-type-completer # Describes the type for the job. The job type RELEASE starts a new job with the latest change from the specified branch. This value is available only for apps that are connected to a repository. The job type RETRY retries an existing job. If the job type value is RETRY, the jobId is also required.
  --job-reason: string # A descriptive reason for starting this job.
  --commit-id: string # The commit ID from a third-party repository provider for the job.
  --commit-message: string # The commit message from a third-party repository provider for the job.
  --commit-time: string # The commit date and time for the job. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/branches/{branchName}/jobs"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobId, var: job_id}, {name: jobType, var: job_type}, {name: jobReason, var: job_reason}, {name: commitId, var: commit_id}, {name: commitMessage, var: commit_message}, {name: commitTime, var: commit_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_id: $job_id, job_type: $job_type, job_reason: $job_reason, commit_id: $commit_id, commit_message: $commit_message, commit_time: $commit_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tags for a specified Amazon Resource Name (ARN).
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

# Tags the resource with a tag key and value.
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
  tags: record # The tags used to tag the resource.
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

# Starts a deployment for a manually deployed app. Manually deployed apps are not connected to a repository.
#
# POST /apps/{appId}/branches/{branchName}/deployments/start
# Returns: record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>
# operationId: StartDeployment
export def "start-deployment" [
  app_id: string
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --job-id: string # The job ID for this deployment, generated by the create deployment request.
  --source-url: string # The source URL for this deployment, used when calling start deployment without create deployment. The source URL can be any HTTP GET URL that is publicly accessible and downloads a single .zip file.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/{appId}/branches/{branchName}/deployments/start"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobId, var: job_id}, {name: sourceUrl, var: source_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_id: $job_id, source_url: $source_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a job that is in progress for a branch of an Amplify app.
#
# DELETE /apps/{appId}/branches/{branchName}/jobs/{jobId}/stop
# Returns: record<jobSummary: record<jobArn: string, jobId: string, commitId: string, commitMessage: string, commitTime: string, startTime: string, status: string, endTime: string, jobType: string>>
# operationId: StopJob
export def "stop-job" [
  app_id: string
  branch_name: string
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
    method: delete
    path: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop"
    path_params: [{name: appId, var: app_id}, {name: branchName, var: branch_name}, {name: jobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, branch_name: $branch_name, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Untags a resource with a specified Amazon Resource Name (ARN).
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
  --tag-keys: list<string> # The tag keys to use to untag a resource. (required)
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
